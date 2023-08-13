{**********************************************}
{                                              }
{ Флот : постройка и ремонт юнита              }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Construct;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Globals.Types,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки постройки юнита
  TPLShipsControlConstruct = class(TPLShipsControlCustom)
  private const
    I_MAX_SHIPYARD_ACTIVE = 4;
  private
    // Количество ХП добавляемого за тик
    function GetHPperTick(AShip: TPlShip): Integer;
    // Таймер события постройки
    function OnTimer(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean;
  public
    // Базовое выполнение
    function Execute(APlanet: TPlPlanet; AShipType: TPlShipType; ACount: Integer;
      APlayer: TGlPlayer): TPlShip;
    // Выполнение команды игрока
    procedure Player(APlanet: TPlPlanet; AShipType: TPlShipType; ACount: Integer;
      APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread,
  SR.Planetar.Profile;

function TPLShipsControlConstruct.GetHPperTick(AShip: TPlShip): Integer;
var
  TmpCount: TPlShipsCount;
begin
  Result := -1;
  try
    // Найдем количество верфей строящегося игрока, 1 верфь есть всегда по умолчанию
    if (not AShip.Planet.Constructors.TryGetValue(AShip.Owner, TmpCount)) then
    begin
      if (AShip.TechActive(plttStationary)) then
        TmpCount.Value := 1
      else
        Exit();
    end;
    // Минимум 150хп / сек
    Result := Min(TmpCount.Value, I_MAX_SHIPYARD_ACTIVE) * AShip.TechValue(plttConstruction);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlConstruct.OnTimer(AShip: TPlShip; var ACounter: Integer;
  var AValue: Integer): Boolean;
var
  TmpTotal: Integer;
  TmpCount: Integer;
begin
  Result := False;
  try
    // Попробуем завершить постройку
    if (ACounter = 0) then
    begin
      if (not AShip.CanOperable(True)) then
        Exit();
      AShip.HP := AShip.TechValue(plttHp);
      // Завершим постройку
      TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(AShip);
      // Выставим стартовые состояния если кораблик не в состоянии полета
      TPlanetarThread(Engine).ControlShips.StandUp.Execute(AShip);
      // Обновим параметры планеты для стационарных построек
      TPlanetarThread(Engine).ControlPlanets.UpdateShipList(AShip, AShip.Count);
      // Отправим смену таймера
      Result := True;
    end;
    // Определим хп
    TmpCount := GetHPperTick(AShip);
    TmpTotal := (AShip.Count * AShip.TechValue(plttHp));
    // Нельзя строить не в простое
    if (AShip.CanOperable(True)) then
      Inc(AShip.HP, TmpCount)
    else
      TmpCount := -TmpCount;
    // Если построены все юниты - уведомим
    if (AShip.HP >= TmpTotal) then
      ACounter := 0
    // Если нет - проверим, изменилась ли скорость
    else if (TmpCount <> ACounter) then
    begin
      ACounter := TmpCount;
      AValue := (TmpTotal - AShip.HP) div ACounter;
      Result := True;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlConstruct.Execute(APlanet: TPlPlanet; AShipType: TPlShipType; ACount: Integer;
  APlayer: TGlPlayer): TPlShip;
var
  TmpLowOrbit: Boolean;
  TmpBackzone: Boolean;
  TmpSlot: Integer;
  TmpCost: Integer;
  TmpCount: Integer;
begin
  Result := nil;
  try
    TmpLowOrbit := TPlanetarProfile(APlayer.PlanetarProfile).TechShipProfile[AShipType, plttLowOrbit].Supported;
    TmpBackzone := TPlanetarProfile(APlayer.PlanetarProfile).TechShipProfile[AShipType, plttIntoBackzone].Supported;
    // Найдем свободный слот
    TmpSlot := GetFreeSlot(TmpBackzone, APlanet, TmpLowOrbit, APlayer);
    if (TmpSlot = 0) then
    begin
      TLogAccess.Write(ClassName, 'Slot');
      Exit();
    end;
    // Попытка высадить ожидаемый кораблик в указанный слот
    if (not CheckArrival(APlanet, TmpLowOrbit, TmpSlot, TmpSlot, APlanet, APlanet.Owner, False)) then
    begin
      TLogAccess.Write(ClassName, 'Arrival');
      Exit();
    end;
    // Дабы не захламлять
    TmpCount := Min(ACount, TPlanetarProfile(APlayer.PlanetarProfile).TechShip(AShipType, plttCount));
    TmpCost := TmpCount * TPlanetarProfile(APlayer.PlanetarProfile).TechShip(AShipType, plttCost);
    // Проверить наличие ресурсов для постройки
    if (APlanet.ResAvailIn[resModules] < TmpCost) then
    begin
      TLogAccess.Write(ClassName, 'Modules');
      Exit();
    end;
    // Если все есть - построим кораблик
    Result := CreateShip(APlanet, AShipType, TmpSlot, TmpCount, APlayer);
    Result.Mode := pshmdConstruction;
    Result.HP := 0;
    // Уменьшим количество затраченных ресурсов
    TPlanetarThread(Engine).ControlStorages.DecrementResource(resModules, APlanet, TmpCost);
    // Добавим созданный кораблик на планеты
    TPlanetarThread(Engine).ControlShips.AddToPlanet.Execute(Result, APlanet, False, False, APlanet.Timer[ppltmBattle]);
    // Отправим сообщение
    TPlanetarThread(Engine).SocketWriter.ShipCreate(Result);
    // Добавим таймер
    TPlanetarThread(Engine).WorkerShips.TimerAdd(Result, pshtmOpConstruction,
      GetHPperTick(Result), OnTimer, Result.Count * Result.TechValue(plttHP) div GetHPperTick(Result));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlConstruct.Player(APlanet: TPlPlanet; AShipType: TPlShipType;
  ACount: Integer; APlayer: TGlPlayer);
var
  TmpStationary: Boolean;
begin
  try
    // Нельзя строить непонятное количество юнитов
    if (ACount <= 0) then
    begin
      TLogAccess.Write(ClassName, 'Count');
      Exit();
    end;
    // Нельзя строить если планета в бою
    if (APlanet.Timer[ppltmBattle]) then
    begin
      TLogAccess.Write(ClassName, 'Battle');
      Exit();
    end;
    // Нельзя строить если технология закрыта
    if (TPlanetarProfile(APlayer.PlanetarProfile).TechShip(AShipType, plttActive) = 0) then
    begin
      TLogAccess.Write(ClassName, 'Tech');
      Exit();
    end;
    // Определим параметры будущего юнита
    TmpStationary := TPlanetarProfile(APlayer.PlanetarProfile).TechShipProfile[AShipType, plttStationary].Supported;
    // Проверка постройки нестационарнго флота
    if (not APlanet.IsManned) then
    begin
      // Нельзя строить на чужой планете
      if (not APlanet.Owner.IsRoleFriend(APlayer)) then
      begin
        TLogAccess.Write(ClassName, 'Role');
        Exit();
      end;
      // На нежилых можно строить только стационарки
      if (not TmpStationary) then
      begin
        TLogAccess.Write(ClassName, 'Manned');
        Exit();
      end;
    end;
    // На жилых не стационарный флот можно строить только если есть верфь
    if (not TmpStationary)
      and (not APlanet.Constructors.ContainsKey(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Shipyard');
      Exit();
    end;
    // Иначе построим кораблик
    Execute(APlanet, AShipType, ACount, APlayer);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
