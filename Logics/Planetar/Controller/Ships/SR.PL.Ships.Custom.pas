{**********************************************}
{                                              }
{ Флот : общие функции                         }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Custom;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes;

type
  // Класс обработки общих функций флота
  TPLShipsControlCustom = class
  protected const
    I_MAX_SHIP_COUNT = 6;
    I_MAX_SHIP_ACTIVE = I_MAX_SHIP_COUNT - 1;
    I_MAX_SHIP_REFILL = I_MAX_SHIP_ACTIVE - 1;
    I_MAX_FUEL_COUNT = 5;
    I_FUEL_FOR_HANGAR = 2;
  protected var
    // Объект планетарной системы
    Engine: TObject;
  protected
    // Создание объекта корабля
    function CreateShip(APlanet: TPlPlanet; AShipType: TPlShipType; ASlot, ACount: Integer;
      APlayer: TGlPlayer): TPlShip;
    // Определение, является ли кораблик блокирующим
    function CheckShipBlocker(AShip: TPlShip; ASlot: TPlLanding; AEnemy: Boolean;
      AWantMode: TPlShipMode): TPlShip;
    // Поиск соседнего корабля, который имеет свойства блокирующего
    function CheckShipSide(ADestination: TPlPlanet; ASlot: TPlLanding;
      AWantMode: TPlShipMode): TPlShip;
    // Проверка возможности прилета корабля на орбиту
    function CheckArrival(ADestination: TPlPlanet; AShipLowOrbit: Boolean;
      ASlotFrom, ASlotTo: TPlLanding; AShipPlanet: TPlPlanet; AShipOwner: TGlPlayer;
      ACheckOnePlanet: Boolean): Boolean;
    // Проверка на возможность прилета и тыл
    function CheckMoveTo(AShip: TPlShip; ADestination: TPlPlanet; ASlotTo: Integer;
      ACheckOnePlanet: Boolean): Boolean;
    // Проверка возможности посадки корабля на слот
    function CheckBackZone(AIgnoreBackZone: Boolean; ADestination: TPlPlanet; ASlot: TPlLanding;
      AOwner: TGlPlayer): Boolean;
    // Получить свободный слот
    function GetFreeSlot(AIgnore: Boolean; ADestination: TPlPlanet; AShipLowOrbit: Boolean;
      AOwner: TGlPlayer): TPlLanding;
    // Нанесение урона юниту
    function DealDamage(AShip: TPlShip; ADamage: Integer; ADestruct: Boolean = True): Integer;
    // Обновление ХП или удаление убитого стека
    procedure WorkShipHP(APlanet: TPlPlanet);
  public
    // Создание контроллера для указанного созвездия
    constructor Create(AEngine: TObject);
  end;

implementation

uses
  SR.Planetar.Thread,
  SR.Planetar.Profile,
  SR.Planetar.Dictionary;

constructor TPLShipsControlCustom.Create(AEngine: TObject);
begin
  inherited Create();

  Engine := AEngine;
end;

function TPLShipsControlCustom.CreateShip(APlanet: TPlPlanet; AShipType: TPlShipType;
  ASlot, ACount: Integer; APlayer: TGlPlayer): TPlShip;
var
  TmpProfile: TPlanetarProfile;
begin
  TmpProfile := TPlanetarProfile(APlayer.PlanetarProfile);
  Result := nil;
  try
    Result := TPlShip.Create();
    Result.ID := TPlanetarThread(Engine).ControlShips.ListShips.Count;
    Result.ShipType := AShipType;
    Result.ChangeTech(@TmpProfile.TechShipProfile[AShipType], @TmpProfile.TechShipValues[AShipType]);
    Result.Planet := APlanet;
    Result.Owner := APlayer;
    Result.Planet := APlanet;
    Result.Count := ACount;
    Result.HP := Result.TechValue(plttHp);
    Result.Fuel := I_MAX_FUEL_COUNT;
    Result.Landing := ASlot;
    // Добавим в список корабликов
    TPlanetarThread(Engine).ControlShips.ListShips.Add(Result);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.GetFreeSlot(AIgnore: Boolean; ADestination: TPlPlanet;
  AShipLowOrbit: Boolean; AOwner: TGlPlayer): TPlLanding;
var
  TmpSlot: TPlLanding;
begin
  Result := 0;
  try
    TmpSlot := 1;
    repeat
      // Попытка найти внутренний слот
      if (AShipLowOrbit) then
        TmpSlot.Dec()
      else
        TmpSlot.Inc();
      // Проверим чтобы слот был пустым и не тылом
      if (ADestination.Landings.IsEmpty(TmpSlot))
        and (CheckBackZone(AIgnore, ADestination, TmpSlot, AOwner))
      then
        Exit(TmpSlot);
    until (TmpSlot = 1);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.CheckMoveTo(AShip: TPlShip; ADestination: TPlPlanet;
  ASlotTo: Integer; ACheckOnePlanet: Boolean): Boolean;
begin
  Result := False;
  try
    Result := CheckArrival(ADestination, AShip.TechActive(plttLowOrbit), AShip.Landing, ASlotTo, AShip.Planet, AShip.Owner, ACheckOnePlanet)
      and CheckBackZone(AShip.TechActive(plttIntoBackzone), ADestination, ASlotTo, AShip.Owner);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.CheckShipBlocker(AShip: TPlShip; ASlot: TPlLanding; AEnemy: Boolean;
  AWantMode: TPlShipMode): TPlShip;
