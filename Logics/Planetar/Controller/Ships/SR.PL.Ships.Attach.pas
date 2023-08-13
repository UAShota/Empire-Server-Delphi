{**********************************************}
{                                              }
{ Флот : прикрепление к планете                }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Attach;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки прикрепления к планете
  TPLShipsControlAttach = class(TPLShipsControlCustom)
  public
    // Базовое выполнение
    procedure Execute(AShip: TPlShip; ADestination: TPlPlanet; AIsAutoTarget: Boolean);
    // Выполнение команды игрока
    procedure Player(AShip: TPlShip; ADestination: TPlPlanet; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlAttach.Execute(AShip: TPlShip; ADestination: TPlPlanet; AIsAutoTarget: Boolean);
begin
  try
    // Уберем кораблик из списка нацеленных
    if (AShip.IsAttachedRange(False)) then
      AShip.Attached.RangeAttackers.Remove(AShip)
    else
    // Отменим захват
    if (Assigned(AShip.Attached)) then
      TPlanetarThread(Engine).ControlShips.Capture.Execute(AShip, False);
    // Отправим сообщение о смене аттача
    AShip.IsAutoTarget := (AIsAutoTarget) and Assigned(ADestination);
    AShip.Attached := ADestination;
    TPlanetarThread(Engine).SocketWriter.ShipChangeAttach(AShip);
    // Если приаттачены не к внешней планете
    if (not Assigned(ADestination))
      or (ADestination = AShip.Planet) then
    begin
      if (AIsAutoTarget) then
        Exit();
      // Для ранжевых локальных корабликов сделаем сброс прицела и автоприцел
      if (AShip.TechActive(plttWeaponRocket)) then
      begin
        // Если боя нет, то выполним автоприцел
        if (not AShip.Planet.Timer[ppltmBattle]) then
          TPlanetarThread(Engine).ControlShips.TargetMarker.Auto(AShip)
        else
        if (AShip.IsTargeted) then
          TPlanetarThread(Engine).ControlShips.TargetLocal.Execute(AShip);
      end else
      // Добавим захват для инвейдера
      if (AShip.TechActive(plttCapturer))
        and (Assigned(AShip.Attached))
      then
        TPlanetarThread(Engine).ControlShips.Capture.Execute(AShip, True);
      Exit();
    end;
    // Запишем в внешние корабли планеты
    AShip.Attached.RangeAttackers.Add(AShip);
    if (AIsAutoTarget) then
      Exit();
    // И переприцелим вручную направленные девы
    if (AShip.TechActive(plttWeaponRocket)) then
      TPlanetarThread(Engine).ControlShips.TargetMarker.Highlight(AShip, AShip.Attached, False)
    else
    // А инвайдер при таком прикреплении сразу летит захватывать
    if (AShip.TechActive(plttCapturer))
      and (AShip.Attached.IsManned)
      and (not TPlanetarThread(Engine).ControlShips.MoveToPlanet.Execute(AShip, AShip.Attached, 0, True, True))
    then
      TLogAccess.Write(ClassName, 'InvaderSlot');
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlAttach.Player(AShip: TPlShip; ADestination: TPlPlanet; APlayer: TGlPlayer);
begin
  try
    // Нельзя управлять неюзабельными
    if (not AShip.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'Operable');
      Exit();
    end;
    // Нельзя повторно атачиться на ту же планету
    if ((AShip.Attached = ADestination) and (not AShip.IsAutoTarget)) then
    begin
      TLogAccess.Write(ClassName, 'Reattach');
      Exit();
    end;
    // Нельзя управлять чужими
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // Приверим куда аттачимся
    if (Assigned(ADestination)) then
    begin
      if (AShip.TechActive(plttCapturer)) then
      begin
        // Нельзя захватывать дружественные планетоиды
        if (ADestination.Owner.IsRoleFriend(AShip.Owner)) then
        begin
          TLogAccess.Write(ClassName, 'Captured');
          Exit();
        end;
        // Нельзя аттачиться к нежилым планетам
        if (not ADestination.IsManned) then
        begin
          TLogAccess.Write(ClassName, 'Manned');
          Exit();
        end;
      end;
      // Проверка на прикрепление к другой планете
      if (AShip.Planet <> ADestination) then
      begin
        // Стационарные не аттачатся на другие планеты
        if (AShip.TechActive(plttStationary)) then
        begin
          TLogAccess.Write(ClassName, 'Stationary');
          Exit();
        end;
        // Нельзя аттачиться на планеты вне радиуса перелета
        if (not AShip.Planet.Links.Contains(ADestination)) then
        begin
          TLogAccess.Write(ClassName, 'Links');
          Exit();
        end;
      end;
      // Проверка на аттач к ЧТ
      if (ADestination.PlanetType = pltHole) then
      begin
        // Нельзя аттачиться к неактивной чт
        if (ADestination.State <> plsActive) then
        begin
          TLogAccess.Write(ClassName, 'HoleInactive');
          Exit();
        end;
        // Попытка переместить игрока на указанную ЧТ
        if (not TPlanetarThread(Engine).ControlShips.MoveToPlanet.Execute(AShip, ADestination)) then
          TLogAccess.Write(ClassName, 'HoleCantMove');
        Exit();
      end;
    end;
    // Приаттачим кораблик
    Execute(AShip, ADestination, False);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
