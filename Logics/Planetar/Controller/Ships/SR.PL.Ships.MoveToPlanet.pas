{**********************************************}
{                                              }
{ Флот : перелет на указанный планетоид        }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.MoveToPlanet;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки перелетов
  TPLShipsControlMoveToPlanet = class(TPLShipsControlCustom)
  private
    // Проверка на возможность слета с планеты
    function GetDepartureAvailable(AShip: TPlShip; ADestination: TPlPlanet): Boolean;
  public
    // Базовое выполнение
    function Execute(AShip: TPlShip; ADestination: TPlPlanet; ASlot: Integer = 0; ACheck: Boolean = True;
      AAttach: Boolean = False): Boolean;
    // Выполнение команды игрока
    procedure Player(AShip: TPlShip; ADestination: TPlPlanet; ASlot: TPlLanding; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlMoveToPlanet.GetDepartureAvailable(AShip: TPlShip;
  ADestination: TPlPlanet): Boolean;
var
  TmpShip: TPlShip;
begin
  Result := False;
  try
    // Проверка активности планетоида
    if (ADestination.State <> plsActive) then
      Exit();
    // Проверка наличия топлива
    if (AShip.Planet <> ADestination)
      and (AShip.Fuel = 0) then
    begin
      TLogAccess.Write(ClassName, 'NoFuel');
      Exit();
    end;
    // Запрет слета работает только на планетах
    if (not AShip.Planet.IsManned)
      or (not AShip.Planet.Timer[ppltmBattle])
    then
      Exit(True);
    // Если на планете работает потенциал - то слетать можно
    if (AShip.Planet.IsLowGravity) then
      Exit(True);
    // Иначе если не корвет и не дева - слетать нельзя
    if (not AShip.TechActive(plttFaster)) then
    begin
      TLogAccess.Write(ClassName, 'NoFaster');
      Exit();
    end;
    // Поиск враждебной военной базы, которая блокирует любые слеты
    for TmpShip in AShip.Planet.Ships do
    begin
      if (TmpShip.TechActive(plttSpeedBlocker))
        and (TmpShip.IsStateActive)
        and (TmpShip.Owner.IsRoleEnemy(AShip.Owner)) then
      begin
        TLogAccess.Write(ClassName, 'SpeedBlocker');
        Exit();
      end;
    end;
    // Если блокировок нет - слет успешен
    Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlMoveToPlanet.Execute(AShip: TPlShip; ADestination: TPlPlanet; ASlot: Integer;
  ACheck, AAttach: Boolean): Boolean;
begin
  Result := False;
  try
    // Найдем слот если нужно
    if (ASlot = 0) then
      ASlot := GetFreeSlot(AShip.TechActive(plttIntoBackzone), ADestination, AShip.TechActive(plttLowOrbit), AShip.Owner);
    // Если доступного слота нет - лететь некуда
    if (ASlot = 0) then
    begin
      TLogAccess.Write(ClassName, 'Slot');
      Exit();
    end;
    // Если учет этой функции был ранее - то не проверяется второй раз
    if (ACheck) then
    begin
      // Проверка на отлет
      if (AShip.Planet <> ADestination)
        and (not GetDepartureAvailable(AShip, ADestination)) then
      begin
        TLogAccess.Write(ClassName, 'Departure');
        Exit();
      end;
      // Проверка на прилет
      if (not CheckMoveTo(AShip, ADestination, ASlot, True)) then
      begin
        TLogAccess.Write(ClassName, 'Arrival');
        Exit();
      end;
    end;
    // Удалить с текущей планеты
    TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(
      AShip, False, False, AShip.Planet <> ADestination);
    // Установка времени перелета
    if (AShip.Planet = ADestination) then
      TPlanetarThread(Engine).ControlShips.Fly.Execute(AShip, pshstMovingLocal)
    else
      TPlanetarThread(Engine).ControlShips.Fly.Execute(AShip, pshstMovingGlobal);
    // Установка цели перелета
    AShip.IsAutoAttach := AAttach;
    AShip.IsTargeted := False;
    AShip.Planet := ADestination;
    AShip.Landing := ASlot;
    // Добавить на планету назначения
    TPlanetarThread(Engine).ControlShips.AddToPlanet.Execute(
      AShip, ADestination, AShip.Planet <> ADestination, False, True);
    // Отправим сообщение
    TPlanetarThread(Engine).SocketWriter.ShipMoveTo(AShip, ADestination, ASlot);
    // Переместили успешно
    Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlMoveToPlanet.Player(AShip: TPlShip; ADestination: TPlPlanet;
  ASlot: TPlLanding; APlayer: TGlPlayer);
begin
  try
    // Проверка на корректность слота
    if (not TPlLanding.Valid(ASlot)) then
    begin
      TLogAccess.Write(ClassName, 'Slot');
      Exit();
    end;
    // Нельзя управлять неактивными корабликами
    if (not AShip.CanOperable(True)) then
    begin
      TLogAccess.Write(ClassName, 'Operable');
      Exit();
    end;
    // Нельзя отправлять на неактивные планеты
    if (ADestination.State <> plsActive) then
    begin
      TLogAccess.Write(ClassName, 'Inactive');
      Exit();
    end;
    // Проверка на свободный слот
    if (not ADestination.Landings.IsEmpty(ASlot)) then
    begin
      TLogAccess.Write(ClassName, 'Aquired');
      Exit();
    end;
    // Прверим нижнюю орбиту
    if (ASlot.IsLowOrbit) then
    begin
      // Запрет если идет бой
      if (ADestination.Timer[ppltmBattle]) then
      begin
        TLogAccess.Write(ClassName, 'LowInBattle');
        Exit();
      end;
      // Запрет если не может там быть
      if (not AShip.TechActive(plttLowOrbit)) then
      begin
        TLogAccess.Write(ClassName, 'LowWrongType');
        Exit();
      end;
    end;
    // Нельзя управлять чужими корабликами
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // Проверим  на перелет на другую планету
    if (AShip.Planet <> ADestination) then
    begin
      // Нельзя перелетать на планеты вне радиуса перелета
      if (not AShip.Planet.Links.Contains(ADestination)) then
      begin
        TLogAccess.Write(ClassName, 'Links');
        Exit();
      end;
      // Стационарные не летают на другие планеты
      if (AShip.TechActive(plttStationary)) then
      begin
        TLogAccess.Write(ClassName, 'Stationary');
        Exit();
      end;
    end;
    // Попытка отправить кораблик
    if (not Execute(AShip, ADestination, ASlot)) then
    begin
      TLogAccess.Write(ClassName, 'CantMove');
      Exit();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
