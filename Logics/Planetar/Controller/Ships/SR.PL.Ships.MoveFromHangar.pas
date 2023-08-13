{**********************************************}
{                                              }
{ Флот : высадка из ангара                     }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.MoveFromHangar;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.Planetar.Hangar,
  SR.PL.Ships.Custom;

type
  // Класс высадки из ангара
  TPLShipsControlMoveFromHangar = class(TPLShipsControlCustom)
  public
    // Базовое выполнение
    procedure Execute(AHangarSlot: Integer; ADestination: TPlPlanet; ATargetSlot: TPlLanding;
      ACount: Integer; APlayer: TGlPlayer);
    // Выполнение команды игрока
    procedure Player(AHangarSlot: Integer; ADestination: TPlPlanet; ATargetSlot: TPlLanding;
      ACount: Integer; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread,
  SR.Planetar.Profile,
  SR.Planetar.Dictionary;

procedure TPLShipsControlMoveFromHangar.Execute(AHangarSlot: Integer; ADestination: TPlPlanet;
  ATargetSlot: TPlLanding; ACount: Integer; APlayer: TGlPlayer);
var
  TmpShip: TPlShip;
  TmpHangar: TPlHangarSlot;
  TmpLowOrbit: Boolean;
  TmpCover: TPlShipsCountPair;
  TmpCount: Integer;
begin
  try
    // Корабль должен существовать и его должно быть
    TmpHangar := TPlanetarProfile(APlayer.PlanetarProfile).Hangar.Slots[AHangarSlot];
    if (TmpHangar.Count = 0) then
    begin
      TLogAccess.Write(ClassName, 'Hangar');
      Exit();
    end;
    // Найдем свободный слот, если не указан
    TmpLowOrbit := TPlanetarProfile(APlayer.PlanetarProfile).TechShipProfile[TmpHangar.ShipType, plttLowOrbit].Supported;
    if (ATargetSlot <= 0) then
      ATargetSlot := GetFreeSlot(True, ADestination, TmpLowOrbit, APlayer)
    else
    // Проверим выгрузку в торговый слот
    if (ATargetSlot.IsLowOrbit) and (not TmpLowOrbit) then
    begin
      TLogAccess.Write(ClassName, 'LowOrbit');
      Exit();
    end;
    // Проверим его нахождение
    if (ATargetSlot = 0) then
    begin
      TLogAccess.Write(ClassName, 'Slot');
      Exit();
    end;
    // Проверить, свободен ли слот для приземления
    if (not CheckArrival(ADestination, TmpLowOrbit, ATargetSlot, ATargetSlot, ADestination, APlayer, False)) then
    begin
      TLogAccess.Write(ClassName, 'Arrival');
      Exit();
    end;
    // Проверка на область закраски противником, на БЧТ она не влияет
    if (not ADestination.IsBigHole)
      and (not ADestination.Owner.IsRoleFriend(ADestination.Owner, APlayer)) then
    begin
      for TmpCover in ADestination.PlayerCoverage do
        if (TmpCover.Key.IsRoleEnemy(APlayer)) then
        begin
          TLogAccess.Write(ClassName, 'Cover');
          Exit();
        end;
    end;
    // Выгрузить можно не больше чем разрешено технологией
    TmpCount := TPlanetarProfile(APlayer.PlanetarProfile).TechShip(TmpHangar.ShipType, plttCount);
    if (ACount <= 0) then
      ACount := TmpCount
    else
      ACount := Min(ACount, TmpCount);
    // Выгрузить из технологий можно не больше чем есть в ангаре
    ACount := Min(ACount, TmpHangar.Count);
    // Уберем с ангара
    TPlanetarProfile(APlayer.PlanetarProfile).Hangar.Change(AHangarSlot, -ACount, APlayer);
    // Построим кораблик для выкладки
    TmpShip := CreateShip(ADestination, TmpHangar.ShipType, ATargetSlot, ACount, APlayer);
    // Отправим сообщение о создании корабля
    TPlanetarThread(Engine).SocketWriter.ShipCreate(TmpShip);
    // Добавить на планету назначения
    TPlanetarThread(Engine).ControlShips.AddToPlanet.Execute(TmpShip, ADestination, True, True, False);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlMoveFromHangar.Player(AHangarSlot: Integer; ADestination: TPlPlanet;
  ATargetSlot: TPlLanding; ACount: Integer; APlayer: TGlPlayer);
begin
  try
    // Проверка на активность планеты
    if (ADestination.State <> plsActive) then
    begin
      TLogAccess.Write(ClassName, 'Inactive');
      Exit();
    end;
    // Проверка номера слота высадки
    if (AHangarSlot < 0)
      or (AHangarSlot > TPlanetarProfile(APlayer.PlanetarProfile).Hangar.Size) then
    begin
      TLogAccess.Write(ClassName, 'Slot');
      Exit();
    end;
    // Нельзя высаживаться на планету с боем
    if (ADestination.Timer[ppltmBattle]) then
    begin
      TLogAccess.Write(ClassName, 'Battle');
      Exit();
    end;
    // Нельзя высаживаться на пульсар
    if (ADestination.PlanetType = pltPulsar) then
    begin
      TLogAccess.Write(ClassName, 'Pulsar');
      Exit();
    end;
    // Нельзя высаживаться на ЧТ
    if (ADestination.PlanetType = pltHole)
      and (not ADestination.IsBigHole) then
    begin
      TLogAccess.Write(ClassName, 'WormHole');
      Exit();
    end;
    // Пробуем высадиться
    Execute(AHangarSlot, ADestination, ATargetSlot, ACount, APlayer);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
