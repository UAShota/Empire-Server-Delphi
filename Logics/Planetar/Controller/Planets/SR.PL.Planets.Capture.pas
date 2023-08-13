{**********************************************}
{                                              }
{ Планетоиды : обработка пульсара              }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{                                              }
{**********************************************}
unit SR.PL.Planets.Capture;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Planets.Custom;

type
  // Класс обработки боевого тика
  TPLPlanetsControlCapture = class(TPLPlanetsControlCustom)
  private type
    TCaptureItem = record
      Player: TGlPlayer;
      Coeff: Single;
    end;
  private const
    // Скорость захвата нейтральной планеты
    C_NEUTRAL_SPEED = 20;
    // Потолок для захвата
    C_CAPTURE_MAX = 100;
    // Множитель стеков убитых за тик
    C_CAPTURE_VICTIM = 180;
    // Скорость захвата за тик
    C_LEVEL_COEFF = 1.956521739;
    // Количество убитых корабликов за 1 скорость захвата
    C_CAPTURE_SHIPS = 999 / C_CAPTURE_VICTIM;
  private var
    // Количество игроков, которые могут захватывать контроль
    FCaptureData: array[0..TPlLandings.I_FIGHT_COUNT] of TCaptureItem;
    // Фактическое количество игроков, которые захватывают контроль
    FCaptureDataCount: Integer;
  private
    // Срабатывание таймера операции
    function OnTimer(APlanet: TPlPlanet; var ACounter: Integer; var AValue: Integer): Boolean;
    // Попытка сбить лояльность к врагу
    function DoCaptureByEnemy(APlanet: TPlPlanet; AShip: TPlShip): Boolean;
    // Попытка заиметь лояльность к себе
    function DoCaptureBySelf(APlanet: TPlPlanet; AShip: TPlShip): Boolean;
    // Определение скорости захвата и количества штурмов на это
    procedure DoCaptureParam(APlanet: TPlPlanet; AShip: TPlShip;
      var ASpeed: Single; var ACount: Integer);
    // Захват лояльности определенной планеты
    procedure DoCapturePlanet(APlanet: TPlPlanet; AShip: TPlShip);
    // Подсчет итогов захвата за тик
    procedure DoCaptureEnd(AShip: TPlShip);
  public
    // Базовое выполнение
    procedure Execute(APlanet: TPlPlanet);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLPlanetsControlCapture.OnTimer(APlanet: TPlPlanet; var ACounter, AValue: Integer): Boolean;
var
  TmpShip: TPlShip;
  TmpCapture: Single;
begin
  Result := False;
  try
    TmpCapture := APlanet.CaptureValue;
    FCaptureDataCount := 0;
    // Переберем всех нападающих
    for TmpShip in APlanet.Ships do
    begin
      if (not TmpShip.IsCapture) then
        Continue;
      // Либо отнимает лояльность у врага в пользу нейтрала, либо прибавляем себе
      if (DoCaptureByEnemy(APlanet, TmpShip))
        or DoCaptureBySelf(APlanet, TmpShip) then
      begin
        DoCaptureEnd(TmpShip);
        ACounter := 0;
        Break;
      end;
    end;
    // Обновим параметры планеты если нужно, т.к. захватчиком может быть несколько
    if (APlanet.CaptureValue <> TmpCapture) then
      TPlanetarThread(Engine).SocketWriter.PlanetCaptureUpdate(APlanet);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLPlanetsControlCapture.DoCaptureByEnemy(APlanet: TPlPlanet; AShip: TPlShip): Boolean;
var
  TmpSpeed: Single;
  TmpCount: Integer;
begin
  Result := True;
  // Пропускаем свое или пустое влияние
  if (AShip.Owner = APlanet.CapturePlayer)
    or (APlanet.CapturePlayer = nil)
  then
    Exit(False);
  // Соберем параметры захвата
  DoCaptureParam(APlanet, AShip, TmpSpeed, TmpCount);
  // Прибьем затраченные кораблики
  AShip.Count := AShip.Count - TmpCount;
  // Уберем лояльность противника
  APlanet.CaptureValue := APlanet.CaptureValue - TmpSpeed;
  // Уберем совсем его влияние
  if (APlanet.CaptureValue < 1) then
    APlanet.CapturePlayer := nil;
end;

function TPLPlanetsControlCapture.DoCaptureBySelf(APlanet: TPlPlanet; AShip: TPlShip): Boolean;
var
  TmpSpeed: Single;
  TmpCount: Integer;
begin
  Result := True;
  // Не просчитываем если лояльность полная
  if (APlanet.Owner = AShip.Owner)
    and (APlanet.CaptureValue = 0)
  then
    Exit(False);
  // Соберем параметры захвата
  DoCaptureParam(APlanet, AShip, TmpSpeed, TmpCount);
  // Увеличиваем свою лояльность
  AShip.Count := AShip.Count - TmpCount;
  APlanet.CapturePlayer := AShip.Owner;
  APlanet.CaptureValue := APlanet.CaptureValue + TmpSpeed;
  // Захватим планету
  if (APlanet.CaptureValue = C_CAPTURE_MAX) then
    DoCapturePlanet(APlanet, AShip);
