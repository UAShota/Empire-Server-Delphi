{**********************************************}
{                                              }
{ Флот : поиск локальной цели для атаки        }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.TargetLocal;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки поиска локальной цели для атаки
  TPLShipsControlTargetLocal = class(TPLShipsControlCustom)
  private
      // Определить, какой кораблик из двух более приоритетен
    function GetShipPriority(ALeft, ARight: TPlShip): Boolean;
    // Получить расстояния между двумя корабликами
    function GetShipRange(ALeft, ARight: TPlShip): Integer;
    // Определить, какой кораблик из двух ближе к указанному
    function GetShipNear(ACenter, ALeft, ARight: TPlShip): Boolean;
    // Поиск противника для атаки
    function GetTargetShip(AShip: TPlShip; AIgnoreFriend, ALeft, AOneStep: Boolean;
      AOwner: TGlPlayer): TPlShip;
    // Прицел в лоб
    procedure TargetingToHead(AShip: TPlShip; ARightShip, ALeftShip: TPlShip; var ATarget: TPlShip);
    // Прицел в лоб в два края
    procedure TargetingToCorners(AShip: TPlShip; ARightShip, ALeftShip: TPlShip);
    // Прицел в лоб с прострелом через цель
    procedure TargetingToInner(AShip, ARightShip, ALeftShip, ARightShipInner, ALeftShipInner: TPlShip);
    // Прицел в две ближние цели
    procedure TargetingToDouble(AShip, ARightShip, ALeftShip, ARightShipInner, ALeftShipInner: TPlShip);
    // Прицеливание прострельным орудием
    procedure WeaponOvershot(AShip: TPlShip);
    // Прицеливание лазерами и ракетами
    procedure WeaponOverFriends(AShip: TPlShip; var AWeapon: TPlShip);
    // Прицеливание двойными лазерами
    procedure WeaponDoubleLaser(AShip: TPlShip);
    // Прицеливание двойными пулями
    procedure WeaponDoubleBullet(AShip: TPlShip);
    // Прицеливание пулей
    procedure WeaponBullet(AShip: TPlShip);
  public
    // Базовое выполнение
    procedure Execute(AShip: TPlShip);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlTargetLocal.GetShipPriority(ALeft, ARight: TPlShip): Boolean;
begin
  Result := False;
  try
    // Левый ближе если нет правого или если они равны
    Result := Assigned(ALeft) and
      (not Assigned(ARight)
        or (ALeft.ShipType = ARight.ShipType)
        or (ALeft.TechValue(plttPriority) <= ARight.TechValue(plttPriority)));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlTargetLocal.GetShipRange(ALeft, ARight: TPlShip): Integer;
var
  TmpRevert: Integer;
begin
  Result := 0;
  try
    Result := Abs(ALeft.Landing - ARight.Landing);
    // Расстояние назад
    TmpRevert := TPlLanding.Offset(-Result);
    // Меньше
    if (TmpRevert < Result) then
      Result := TmpRevert;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlTargetLocal.GetShipNear(ACenter, ALeft, ARight: TPlShip): Boolean;
begin
  Result := False;
  try
    // Левый ближе если нет правого или если он реально ближе
    Result := Assigned(ALeft) and
      (not Assigned(ARight) or (GetShipRange(ACenter, ALeft) <= GetShipRange(ACenter, ARight)));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.TargetingToHead(AShip, ARightShip, ALeftShip: TPlShip;
  var ATarget: TPlShip);
var
  TmpTargetCenter: TPlShip;
begin
  try
    if GetShipNear(AShip, ALeftShip, ARightShip) then
      TmpTargetCenter := ALeftShip
    else
      TmpTargetCenter := ARightShip;
    // Проверим изменения
    if (ATarget <> TmpTargetCenter) then
      ATarget := TmpTargetCenter;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.TargetingToCorners(AShip, ARightShip, ALeftShip: TPlShip);
begin
  try
    // Переключение батареи на другую если нет цели
    if (not Assigned(ALeftShip)) then
      ALeftShip := ARightShip;
    if (not Assigned(ARightShip)) then
      ARightShip := ALeftShip;
    // Проверим изменения
    if (AShip.Targets[pswRight] <> ARightShip) then
      AShip.Targets[pswRight] := ARightShip;
    if (AShip.Targets[pswLeft] <> ALeftShip) then
      AShip.Targets[pswLeft] := ALeftShip;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.TargetingToDouble(AShip, ARightShip, ALeftShip,
  ARightShipInner, ALeftShipInner: TPlShip);
