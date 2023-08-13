{**********************************************}
{                                              }
{ Флот : аннигиляция юнита                     }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Annihilation;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки аннигиляции юнита
  TPLShipsControlAnnihilation = class(TPLShipsControlCustom)
  private const
    // Время аннигиляции
    CI_TIME_ANNIHILATION = 10;
  private
    // Нанесение урона юниту
    procedure DoDamage(AShip: TPlShip; ADamageBase, ADamageExt: Integer);
    // Взрыв юнита
    procedure DoAnnihilate(AShip: TPlShip);
    // Срабатывание таймера операции
    function OnTimer(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean;
  public
    // Выполнение команды игрока
    procedure Player(AShip: TPlShip; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlAnnihilation.DoDamage(AShip: TPlShip; ADamageBase, ADamageExt: Integer);
begin
  try
    // Для военок используется дополнительный урон
    if (AShip.TechActive(plttStationary)) then
      ADamageBase := ADamageExt;
    // Нанесем урон
    DealDamage(AShip, ADamageBase);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlAnnihilation.DoAnnihilate(AShip: TPlShip);
var
  TmpPlanet: TPlPlanet;
  TmpShip: TPlShip;
  TmpBase: Integer;
  TmpDmgExt: Integer;
begin
  try
    TmpBase := AShip.Count * AShip.TechValue(plttAnnihilation);
    TmpDmgExt := TmpBase * 2;
    // Нанесем урон всем кораблям на орбите
    for TmpShip in AShip.Planet.Ships do
      DoDamage(TmpShip, TmpBase, TmpDmgExt);
    WorkShipHP(AShip.Planet);
    // Нанесем урон всем кораблям вне орбиты для бчт
    if (AShip.Planet.IsBigHole) then
    begin
      for TmpPlanet in AShip.Planet.Links do
      begin
        // Нанесем урон всем кораблям на орбите
        for TmpShip in TmpPlanet.Ships do
          DoDamage(TmpShip, TmpBase, TmpDmgExt);
        WorkShipHP(TmpPlanet);
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlAnnihilation.OnTimer(AShip: TPlShip; var ACounter: Integer;
  var AValue: Integer): Boolean;
const
  CS_NAME = 'OnTimer';
var
  TmpTime: Integer;
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
    // Выполним подрыв
    DoAnnihilate(AShip);
    // Обновим потанцевал
    TPlanetarThread(Engine).SocketWriter.PlanetLowGravityUpdate(AShip.Planet, True);
    // Добавочное время
    TmpTime := 60;
    // При повторном времени добавляется только процент от времени
    if (AShip.Planet.IsLowGravity) then
      TmpTime := Round(TmpTime * 0.5)
    else
      AShip.Planet.IsLowGravity := True;
    // Продлим время пульсара
    if (AShip.Planet.PlanetType = pltPulsar) then
    begin
      { TODO -omdv : Учитывать массу убитого флота }
      Inc(AShip.Planet.StateTime, TmpTime);
    end else
    // Продлим время червоточины
    if (AShip.Planet.PlanetType = pltHole) then
    begin
      { TODO -omdv : Учитывать массу убитого флота }
      Inc(AShip.Planet.Portal.Enter.StateTime, TmpTime);
      Inc(AShip.Planet.Portal.Exit.StateTime, TmpTime);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlAnnihilation.Player(AShip: TPlShip; APlayer: TGlPlayer);
begin
  try
    // Нельзя взрывать не деву
    if (not AShip.TechActive(plttAnnihilation)) then
    begin
      TLogAccess.Write(ClassName, 'NoTech');
      Exit();
    end;
    // Нельзя взрывать повторно
    if (AShip.Timer[pshtmOpAnnihilation]) then
    begin
      TLogAccess.Write(ClassName, 'Timer');
      Exit();
    end;
    // Нельзя управлять неюзабельными
    if (not AShip.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'Operable');
      Exit();
    end;
    // Нельзя взрывать если недостаточно кораблей
    if (AShip.Count < AShip.TechValue(plttCount) div 2) then
    begin
      TLogAccess.Write(ClassName, 'Count');
      Exit();
    end;
    // Нельзя управлять чужими
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // Уберем в пассив и выставим тайминг
    TPlanetarThread(Engine).ControlShips.StandDown.Execute(AShip, AShip.Mode, False);
    TPlanetarThread(Engine).WorkerShips.TimerAdd(AShip, pshtmOpAnnihilation, CI_TIME_ANNIHILATION, OnTimer);
    // Обновляем состояние
    AShip.State := pshstAnnihilation;
    TPlanetarThread(Engine).SocketWriter.ShipUpdateState(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
