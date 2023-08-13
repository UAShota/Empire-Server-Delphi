{**********************************************}
{                                              }
{ Флот : удаление юнита с планетоида           }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.RemoveFromPlanet;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки удаления юнита с планетоида
  TPLShipsControlRemoveFromPlanet = class(TPLShipsControlCustom)
  private
    // Отпрака флота автозаменя
    procedure DoReplaceDeleted(AShip: TPlShip);
  public
    // Базовое выполнение
    procedure Execute(AShip: TPlShip; APhisycal, AExplosive, ARecalc: Boolean);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlRemoveFromPlanet.DoReplaceDeleted(AShip: TPlShip);
var
  TmpShip: TPlShip;
begin
  try
    // Нельзя заменять стационарки, девы и нижний слот
    if (AShip.Landing.IsLowOrbit)
      or (AShip.TechActive(plttStationary))
      or (AShip.TechActive(plttWeaponRocket))
    then
      Exit();
    // Переберем все привязанные корабли
    for TmpShip in AShip.Planet.RangeAttackers do
    begin
      if (TmpShip.ShipType = AShip.ShipType)
        and TPlanetarThread(Engine).ControlShips.MoveToPlanet.Execute(TmpShip, AShip.Planet, AShip.Landing, True, True) then
      begin
        if (AShip.Mode = pshmdOffline) then
          TmpShip.Mode := AShip.Mode;
        Break;
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlRemoveFromPlanet.Execute(AShip: TPlShip; APhisycal, AExplosive, ARecalc: Boolean);
begin
  try
    // Уберем из списка планеты
    AShip.Planet.Landings.Remove(AShip);
    // Если задан пересчет
    if (ARecalc) then
    begin
      // Уберем привязку
      if (Assigned(AShip.Attached)) then
        TPlanetarThread(Engine).ControlShips.Attach.Execute(AShip, nil, True);
      // Обновим параметры планеты
      TPlanetarThread(Engine).ControlPlanets.UpdateShipList(AShip, -AShip.Count);
    end;
    // Подчистим список активных
    TPlanetarThread(Engine).ControlShips.StandDown.Execute(AShip, AShip.Mode, True);
    // Отправим сообщение изменения контроля
    TPlanetarThread(Engine).ControlPlanets.PlayerControlChange(
      AShip.Planet, AShip.Owner, False, AShip.Landing.IsLowOrbit);
    // Удаление с карты кораблей
    if (APhisycal) then
    begin
      // Уберем все таймеры
      TPlanetarThread(Engine).WorkerShips.TimerRemove(AShip);
      // Удалим из группы
      if (Assigned(AShip.Group)) then
        AShip.Group.Remove(AShip);
      // Отправим сообщение
      TPlanetarThread(Engine).SocketWriter.ShipDelete(AShip, AExplosive);
      // Уберем кораблик из списков
      TPlanetarThread(Engine).ControlShips.ListShips[AShip.ID] := nil;
      // Заменим кораблик, если нужно
      DoReplaceDeleted(AShip);
      // Уничтожить сам объект на вечный покой
      FreeAndNil(AShip);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
