{**********************************************}
{                                              }
{ ���� : ������� �� ��������� ���������        }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.MoveToPlanet;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ���������
  TPLShipsControlMoveToPlanet = class(TPLShipsControlCustom)
  private
    // �������� �� ����������� ����� � �������
    function GetDepartureAvailable(AShip: TPlShip; ADestination: TPlPlanet): Boolean;
  public
    // ������� ����������
    function Execute(AShip: TPlShip; ADestination: TPlPlanet; ASlot: Integer = 0; ACheck: Boolean = True;
      AAttach: Boolean = False): Boolean;
    // ���������� ������� ������
    procedure Player(AShip: TPlShip; ADestination: TPlPlanet; ASlot: TPlLanding; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlMoveToPlanet.GetDepartureAvailable(AShip: TPlShip;
  ADestination: TPlPlanet): Boolean;
var
  TmpShip: TPlShip;
begin
  Result := False;
  try
    // �������� ���������� ����������
    if (ADestination.State <> plsActive) then
      Exit();
    // �������� ������� �������
    if (AShip.Planet <> ADestination)
      and (AShip.Fuel = 0) then
    begin
      TLogAccess.Write(ClassName, 'NoFuel');
      Exit();
    end;
    // ������ ����� �������� ������ �� ��������
    if (not AShip.Planet.IsManned)
      or (not AShip.Planet.Timer[ppltmBattle])
    then
      Exit(True);
    // ���� �� ������� �������� ��������� - �� ������� �����
    if (AShip.Planet.IsLowGravity) then
      Exit(True);
    // ����� ���� �� ������ � �� ���� - ������� ������
    if (not AShip.TechActive(plttFaster)) then
    begin
      TLogAccess.Write(ClassName, 'NoFaster');
      Exit();
    end;
    // ����� ���������� ������� ����, ������� ��������� ����� �����
    for TmpShip in AShip.Planet.Ships do
    begin
      if (TmpShip.TechActive(plttSpeedBlocker))
        and (TmpShip.IsStateActive)
        and (TmpShip.Owner.IsRoleEnemy(AShip.Owner)) then
      begin
        TLogAccess.Write(ClassName, 'SpeedBlocker');
        Exit();
      end;
    end;
    // ���� ���������� ��� - ���� �������
    Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlMoveToPlanet.Execute(AShip: TPlShip; ADestination: TPlPlanet; ASlot: Integer;
  ACheck, AAttach: Boolean): Boolean;
begin
  Result := False;
  try
    // ������ ���� ���� �����
    if (ASlot = 0) then
      ASlot := GetFreeSlot(AShip.TechActive(plttIntoBackzone), ADestination, AShip.TechActive(plttLowOrbit), AShip.Owner);
    // ���� ���������� ����� ��� - ������ ������
    if (ASlot = 0) then
    begin
      TLogAccess.Write(ClassName, 'Slot');
      Exit();
    end;
    // ���� ���� ���� ������� ��� ����� - �� �� ����������� ������ ���
    if (ACheck) then
    begin
      // �������� �� �����
      if (AShip.Planet <> ADestination)
        and (not GetDepartureAvailable(AShip, ADestination)) then
      begin
        TLogAccess.Write(ClassName, 'Departure');
        Exit();
      end;
      // �������� �� ������
      if (not CheckMoveTo(AShip, ADestination, ASlot, True)) then
      begin
        TLogAccess.Write(ClassName, 'Arrival');
        Exit();
      end;
    end;
    // ������� � ������� �������
    TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(
      AShip, False, False, AShip.Planet <> ADestination);
    // ��������� ������� ��������
    if (AShip.Planet = ADestination) then
      TPlanetarThread(Engine).ControlShips.Fly.Execute(AShip, pshstMovingLocal)
    else
      TPlanetarThread(Engine).ControlShips.Fly.Execute(AShip, pshstMovingGlobal);
    // ��������� ���� ��������
    AShip.IsAutoAttach := AAttach;
    AShip.IsTargeted := False;
    AShip.Planet := ADestination;
    AShip.Landing := ASlot;
    // �������� �� ������� ����������
    TPlanetarThread(Engine).ControlShips.AddToPlanet.Execute(
      AShip, ADestination, AShip.Planet <> ADestination, False, True);
    // �������� ���������
    TPlanetarThread(Engine).SocketWriter.ShipMoveTo(AShip, ADestination, ASlot);
    // ����������� �������
    Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlMoveToPlanet.Player(AShip: TPlShip; ADestination: TPlPlanet;
  ASlot: TPlLanding; APlayer: TGlPlayer);
begin
  try
    // �������� �� ������������ �����
    if (not TPlLanding.Valid(ASlot)) then
    begin
      TLogAccess.Write(ClassName, 'Slot');
      Exit();
    end;
    // ������ ��������� ����������� �����������
    if (not AShip.CanOperable(True)) then
    begin
      TLogAccess.Write(ClassName, 'Operable');
      Exit();
    end;
    // ������ ���������� �� ���������� �������
    if (ADestination.State <> plsActive) then
    begin
      TLogAccess.Write(ClassName, 'Inactive');
      Exit();
    end;
    // �������� �� ��������� ����
    if (not ADestination.Landings.IsEmpty(ASlot)) then
    begin
      TLogAccess.Write(ClassName, 'Aquired');
      Exit();
    end;
    // ������� ������ ������
    if (ASlot.IsLowOrbit) then
    begin
      // ������ ���� ���� ���
      if (ADestination.Timer[ppltmBattle]) then
      begin
        TLogAccess.Write(ClassName, 'LowInBattle');
        Exit();
      end;
      // ������ ���� �� ����� ��� ����
      if (not AShip.TechActive(plttLowOrbit)) then
      begin
        TLogAccess.Write(ClassName, 'LowWrongType');
        Exit();
      end;
    end;
    // ������ ��������� ������ �����������
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // ��������  �� ������� �� ������ �������
    if (AShip.Planet <> ADestination) then
    begin
      // ������ ���������� �� ������� ��� ������� ��������
      if (not AShip.Planet.Links.Contains(ADestination)) then
      begin
        TLogAccess.Write(ClassName, 'Links');
        Exit();
      end;
      // ������������ �� ������ �� ������ �������
      if (AShip.TechActive(plttStationary)) then
      begin
        TLogAccess.Write(ClassName, 'Stationary');
        Exit();
      end;
    end;
    // ������� ��������� ��������
    if (not Execute(AShip, ADestination, ASlot)) then
    begin
      TLogAccess.Write(ClassName, 'CantMove');
      Exit();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
