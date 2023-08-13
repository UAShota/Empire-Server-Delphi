{**********************************************}
{                                              }
{ ���� : ����������� �����                     }
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
  // ����� ��������� ����������� �����
  TPLShipsControlAnnihilation = class(TPLShipsControlCustom)
  private const
    // ����� �����������
    CI_TIME_ANNIHILATION = 10;
  private
    // ��������� ����� �����
    procedure DoDamage(AShip: TPlShip; ADamageBase, ADamageExt: Integer);
    // ����� �����
    procedure DoAnnihilate(AShip: TPlShip);
    // ������������ ������� ��������
    function OnTimer(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean;
  public
    // ���������� ������� ������
    procedure Player(AShip: TPlShip; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlAnnihilation.DoDamage(AShip: TPlShip; ADamageBase, ADamageExt: Integer);
begin
  try
    // ��� ������ ������������ �������������� ����
    if (AShip.TechActive(plttStationary)) then
      ADamageBase := ADamageExt;
    // ������� ����
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
    // ������� ���� ���� �������� �� ������
    for TmpShip in AShip.Planet.Ships do
      DoDamage(TmpShip, TmpBase, TmpDmgExt);
    WorkShipHP(AShip.Planet);
    // ������� ���� ���� �������� ��� ������ ��� ���
    if (AShip.Planet.IsBigHole) then
    begin
      for TmpPlanet in AShip.Planet.Links do
      begin
        // ������� ���� ���� �������� �� ������
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
    // ������ �� ��������
    if (ACounter > 0) then
    begin
      Dec(ACounter);
      Exit();
    end else
      Result := True;
    // �������� ������
    DoAnnihilate(AShip);
    // ������� ����������
    TPlanetarThread(Engine).SocketWriter.PlanetLowGravityUpdate(AShip.Planet, True);
    // ���������� �����
    TmpTime := 60;
    // ��� ��������� ������� ����������� ������ ������� �� �������
    if (AShip.Planet.IsLowGravity) then
      TmpTime := Round(TmpTime * 0.5)
    else
      AShip.Planet.IsLowGravity := True;
    // ������� ����� ��������
    if (AShip.Planet.PlanetType = pltPulsar) then
    begin
      { TODO -omdv : ��������� ����� ������� ����� }
      Inc(AShip.Planet.StateTime, TmpTime);
    end else
    // ������� ����� �����������
    if (AShip.Planet.PlanetType = pltHole) then
    begin
      { TODO -omdv : ��������� ����� ������� ����� }
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
    // ������ �������� �� ����
    if (not AShip.TechActive(plttAnnihilation)) then
    begin
      TLogAccess.Write(ClassName, 'NoTech');
      Exit();
    end;
    // ������ �������� ��������
    if (AShip.Timer[pshtmOpAnnihilation]) then
    begin
      TLogAccess.Write(ClassName, 'Timer');
      Exit();
    end;
    // ������ ��������� �������������
    if (not AShip.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'Operable');
      Exit();
    end;
    // ������ �������� ���� ������������ ��������
    if (AShip.Count < AShip.TechValue(plttCount) div 2) then
    begin
      TLogAccess.Write(ClassName, 'Count');
      Exit();
    end;
    // ������ ��������� ������
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // ������ � ������ � �������� �������
    TPlanetarThread(Engine).ControlShips.StandDown.Execute(AShip, AShip.Mode, False);
    TPlanetarThread(Engine).WorkerShips.TimerAdd(AShip, pshtmOpAnnihilation, CI_TIME_ANNIHILATION, OnTimer);
    // ��������� ���������
    AShip.State := pshstAnnihilation;
    TPlanetarThread(Engine).SocketWriter.ShipUpdateState(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