begin
  try
    // Перевод второго орудия на прострел
    if (GetShipNear(AShip, ALeftShipInner, ARightShip)) then
      ARightShip := ALeftShipInner
    else
    if (GetShipNear(AShip, ARightShipInner, ALeftShip)) then
      ALeftShip := ARightShipInner;
    // Переключение батареи на другую если нет цели
    if (not Assigned(ARightShip)) then
      ARightShip := ALeftShip;
    if (not Assigned(ALeftShip)) then
      ALeftShip := ARightShip;
    // Проверим изменения
    if (AShip.Targets[pswRight] <> ARightShip) then
      AShip.Targets[pswRight] := ARightShip;
    if (AShip.Targets[pswLeft] <> ALeftShip) then
      AShip.Targets[pswLeft] := ALeftShip;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.TargetingToInner(AShip, ARightShip, ALeftShip,
  ARightShipInner, ALeftShipInner: TPlShip);
var
  TmpTargetCenter: TPlShip;
begin
  (*приоритет*)
  try
    TmpTargetCenter := nil;
    // Сперва цель второй прострел слева
    if Assigned(ALeftShipInner)
      and (ALeftShipInner.TechActive(plttOvershotTarget))
    then
      TmpTargetCenter := ALeftShipInner;
    // Далее смотрим приоритет левой цели
    if GetShipPriority(ALeftShip, TmpTargetCenter) then
      TmpTargetCenter := ALeftShip;
    // Теперь смотрим приоритет прострела правой цели
    if Assigned(ARightShipInner)
      and (ARightShipInner.TechActive(plttOvershotTarget))
      and GetShipPriority(ARightShipInner, TmpTargetCenter)
    then
      TmpTargetCenter := ARightShipInner;
    // И проверим что первая правая не приоритетнее
    if not Assigned(TmpTargetCenter)
      or (not (TmpTargetCenter.TechActive(plttOvershotTarget)) and not GetShipNear(AShip, TmpTargetCenter, ARightShip))
    then
      TmpTargetCenter := ARightShip;
    // Проверим изменения
    if (AShip.Targets[pswCenter] <> TmpTargetCenter) then
      AShip.Targets[pswCenter] := TmpTargetCenter;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlTargetLocal.GetTargetShip(AShip: TPlShip; AIgnoreFriend,
  ALeft, AOneStep: Boolean; AOwner: TGlPlayer): TPlShip;
var
  TmpSlot: TPlLanding;
begin
  Result := nil;
  try
    TmpSlot := AShip.Landing;
    repeat
      // Сдвинем слот
      if (ALeft) then
        TmpSlot.Dec()
      else
        TmpSlot.Inc();
      // Берем кораблик из слота
      if (AShip.Planet.Landings.IsShip(TmpSlot, Result)) then
      begin
        // Если это противник - он должен быть активным или последний
        if (Result.Owner.IsRoleEnemy(AOwner)) then
        begin
          if (Result.IsStateActive)
            or (Result.Planet.ShipCount[AShip.Owner].Active = 0)
          then
            Exit();
        end else
        // Иначе смотрим, можно ли простреливать своего
        begin
          if (not AIgnoreFriend)
            and (AShip.IsStateActive)
          then
            Exit(nil);
        end;
        // Если кораблик не найден - нечего возвращать
        Result := nil;
      end;
      // Нужен только соседний кораблик
      if (AOneStep) then
        Break;
    until (TmpSlot = AShip.Landing);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.WeaponDoubleBullet(AShip: TPlShip);
var
  TmpShipLeft: TPlShip;
  TmpShipRight: TPlShip;
begin
  try
    TmpShipRight := GetTargetShip(AShip, False, True, False, AShip.Owner);
    TmpShipLeft := GetTargetShip(AShip, False, False, False, AShip.Owner);
    // Определим нужную цель, корвет имеет прострел
    TargetingToCorners(AShip, TmpShipRight, TmpShipLeft);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.WeaponBullet(AShip: TPlShip);
var
  TmpShipLeft: TPlShip;
  TmpShipRight: TPlShip;
begin
  try
    TmpShipRight := GetTargetShip(AShip, False, True, False, AShip.Owner);
    TmpShipLeft := GetTargetShip(AShip, False, False, False, AShip.Owner);
    // Определим нужную цель, корвет имеет прострел
    TargetingToHead(AShip, TmpShipRight, TmpShipLeft, AShip.Targets[pswCenter]);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.WeaponDoubleLaser(AShip: TPlShip);
