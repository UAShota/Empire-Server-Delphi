{**********************************************}
{                                              }
{ ‘лот : учет добавлени€ юнита на планетоид    }
{        и попытка перевести в боевой режим    }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.StandUp;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  //  ласс обработки добавлени€ юнита в учет количества или актива
  TPLShipsControlStandUp = class(TPLShipsControlCustom)
  private
    // ѕроверка на необходимость заблокировать кораблик
    procedure DoCheckBlock(AShip: TPlShip);
    // ѕроверка на необходимость самозаблокироватьс€
    function DoCheckBlocked(AShip: TPlShip): Boolean;
  public
    // Ѕазовое выполнение
    procedure Execute(AShip: TPlShip; AChangeState: Boolean = True; AChangeMode: Boolean = True;
      AChangeCount: Boolean = False; ARetarget: Boolean = True);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlStandUp.DoCheckBlock(AShip: TPlShip);
var
  TmpTargetShip: TPlShip;
  TmpBlockerShip: TPlShip;
begin
  try
    // ≈сть ли вражеский кораблик дл€ блокировани€ справа и наш еще правее
    TmpTargetShip := CheckShipBlocker(AShip, AShip.Landing.Prev(), True, pshmdActive);
    if (Assigned(TmpTargetShip)) then
    begin
      TmpBlockerShip := CheckShipBlocker(AShip, AShip.Landing.Prev().Prev(), False, pshmdActive);
      if (TmpBlockerShip <> nil) then
        TPlanetarThread(Engine).ControlShips.StandDown.Execute(TmpTargetShip, pshmdBlocked);
    end;
    // ≈сть ли кораблик дл€ блокировани€ слева
    TmpTargetShip := CheckShipBlocker(AShip, AShip.Landing.Next(), True, pshmdActive);
    if (Assigned(TmpTargetShip)) then
    begin
      TmpBlockerShip := CheckShipBlocker(AShip, AShip.Landing.Next().Next(), False, pshmdActive);
      if (TmpBlockerShip <> nil) then
        TPlanetarThread(Engine).ControlShips.StandDown.Execute(TmpTargetShip, pshmdBlocked);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlStandUp.DoCheckBlocked(AShip: TPlShip): Boolean;
var
  TmpTargetShip: TPlShip;
begin
  Result := False;
  try
    // ≈сть ли кораблик дл€ блокировани€ справа
    TmpTargetShip := CheckShipBlocker(AShip, AShip.Landing.Prev(), True, pshmdActive);
    if not Assigned(TmpTargetShip) then
      Exit(True);
    // ≈сть ли кораблик дл€ блокировани€ слева
    TmpTargetShip := CheckShipBlocker(AShip, AShip.Landing.Next(), True, pshmdActive);
    if not Assigned(TmpTargetShip) then
      Exit(True);
    // ≈сли есть два противника - блокируемс€
    TPlanetarThread(Engine).ControlShips.StandDown.Execute(AShip, pshmdBlocked);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlStandUp.Execute(AShip: TPlShip; AChangeState, AChangeMode,
  AChangeCount, ARetarget: Boolean);
var
  TmpFlagFound: Boolean;
  TmpIndex: TPlShipsCountPair;
  TmpCount: TPlShipsCount;
begin
  try
    if (AChangeState) then
      AShip.State := pshstIddle;
    // ≈сли перемещение идет на нижний слот - добавление в сумму не нужно
    if (AShip.Landing.IsLowOrbit) then
    begin
      // ≈сли кораблик был избыточным - сменим состо€ние
      if (AChangeMode) then
        AShip.Mode := pshmdActive;
    end else
    begin
      // ѕо умолчанию кораблик есть и он активен
      TmpFlagFound := False;
      // —перва добавим кораблик во все списки как активный
      for TmpIndex in AShip.Planet.ShipCount do
      begin
        // ƒобавл€ем только в списки союзных войск
        if (not AShip.Owner.IsRoleFriend(TmpIndex.Key)) then
          Continue
        else
          TmpCount := TmpIndex.Value;
        // ќпределим, есть ли вообще свои стеки
        if (not TmpFlagFound) then
          TmpFlagFound := (TmpIndex.Key = AShip.Owner);
        // јктивным делаем при €вном указании либо избыточным если он уже активный
        if (AChangeMode) then
        begin
          if (TmpCount.Active = I_MAX_SHIP_ACTIVE) then
            AShip.Mode := pshmdFull
          else
            AShip.Mode := pshmdActive;
        end;
        // ќбновл€ем общее количество корабликов и количество активных
        Inc(TmpCount.Exist, Ord(AChangeCount));
        Inc(TmpCount.Active, Ord(AShip.IsStateActive));
        // «апишем назад
        AShip.Planet.ShipCount[TmpIndex.Key] := TmpCount;
      end;
      // ≈сли это первый кораблик - начнем список
      if (not TmpFlagFound) then
      begin
        TmpCount.Exist := 1;
        TmpCount.Active := Ord(AShip.IsStateActive);
        // «апишем назад
        AShip.Planet.ShipCount.Add(AShip.Owner, TmpCount);
      end;
      // ƒл€ активных кораблей сменим контроль и проверим боевку
      if (AShip.IsStateActive) then
      begin
        // ƒействи€, выполн€емые по прилету, автозахват планеты
        TPlanetarThread(Engine).ControlShips.Capture.Execute(AShip, True);
        // ѕри отправке например с ангара это не нужно
        if (ARetarget) then
        begin
          // ѕроверим, какие кораблики заблокировал этот кораблик и отправим закраску
          DoCheckBlock(AShip);
          // ѕроверим что можно подн€тьс€, если поднимаетс€ дева - ищем автоатаку
          DoCheckBlocked(AShip);
          // ѕереприцелим планету
          TPlanetarThread(Engine).ControlPlanets.Retarget(AShip, True);
        end;
      end;
    end;
    // ѕри запросе активных действий, уведомим клиента
    if (AChangeState or AChangeMode) then
      TPlanetarThread(Engine).SocketWriter.ShipUpdateState(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
