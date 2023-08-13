{**********************************************}
{                                              }
{ ���������� : ��������� ������ ����           }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{                                              }
{**********************************************}
unit SR.PL.Planets.Wormhole;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Planets.Custom;

type
  // ����� ��������� ������� ����
  TPLPlanetsControlWormhole = class(TPLPlanetsControlCustom)
  private var
    FBigHolesCount: Integer;
    FSmallHolesCount: Integer;
    FWormholesActive: TPlPlanetList;
    FWormholesInactive: TPlPlanetList;
  private
    // ������������ ������� ��������
    function OnTimer(APlanet: TPlPlanet; var ACounter: Integer; var AValue: Integer): Boolean;
    // ��������� �������� ������� ��
    procedure DoSetHoleEdge(APlanet: TPlPlanet; AEdge: Boolean);
    // ����� ��������� ��
    procedure DoChangeState(APlanet: TPlPlanet);
    // ��������� ���� ��
    procedure DoActivate(ABigHole: Boolean; var APortal: TPlPlanet);
  public
    constructor Create(AEngine: TObject); override;
    destructor Destroy(); override;
    // ������� ����������
    procedure Execute(APlanet: TPlPlanet);
    // ������� �������� �� � ���������
    procedure Reactivate();
  end;

implementation

uses
  SR.Planetar.Thread;

constructor TPLPlanetsControlWormhole.Create(AEngine: TObject);
begin
  inherited Create(AEngine);

  FWormholesActive := TPlPlanetList.Create();
  FWormholesInactive := TPlPlanetList.Create();
end;

destructor TPLPlanetsControlWormhole.Destroy();
begin
  FreeAndNil(FWormholesInactive);
  FreeAndNil(FWormholesActive);

  inherited Destroy();
end;

function TPLPlanetsControlWormhole.OnTimer(APlanet: TPlPlanet; var ACounter, AValue: Integer): Boolean;
begin
  Result := False;
  try
    // ������ �� ����������
    if (ACounter > 0) then
    begin
      Dec(ACounter);
      Exit();
    end;
    // ������ ��������� ����� ��������
    DoChangeState(APlanet.Portal.Enter);
    DoChangeState(APlanet.Portal.Exit);
    // ������� ����� ��� ������������ ��
    if (APlanet.State = plsActivation) then
    begin
      ACounter := APlanet.StateTime;
      AValue := ACounter;
      Exit();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLPlanetsControlWormhole.DoChangeState(APlanet: TPlPlanet);
begin
  // �������� �������� �� ��� ������� ��������������
  if (APlanet.State = plsActive) then
  begin
    // ��� ��� ������ ��������� �� ��� � �������� ��������
    if (APlanet.IsBigHole) then
    begin
      DoSetHoleEdge(APlanet, False);
      APlanet.IsBigHole := False;
      Dec(FBigHolesCount);
    end else
      Dec(FSmallHolesCount);
    FWormholesInactive.Add(APlanet);
    // ��������� ������
    APlanet.State := plsInactive;
    // ������� ������
    TPlanetarThread(Engine).ControlPlanets.ClosePortal(APlanet);
    // ��������� ������� � ������
    TPlanetarThread(Engine).ControlShips.Escape.Execute(APlanet);
  end else
  begin
    APlanet.State := plsActive;
    APlanet.StateTime := TPlanetarThread(Engine).TimeWormholeActive;
  end;
  // �������� ��������� � ����� ���������
  TPlanetarThread(Engine).SocketWriter.PlanetStateUpdate(APlanet);
end;

procedure TPLPlanetsControlWormhole.DoSetHoleEdge(APlanet: TPlPlanet; AEdge: Boolean);
var
  TmpPlanet: TPlPlanet;
begin
  for TmpPlanet in APlanet.Links do
  begin
    if (TmpPlanet.PlanetType <> pltHole) then
      TmpPlanet.IsBigEdge := AEdge;
  end;
end;

procedure TPLPlanetsControlWormhole.DoActivate(ABigHole: Boolean; var APortal: TPlPlanet);
var
  TmpI: Integer;
  TmpPlanet: TPlPlanet;
begin
  TmpI := Random(Pred(FWormholesInactive.Count));
  TmpPlanet := FWormholesInactive[TmpI];
  FWormholesInactive.Delete(TmpI);
  // �������� ���
  TmpPlanet.IsBigHole := True;
  TmpPlanet.State := plsActivation;
  TmpPlanet.StateTime := TPlanetarThread(Engine).TimeWormholeOpen;
  TPlanetarThread(Engine).WorkerPlanets.TimerAdd(TmpPlanet, ppltmWormhole, TmpPlanet.StateTime, OnTimer);
  // ��������� ������
  if (Assigned(APortal)) then
  begin
    TPlanetarThread(Engine).ControlPlanets.OpenPortal(TmpPlanet, APortal, False, True);
    APortal := nil;
  end else
    APortal := TmpPlanet;
  // ������� �� � ���������
  if (ABigHole) then
  begin
    Inc(FBigHolesCount);
    DoSetHoleEdge(TmpPlanet, True);
  end else
    Inc(FSmallHolesCount);
  // �������� ��������� � ����� ���������
  TPlanetarThread(Engine).SocketWriter.PlanetStateUpdate(TmpPlanet);
end;

procedure TPLPlanetsControlWormhole.Reactivate();
var
  TmpPortalPlanet: TPlPlanet;
begin
  // �������� ��� ����� �������� �����-���� ���
  TmpPortalPlanet := nil;
  while (FBigHolesCount < 2) do
    DoActivate(True, TmpPortalPlanet);
  // �������� ��� ����� �������� ��, �� ���� �� ������ 50 ������
  TmpPortalPlanet := nil;
  while (FSmallHolesCount - 2 < Trunc(TPlanetarThread(Engine).MannedCount / 50) * 2) do
    DoActivate(False, TmpPortalPlanet);
end;

procedure TPLPlanetsControlWormhole.Execute(APlanet: TPlPlanet);
begin
  FWormholesActive.Add(APlanet);
  FWormholesInactive.Add(APlanet);
end;

end.