begin
  Result := nil;
  try
    // Корабль должен быть активной военкой, крейсером или дредом
    if (not AShip.TechActive(plttCornerBlock)) then
      Exit(nil);
    // Проверим указанную сторну от кораблика
    Result := CheckShipSide(AShip.Planet, ASlot, AWantMode);
    if (Result = nil) then
      Exit(nil);
    // Корабль должен быть по центру врагом, с края - союзным
    if (AEnemy and AShip.Owner.IsRoleFriend(Result.Owner))
      or (not AEnemy and AShip.Owner.IsRoleEnemy(Result.Owner))
    then
      Exit(nil);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.CheckShipSide(ADestination: TPlPlanet; ASlot: TPlLanding;
  AWantMode: TPlShipMode): TPlShip;
begin
  Result := nil;
  try
    // Признак наличия корабля, нет блока если противник не стоит или стоит не в определенном режиме
    if (not ADestination.Landings.IsShip(ASlot, Result))
      or (Result.State <> pshstIddle)
      or (Result.Mode <> AWantMode)
    then
      Exit(nil);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.CheckArrival(ADestination: TPlPlanet;
  AShipLowOrbit: Boolean; ASlotFrom, ASlotTo: TPlLanding; AShipPlanet: TPlPlanet;
  AShipOwner: TGlPlayer; ACheckOnePlanet: Boolean): Boolean;
var
  TmpSelfPlanet: Boolean;
  TmpCount: TPlShipsCount;
begin
  Result := False;
  try
    // Расчет возможности перелета
    TmpSelfPlanet := (AShipPlanet = ADestination);
    // Если орбита боевая - проверяем параметры на 6 стеков если
    if (not ASlotTo.IsLowOrbit)
      and (not TmpSelfPlanet or not ASlotFrom.IsLowOrbit or not ACheckOnePlanet)
      and (ADestination.ShipCount.TryGetValue(AShipOwner, TmpCount))
      and (TmpCount.Exist = I_MAX_SHIP_COUNT) then
    begin
      TLogAccess.Write(ClassName, 'Full');
      Exit();
    end;
    Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.CheckBackZone(AIgnoreBackZone: Boolean; ADestination: TPlPlanet;
  ASlot: TPlLanding; AOwner: TGlPlayer): Boolean;
var
  TmpLeft: TPlShip;
  TmpRight: TPlShip;
begin
  Result := False;
  try
    // С техой влета в тыл везде можно
    if (AIgnoreBackZone) then
      Exit(True);
    // Левый слот тыла, быстрая проверка на свой юнит
    TmpLeft := CheckShipSide(ADestination, ASlot.Prev(), pshmdActive);
    if (TmpLeft = nil) or (TmpLeft.Owner.IsRoleFriend(AOwner)) then
      Exit(True);
    // Правый слот тыла, быстрая проверка на свой юнит
    TmpRight := CheckShipSide(ADestination, ASlot.Next(), pshmdActive);
    if (TmpRight = nil) or (TmpRight.Owner.IsRoleFriend(AOwner)) then
      Exit(True);
    // Если крайние кораблики не союзные друг другу, то тыла нет
    Result := TmpRight.Owner.IsRoleEnemy(TmpLeft.Owner);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.DealDamage(AShip: TPlShip; ADamage: Integer;
  ADestruct: Boolean): Integer;
var
  TmpDamage: Integer;
  TmpKilled: Integer;
  TmpHP: Integer;
begin
  Result := 0;
  try
    // Пропуск ненацеленных стволов
    if (not Assigned(AShip)) then
      Exit();
    // Отключение атаки вторым стволом и ретаргет внешних
    if (AShip.Count = 0) then
      Exit();
    // Посчитаем количество убитых и общий урон
    TmpHP := AShip.TechValue(plttHp);
    TmpKilled := Min(AShip.Count, Trunc(ADamage / TmpHP));
    TmpDamage := TmpKilled * TmpHP;
    // Учтем итоговый урон, убавим остаточный, уберем убитые
    Inc(Result, TmpDamage);       (**)
    Dec(ADamage, TmpDamage);
    Dec(AShip.Count, TmpKilled);
    if (ADestruct) then
      Inc(AShip.Destructed, TmpKilled);
    // Проверим наличие корабликов
    if (AShip.Count > 0) then
    begin
      TmpDamage := Min(AShip.HP, ADamage);
      Dec(AShip.HP, TmpDamage);
      Inc(Result, ADamage);
      // Замена корабля при хп в ноле
      if (AShip.HP = 0) then
      begin
        AShip.HP := TmpHP - (ADamage - TmpDamage);
        Dec(AShip.Count);
        // Убитые только если нужно
        if (ADestruct) then
          Inc(AShip.Destructed);
      end;
    end;
    // Если юнит убит - обновим данные планеты
    if (TmpKilled > 0) then
      TPlanetarThread(Engine).ControlPlanets.UpdateShipList(AShip, -TmpKilled);
    // Обновим параметры корабля, если он удален - взрываем
    if (ADestruct) then
      AShip.IsDestroyed := pshchDestruct
    else
      AShip.IsDestroyed := pshchSilent;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlCustom.WorkShipHP(APlanet: TPlPlanet);
var
  TmpI: Integer;
  TmpShip: TPlShip;
begin
  try
    for TmpI := Pred(APlanet.Ships.Count) downto 0 do
    begin
      TmpShip := APlanet.Ships[TmpI];
      if (TmpShip.IsDestroyed = pshchNone) then
        Continue;
      // Если ХП есть - обновим данные
      if (TmpShip.Count > 0) then
      begin
        TmpShip.IsDestroyed := pshchNone;
        TPlanetarThread(Engine).ControlShips.Repair.Check(TmpShip);
        TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(TmpShip);
      end else
      // Удалим с планеты
      begin
        TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(
          TmpShip, True, TmpShip.IsDestroyed = pshchDestruct, True);
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