var
  TmpShipLeft: TPlShip;
  TmpShipRight: TPlShip;
  TmpShipInnerLeft: TPlShip;
  TmpShipInnerRight: TPlShip;
begin
  try
    TmpShipRight := GetTargetShip(AShip, True, True, False, AShip.Owner);
    TmpShipLeft := GetTargetShip(AShip, True, False, False, AShip.Owner);
    // Проверим прострел
    if (Assigned(TmpShipRight)) then
      TmpShipInnerRight := GetTargetShip(TmpShipRight, True, True, False, AShip.Owner)
    else
      TmpShipInnerRight := nil;
    if (Assigned(TmpShipLeft)) then
      TmpShipInnerLeft := GetTargetShip(TmpShipLeft, True, False, False, AShip.Owner)
    else
      TmpShipInnerLeft := nil;
    // Определим нужную цель
    TargetingToDouble(AShip, TmpShipRight, TmpShipLeft, TmpShipInnerRight, TmpShipInnerLeft);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.WeaponOverFriends(AShip: TPlShip; var AWeapon: TPlShip);
var
  TmpShipLeft: TPlShip;
  TmpShipRight: TPlShip;
begin
  try
    TmpShipRight := GetTargetShip(AShip, True, True, False, AShip.Owner);
    TmpShipLeft := GetTargetShip(AShip, True, False, False, AShip.Owner);
    TargetingToHead(AShip, TmpShipRight, TmpShipLeft, AWeapon);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.WeaponOvershot(AShip: TPlShip);
var
  TmpShipLeft: TPlShip;
  TmpShipRight: TPlShip;
  TmpShipInnerLeft: TPlShip;
  TmpShipInnerRight: TPlShip;
begin
  try
    TmpShipRight := GetTargetShip(AShip, False, True, False, AShip.Owner);
    TmpShipLeft := GetTargetShip(AShip, False, False, False, AShip.Owner);
    // Проверим прострел справа
    if Assigned(TmpShipRight)
      and (not TmpShipRight.TechActive(plttOvershotblocker))
      and (GetShipRange(AShip, TmpShipRight) = 1)
    then
      TmpShipInnerRight := GetTargetShip(TmpShipRight, False, True, True, AShip.Owner)
    else
      TmpShipInnerRight := nil;
    // Проверим прострел слева
    if Assigned(TmpShipLeft)
      and (not TmpShipLeft.TechActive(plttOvershotblocker))
      and (GetShipRange(AShip, TmpShipLeft) = 1)
    then
      TmpShipInnerLeft := GetTargetShip(TmpShipLeft, False, False, True, AShip.Owner)
    else
      TmpShipInnerLeft := nil;
    // Определим нужную цель
    TargetingToInner(AShip, TmpShipRight, TmpShipLeft, TmpShipInnerRight, TmpShipInnerLeft);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.Execute(AShip: TPlShip);
var
  TmpTargets: TPlShipTargets;
  TmpWeapon: TPlShipWeaponType;
begin
  try
    TmpTargets := AShip.Targets;
    // Для других ищем цели на текущей планете
    if (AShip.IsStateActive) then
    begin
      // Прострел через противника не зависит от орудия
      if (AShip.TechActive(plttWeaponOvershot)) then
        WeaponOvershot(AShip);
      // Лазер в крайнего через своих
      if (AShip.TechActive(plttWeaponLaser)) then
        WeaponOverFriends(AShip, AShip.Targets[pswCenter]);
      // Ракета стреляют в крайнего через своих
      if (AShip.TechActive(plttWeaponRocket)) then
        WeaponOverFriends(AShip, AShip.Targets[pswRocket]);
      // Двойной простреливающий лазер
      if (AShip.TechActive(plttWeaponDoubleLaser)) then
        WeaponDoubleLaser(AShip);
      // Двойной патрон
      if (AShip.TechActive(plttWeaponDoubleBullet)) then
        WeaponDoubleBullet(AShip);
      // Транспорт и прочие стреляют одним патроном в лоб
      if (AShip.TechActive(plttWeaponBullet)) then
        WeaponBullet(AShip);
    end else
      AShip.IsTargeted := False;
    // Отправим смену состояния
    for TmpWeapon := Low(TPlShipWeaponType) to High(TPlShipWeaponType) do
    begin
      if (TmpTargets[TmpWeapon] <> AShip.Targets[TmpWeapon]) then
        TPlanetarThread(Engine).SocketWriter.ShipRetarget(AShip, TmpWeapon);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
