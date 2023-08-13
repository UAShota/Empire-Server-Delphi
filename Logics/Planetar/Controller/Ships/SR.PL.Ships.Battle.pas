{**********************************************}
{                                              }
{ Боевка : обработка боевого тика              }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Battle;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки боевого тика
  TPLShipsControlBattle = class(TPLShipsControlCustom)
  private
    // Корректировка урона с учетом бонусов
    function GetCorrectDamage(AShip: TPlShip; ADamage: Integer): Integer;
    // Атака орудий нацеленного кораблика
    procedure DoAttackTarget(APlanet: TPlPlanet; AShip: TPlShip);
    // Переприцел юнитов на планете
    procedure DoRetarget(APlanet: TPlPlanet; AExternal: Boolean = False);
  public
    // Базовое выполнение
    function Execute(APlanet: TPlPlanet): Boolean;
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlBattle.GetCorrectDamage(AShip: TPlShip; ADamage: Integer): Integer;
begin
  Result := ADamage;
  try
    // Стационарки стреляют константным дамагом
    if (not AShip.TechActive(plttStationary)) then
      Result := Min(2000, AShip.Count * Result);
    {$IFNDEF DEBUG}
   // Result := 2;
    {$ENDIF}
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlBattle.DoRetarget(APlanet: TPlPlanet; AExternal: Boolean);
var
  TmpI: Integer;
  TmpList: TPlShipList;
  TmpShip: TPlShip;
begin
  try
    // Выберем список
    if (AExternal) then
      TmpList := APlanet.RangeAttackers
    else
      TmpList := APlanet.Ships;
    // Проверим наличие кораблей
    for TmpI := Pred(TmpList.Count) downto 0 do
    begin
      TmpShip := TmpList[TmpI];
      // Пропуск внутренних слотов и нацеленных дев на другую планету
      if (AExternal = TmpShip.IsAttachedRange(True))
        and (not TmpShip.Landing.IsLowOrbit) then
      begin
        if (AExternal) then
          TPlanetarThread(Engine).ControlShips.TargetMarker.Highlight(
            TmpShip, TmpShip.Attached, TmpShip.IsAutoTarget)
        else
          TPlanetarThread(Engine).ControlShips.TargetLocal.Execute(TmpShip);
      end;
    end;
    // Прицелим дальние
    if (not AExternal) then
      DoRetarget(APlanet, True);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlBattle.DoAttackTarget(APlanet: TPlPlanet; AShip: TPlShip);
var
  TmpDmg: Integer;
begin
  try
    // Двойные пули
    TmpDmg := AShip.TechValue(plttWeaponDoubleBullet);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswLeft], TmpDmg);
      DealDamage(AShip.Targets[pswRight], TmpDmg);
    end;
    // Двойные лазеры
    TmpDmg := AShip.TechValue(plttWeaponDoubleLaser);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswLeft], TmpDmg);
      DealDamage(AShip.Targets[pswRight], TmpDmg);
    end;
    // Одиночный патрон
    TmpDmg := AShip.TechValue(plttWeaponBullet);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswCenter], TmpDmg);
    end;
    // Прострелочный патрон
    TmpDmg := AShip.TechValue(plttWeaponOvershot);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswCenter], TmpDmg);
    end;
    // Одиночный лазер
    TmpDmg := AShip.TechValue(plttWeaponLaser);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswCenter], TmpDmg);
    end;
    // Ракета
    TmpDmg := AShip.TechValue(plttWeaponRocket);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswRocket], TmpDmg);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlBattle.Execute(APlanet: TPlPlanet): Boolean;
var
  TmpShip: TPlShip;
begin
  Result := False;
  try
    // Поиск цели только при смене ситуации на планете
    if (APlanet.IsRetarget) then
      DoRetarget(APlanet);
    // Атака локальных корабликов
    for TmpShip in APlanet.Ships do
    begin
      if (TmpShip.IsTargeted)
        and (not TmpShip.IsAttachedRange(True)) then
      begin
        Result := True;
        DoAttackTarget(APlanet, TmpShip);
      end;
    end;
    // Атака внешних корабликов
    if (Result) then
    begin
      for TmpShip in APlanet.RangeAttackers do
      begin
        if (TmpShip.IsTargeted) then
          DoAttackTarget(APlanet, TmpShip);
      end;
      // Прицелим свободные кораблики с других планет при наличии боя или свои корабли на другие планеты
      if (APlanet.IsRetarget) then
      begin
        APlanet.IsRetarget := False;
        TPlanetarThread(Engine).ControlShips.Retarget.Execute(APlanet);
      end;
    end;
    // Усредним количество привязанных корабликов
    TPlanetarThread(Engine).ControlShips.Hypodispersion.ByPlanet(APlanet);
    // Отправим сообщение о смене ХП нуждающимся корабликам
    WorkShipHP(APlanet);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
