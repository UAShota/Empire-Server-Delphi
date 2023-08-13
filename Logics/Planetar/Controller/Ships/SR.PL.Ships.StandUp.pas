{**********************************************}
{                                              }
{ ���� : ���� ���������� ����� �� ���������    }
{        � ������� ��������� � ������ �����    }
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
  // ����� ��������� ���������� ����� � ���� ���������� ��� ������
  TPLShipsControlStandUp = class(TPLShipsControlCustom)
  private
    // �������� �� ������������� ������������� ��������
    procedure DoCheckBlock(AShip: TPlShip);
    // �������� �� ������������� �������������������
    function DoCheckBlocked(AShip: TPlShip): Boolean;
  public
    // ������� ����������
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
    // ���� �� ��������� �������� ��� ������������ ������ � ��� ��� ������
    TmpTargetShip := CheckShipBlocker(AShip, AShip.Landing.Prev(), True, pshmdActive);
    if (Assigned(TmpTargetShip)) then
    begin
      TmpBlockerShip := CheckShipBlocker(AShip, AShip.Landing.Prev().Prev(), False, pshmdActive);
      if (TmpBlockerShip <> nil) then
        TPlanetarThread(Engine).ControlShips.StandDown.Execute(TmpTargetShip, pshmdBlocked);
    end;
    // ���� �� �������� ��� ������������ �����
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
    // ���� �� �������� ��� ������������ ������
    TmpTargetShip := CheckShipBlocker(AShip, AShip.Landing.Prev(), True, pshmdActive);
    if not Assigned(TmpTargetShip) then
      Exit(True);
    // ���� �� �������� ��� ������������ �����
    TmpTargetShip := CheckShipBlocker(AShip, AShip.Landing.Next(), True, pshmdActive);
    if not Assigned(TmpTargetShip) then
      Exit(True);
    // ���� ���� ��� ���������� - �����������
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
    // ���� ����������� ���� �� ������ ���� - ���������� � ����� �� �����
    if (AShip.Landing.IsLowOrbit) then
    begin
      // ���� �������� ��� ���������� - ������ ���������
      if (AChangeMode) then
        AShip.Mode := pshmdActive;
    end else
    begin
      // �� ��������� �������� ���� � �� �������
      TmpFlagFound := False;
      // ������ ������� �������� �� ��� ������ ��� ��������
      for TmpIndex in AShip.Planet.ShipCount do
      begin
        // ��������� ������ � ������ ������� �����
        if (not AShip.Owner.IsRoleFriend(TmpIndex.Key)) then
          Continue
        else
          TmpCount := TmpIndex.Value;
        // ���������, ���� �� ������ ���� �����
        if (not TmpFlagFound) then
          TmpFlagFound := (TmpIndex.Key = AShip.Owner);
        // �������� ������ ��� ����� �������� ���� ���������� ���� �� ��� ��������
        if (AChangeMode) then
        begin
          if (TmpCount.Active = I_MAX_SHIP_ACTIVE) then
            AShip.Mode := pshmdFull
          else
            AShip.Mode := pshmdActive;
        end;
        // ��������� ����� ���������� ���������� � ���������� ��������
        Inc(TmpCount.Exist, Ord(AChangeCount));
        Inc(TmpCount.Active, Ord(AShip.IsStateActive));
        // ������� �����
        AShip.Planet.ShipCount[TmpIndex.Key] := TmpCount;
      end;
      // ���� ��� ������ �������� - ������ ������
      if (not TmpFlagFound) then
      begin
        TmpCount.Exist := 1;
        TmpCount.Active := Ord(AShip.IsStateActive);
        // ������� �����
        AShip.Planet.ShipCount.Add(AShip.Owner, TmpCount);
      end;
      // ��� �������� �������� ������ �������� � �������� ������
      if (AShip.IsStateActive) then
      begin
        // ��������, ����������� �� �������, ���������� �������
        TPlanetarThread(Engine).ControlShips.Capture.Execute(AShip, True);
        // ��� �������� �������� � ������ ��� �� �����
        if (ARetarget) then
        begin
          // ��������, ����� ��������� ������������ ���� �������� � �������� ��������
          DoCheckBlock(AShip);
          // �������� ��� ����� ���������, ���� ����������� ���� - ���� ���������
          DoCheckBlocked(AShip);
          // ������������ �������
          TPlanetarThread(Engine).ControlPlanets.Retarget(AShip, True);
        end;
      end;
    end;
    // ��� ������� �������� ��������, �������� �������
    if (AChangeState or AChangeMode) then
      TPlanetarThread(Engine).SocketWriter.ShipUpdateState(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
