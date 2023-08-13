{**********************************************}
{                                              }
{ Флот : порталы                               }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Portal;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки порталов флота
  TPLShipsControlPortal = class(TPLShipsControlCustom)
  private const
    // Время быстрого портала
    CI_TIME_PORTAL_FAST = 3;
    // Время медленного портала
    CI_TIME_PORTAL_SLOW = 15;
  private
    // Определение времени портала
    function GetPortalTime(AShip: TPlShip): Integer;
    // Таймер прыжка в портал
    function OnTimer(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean;
  public
    // Включение или выключение прыжка в портал
    procedure Execute(AShip: TPlShip; ABreak: Boolean);
    // Выполнение команды игрока
    procedure Player(AShip: TPlShip; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlPortal.GetPortalTime(AShip: TPlShip): Integer;
begin
  Result := -1;
  try
    if (AShip.Planet.Portal.FastTransfer) then
      Result := CI_TIME_PORTAL_FAST
    else
      Result := CI_TIME_PORTAL_SLOW;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlPortal.OnTimer(AShip: TPlShip; var ACounter: Integer;
  var AValue: Integer): Boolean;
var
  TmpPortal: TPlPortal;
  TmpPlanet: TPlPlanet;
begin
  Result := False;
  try
    // Таймер не закончен
    if (ACounter > 0) then
    begin
      Dec(ACounter);
      Exit();
    end else
      Result := True;
    // Определим портал
    TmpPortal := AShip.Planet.Portal;
    // Определим направление прыжка
    if (AShip.Planet = TmpPortal.Enter) then
      TmpPlanet := TmpPortal.Exit
    else
      TmpPlanet := TmpPortal.Enter;
    // Попробуем отправить
    if (not TPlanetarThread(Engine).ControlShips.JumpToPlanet.Execute(AShip, TmpPlanet)) then
    begin
      ACounter := GetPortalTime(AShip);
      AValue := ACounter;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlPortal.Execute(AShip: TPlShip; ABreak: Boolean);
begin
  try
    // Прерывание прыжка
    if (ABreak) then
    begin
      TPlanetarThread(Engine).WorkerShips.TimerRemove(AShip, pshtmOpPortalJump);
      TPlanetarThread(Engine).ControlShips.StandUp.Execute(AShip, True, False);
    end else
    // Старт прыжка
    begin
      TPlanetarThread(Engine).WorkerShips.TimerAdd(AShip, pshtmOpPortalJump, GetPortalTime(AShip), OnTimer);
      TPlanetarThread(Engine).ControlShips.StandDown.Execute(AShip, AShip.Mode, False);
      AShip.State := pshstPortalJump;
    end;
    // Обновим состояние
    TPlanetarThread(Engine).SocketWriter.ShipUpdateState(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlPortal.Player(AShip: TPlShip; APlayer: TGlPlayer);
begin
  try
    // Нельзя управлять чужими
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // Отмена отправки корабля по порталу
    if (AShip.Timer[pshtmOpPortalJump]) then
    begin
      // Нельзя отменить непортующийся кораблик
      if (AShip.State <> pshstPortalJump) then
      begin
        TLogAccess.Write(ClassName, 'CantBreak');
        Exit();
      end;
      // Отменяем прыжок
      Execute(AShip, True);
    end else
    // Запуск корабля в портал
    begin
      // Нельзя управлять неюзабельными
      if (not AShip.CanOperable) then
      begin
        TLogAccess.Write(ClassName, 'Operable');
        Exit();
      end;
      // Нельзя отправлять если нет портала
      if (not Assigned(AShip.Planet.Portal)) then
      begin
        TLogAccess.Write(ClassName, 'NoPortal');
        Exit();
      end;
      // Нельзя отправлять во вражеский портал
      if (AShip.Planet.PlanetType <> pltHole)
        and (not AShip.Planet.Portal.Owner.IsRoleFriend(AShip.Owner)) then
      begin
        TLogAccess.Write(ClassName, 'Role');
        Exit();
      end;
      // Запустим таймер прыжка
      Execute(AShip, False);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