end;

procedure TPLPlanetsControlCapture.DoCaptureParam(APlanet: TPlPlanet; AShip: TPlShip;
  var ASpeed: Single; var ACount: Integer);
var
  TmpSpeed: Single;
  TmpCount: Single;
  TmpI: Integer;
  TmpCoeff: Single;
  TmpFound: Boolean;
begin
  // Нейтралка всегда 5 секунд и 10 стеков за секунду
  if (APlanet.Owner = nil) then
  begin
    TmpSpeed := C_NEUTRAL_SPEED;
    TmpCount := 2;
  end else
  begin
    TmpSpeed := C_CAPTURE_VICTIM / (C_LEVEL_COEFF * APlanet.Level);
    TmpCount := 2;
  end;
  // Уменьшим скорость на коэффициент атаки если штурм не первый для этого-же владельца
  TmpFound := False;
  TmpCoeff := C_CAPTURE_MAX;
  for TmpI := 0 to Pred(FCaptureDataCount) do
  begin
    if (FCaptureData[TmpI].Player = AShip.Owner) then
    begin
      TmpFound := True;
      TmpCoeff := FCaptureData[TmpI].Coeff;
      FCaptureData[TmpI].Coeff := TmpCoeff / 2;
      Break;
    end;
  end;
  // 1 стек = C_CAPTURE_MAX, 2 стек = 25, 3 стек = 12.5, 4 стек = 6, 5 стек = 3 : +46%
  if (not TmpFound) then
  begin
    FCaptureData[FCaptureDataCount].Player := AShip.Owner;
    FCaptureData[FCaptureDataCount].Coeff := C_CAPTURE_MAX;
    Inc(FCaptureDataCount);
  end;
  if (TmpCoeff < C_CAPTURE_MAX) then
    TmpSpeed := TmpSpeed / C_CAPTURE_MAX * TmpCoeff;
  // Проверим на случай если лояльность меньше скорости захвата - пересчитаем затребованные кораблики
  if (C_CAPTURE_MAX - APlanet.CaptureValue < TmpSpeed) then
  begin
    TmpCount := TmpCount * (APlanet.CaptureValue / TmpSpeed);
    TmpSpeed := 0;
    APlanet.CaptureValue := C_CAPTURE_MAX;
  end;
  // Проверим количество корабликов, нужные для захвата
  if (AShip.Count < Round(TmpCount)) then
  begin
    TmpSpeed := TmpSpeed * (AShip.Count / TmpCount);
    TmpCount := AShip.Count;
  end;
  ASpeed := TmpSpeed;
  ACount := Round(TmpCount);
end;

procedure TPLPlanetsControlCapture.DoCaptureEnd(AShip: TPlShip);
begin
  // Обновим ХП кораблика или уничтожим пустой стек
  if (AShip.Count > 0) then
    TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(AShip)
  else
    TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(AShip, True, True, False);
end;

procedure TPLPlanetsControlCapture.DoCapturePlanet(APlanet: TPlPlanet; AShip: TPlShip);
var
  TmpShip: TPlShip;
begin
  // Уберем бонусы противника
  for TmpShip in APlanet.Ships do
  begin
    if (TmpShip.Owner = AShip.Owner) then
      Continue;
    TPlanetarThread(Engine).ControlPlanets.UpdateShipList(TmpShip, -TmpShip.Count);
    if (TmpShip.IsCapture) then
      TPlanetarThread(Engine).ControlShips.Attach.Execute(AShip, nil, False);
  end;
  // Уберем контроль противника
  TPlanetarThread(Engine).ControlPlanets.PlayerControlChange(APlanet, APlanet.Owner, False, False);
  // Заменим параметры
  APlanet.Owner := AShip.Owner;
  APlanet.CaptureValue := 0;
  APlanet.Name := AShip.Owner.Name;
  // Добавим свои бонусы
  for TmpShip in APlanet.Ships do
  begin
    if (TmpShip.Owner <> AShip.Owner) then
      Continue;
    TPlanetarThread(Engine).ControlPlanets.UpdateShipList(TmpShip, TmpShip.Count);
    if (TmpShip.IsCapture) then
      TPlanetarThread(Engine).ControlShips.Attach.Execute(TmpShip, nil, False);
  end;
  // Отправим сообщение о владельце
  TPlanetarThread(Engine).SocketWriter.PlanetOwnerChanged(APlanet);
  // Добавим свой контроль
  TPlanetarThread(Engine).ControlPlanets.PlayerControlChange(APlanet, APlanet.Owner, True, False);
end;

procedure TPLPlanetsControlCapture.Execute(APlanet: TPlPlanet);
begin
  TPlanetarThread(Engine).WorkerPlanets.TimerAdd(APlanet, ppltmCapture, 1, OnTimer);
end;

end.
