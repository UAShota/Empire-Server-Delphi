{**********************************************}
{                                              }
{ ���������� : ��������� ��������              }
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
  // ����� ��������� ������� ����
  TPLPlanetsControlCapture = class(TPLPlanetsControlCustom)
  private type
    TCaptureItem = record
      Player: TGlPlayer;
      Coeff: Single;
    end;
  private const
    // �������� ������� ����������� �������
    C_NEUTRAL_SPEED = 20;
    // ������� ��� �������
    C_CAPTURE_MAX = 100;
    // ��������� ������ ������ �� ���
    C_CAPTURE_VICTIM = 180;
    // �������� ������� �� ���
    C_LEVEL_COEFF = 1.956521739;
    // ���������� ������ ���������� �� 1 �������� �������
    C_CAPTURE_SHIPS = 999 / C_CAPTURE_VICTIM;
  private var
    // ���������� �������, ������� ����� ����������� ��������
    FCaptureData: array[0..TPlLandings.I_FIGHT_COUNT] of TCaptureItem;
    // ����������� ���������� �������, ������� ����������� ��������
    FCaptureDataCount: Integer;
  private
    // ������������ ������� ��������
    function OnTimer(APlanet: TPlPlanet; var ACounter: Integer; var AValue: Integer): Boolean;
    // ������� ����� ���������� � �����
    function DoCaptureByEnemy(APlanet: TPlPlanet; AShip: TPlShip): Boolean;
    // ������� ������� ���������� � ����
    function DoCaptureBySelf(APlanet: TPlPlanet; AShip: TPlShip): Boolean;
    // ����������� �������� ������� � ���������� ������� �� ���
    procedure DoCaptureParam(APlanet: TPlPlanet; AShip: TPlShip;
      var ASpeed: Single; var ACount: Integer);
    // ������ ���������� ������������ �������
    procedure DoCapturePlanet(APlanet: TPlPlanet; AShip: TPlShip);
    // ������� ������ ������� �� ���
    procedure DoCaptureEnd(AShip: TPlShip);
  public
    // ������� ����������
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
    // ��������� ���� ����������
    for TmpShip in APlanet.Ships do
    begin
      if (not TmpShip.IsCapture) then
        Continue;
      // ���� �������� ���������� � ����� � ������ ��������, ���� ���������� ����
      if (DoCaptureByEnemy(APlanet, TmpShip))
        or DoCaptureBySelf(APlanet, TmpShip) then
      begin
        DoCaptureEnd(TmpShip);
        ACounter := 0;
        Break;
      end;
    end;
    // ������� ��������� ������� ���� �����, �.�. ����������� ����� ���� ���������
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
  // ���������� ���� ��� ������ �������
  if (AShip.Owner = APlanet.CapturePlayer)
    or (APlanet.CapturePlayer = nil)
  then
    Exit(False);
  // ������� ��������� �������
  DoCaptureParam(APlanet, AShip, TmpSpeed, TmpCount);
  // ������� ����������� ���������
  AShip.Count := AShip.Count - TmpCount;
  // ������ ���������� ����������
  APlanet.CaptureValue := APlanet.CaptureValue - TmpSpeed;
  // ������ ������ ��� �������
  if (APlanet.CaptureValue < 1) then
    APlanet.CapturePlayer := nil;
end;

function TPLPlanetsControlCapture.DoCaptureBySelf(APlanet: TPlPlanet; AShip: TPlShip): Boolean;
var
  TmpSpeed: Single;
  TmpCount: Integer;
begin
  Result := True;
  // �� ������������ ���� ���������� ������
  if (APlanet.Owner = AShip.Owner)
    and (APlanet.CaptureValue = 0)
  then
    Exit(False);
  // ������� ��������� �������
  DoCaptureParam(APlanet, AShip, TmpSpeed, TmpCount);
  // ����������� ���� ����������
  AShip.Count := AShip.Count - TmpCount;
  APlanet.CapturePlayer := AShip.Owner;
  APlanet.CaptureValue := APlanet.CaptureValue + TmpSpeed;
  // �������� �������
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
  // ��������� ������ 5 ������ � 10 ������ �� �������
  if (APlanet.Owner = nil) then
  begin
    TmpSpeed := C_NEUTRAL_SPEED;
    TmpCount := 2;
  end else
  begin
    TmpSpeed := C_CAPTURE_VICTIM / (C_LEVEL_COEFF * APlanet.Level);
    TmpCount := 2;
  end;
  // �������� �������� �� ����������� ����� ���� ����� �� ������ ��� �����-�� ���������
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
  // 1 ���� = C_CAPTURE_MAX, 2 ���� = 25, 3 ���� = 12.5, 4 ���� = 6, 5 ���� = 3 : +46%
  if (not TmpFound) then
  begin
    FCaptureData[FCaptureDataCount].Player := AShip.Owner;
    FCaptureData[FCaptureDataCount].Coeff := C_CAPTURE_MAX;
    Inc(FCaptureDataCount);
  end;
  if (TmpCoeff < C_CAPTURE_MAX) then
    TmpSpeed := TmpSpeed / C_CAPTURE_MAX * TmpCoeff;
  // �������� �� ������ ���� ���������� ������ �������� ������� - ����������� ������������� ���������
  if (C_CAPTURE_MAX - APlanet.CaptureValue < TmpSpeed) then
  begin
    TmpCount := TmpCount * (APlanet.CaptureValue / TmpSpeed);
    TmpSpeed := 0;
    APlanet.CaptureValue := C_CAPTURE_MAX;
  end;
  // �������� ���������� ����������, ������ ��� �������
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
  // ������� �� ��������� ��� ��������� ������ ����
  if (AShip.Count > 0) then
    TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(AShip)
  else
    TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(AShip, True, True, False);
end;

procedure TPLPlanetsControlCapture.DoCapturePlanet(APlanet: TPlPlanet; AShip: TPlShip);
var
  TmpShip: TPlShip;
begin
  // ������ ������ ����������
  for TmpShip in APlanet.Ships do
  begin
    if (TmpShip.Owner = AShip.Owner) then
      Continue;
    TPlanetarThread(Engine).ControlPlanets.UpdateShipList(TmpShip, -TmpShip.Count);
    if (TmpShip.IsCapture) then
      TPlanetarThread(Engine).ControlShips.Attach.Execute(AShip, nil, False);
  end;
  // ������ �������� ����������
  TPlanetarThread(Engine).ControlPlanets.PlayerControlChange(APlanet, APlanet.Owner, False, False);
  // ������� ���������
  APlanet.Owner := AShip.Owner;
  APlanet.CaptureValue := 0;
  APlanet.Name := AShip.Owner.Name;
  // ������� ���� ������
  for TmpShip in APlanet.Ships do
  begin
    if (TmpShip.Owner <> AShip.Owner) then
      Continue;
    TPlanetarThread(Engine).ControlPlanets.UpdateShipList(TmpShip, TmpShip.Count);
    if (TmpShip.IsCapture) then
      TPlanetarThread(Engine).ControlShips.Attach.Execute(TmpShip, nil, False);
  end;
  // �������� ��������� � ���������
  TPlanetarThread(Engine).SocketWriter.PlanetOwnerChanged(APlanet);
  // ������� ���� ��������
  TPlanetarThread(Engine).ControlPlanets.PlayerControlChange(APlanet, APlanet.Owner, True, False);
end;

procedure TPLPlanetsControlCapture.Execute(APlanet: TPlPlanet);
begin
  TPlanetarThread(Engine).WorkerPlanets.TimerAdd(APlanet, ppltmCapture, 1, OnTimer);
end;

end.
