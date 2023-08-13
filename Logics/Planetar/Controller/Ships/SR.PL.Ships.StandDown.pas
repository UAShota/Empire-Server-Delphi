{**********************************************}
{                                              }
{ ���� : ���� �������� ����� � ���������� �    }
{        ������� ��������� � ��������� �����   }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.StandDown;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� �������� ����� �� ����� ���������� ��� ������
  TPLShipsControlStandDown = class(TPLShipsControlCustom)
  private
    // ������������ ��������� ����� �� ���������� ��� �����
    procedure DoStandUpBlocked(AShip: TPlShip);
    // ������������ ���� ���� �� ������������ ��� �����
    procedure DoStandUpShips(AShip: TPlShip);
  public
    // ������� ����������
    procedure Execute(AShip: TPlShip; AMode: TPlShipMode; AChangeCount: Boolean = False);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlStandDown.DoStandUpShips(AShip: TPlShip);
var
  TmpShip: TPlShip;
begin
  try
    // ������� ��������, ������� ��� � ����������
    for TmpShip in AShip.Planet.Ships do
      if (TmpShip.Mode = pshmdFull)
        and (AShip.Owner.IsRoleFriend(TmpShip.Owner)) then
    begin
      TPlanetarThread(Engine).ControlShips.StandUp.Execute(TmpShip);
      Break;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlStandDown.DoStandUpBlocked(AShip: TPlShip);
var
  TmpShip: TPlShip;
begin
  try
    // ������� �������� ������
    TmpShip := CheckShipBlocker(AShip, AShip.Landing.Prev(), True, pshmdBlocked);
    if (TmpShip <> nil)
      and (TmpShip.Mode = pshmdBlocked)
    then
      TPlanetarThread(Engine).ControlShips.StandUp.Execute(TmpShip);
    // ������� �������� �����
    TmpShip := CheckShipBlocker(AShip, AShip.Landing.Next(), True, pshmdBlocked);
    if (TmpShip <> nil)
      and (TmpShip.Mode = pshmdBlocked)
    then
      TPlanetarThread(Engine).ControlShips.StandUp.Execute(TmpShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlStandDown.Execute(AShip: TPlShip; AMode: TPlShipMode;
  AChangeCount: Boolean = False);
var
  TmpIndex: TPlShipsCountPair;
  TmpCount: TPlShipsCount;
  TmpFlagFound: Boolean;
begin
  try
    // ������ ����� �� ����������� ��� �������� �������
    if (AShip.Landing.IsLowOrbit) then
      Exit();
    // � ��� ������ ������ �������� ������
    TmpFlagFound := False;
    TmpCount.Value := 0;
    // ��������� ��� ����� �������
    for TmpIndex in AShip.Planet.ShipCount do
    begin
      if (not TmpFlagFound) then
        TmpFlagFound := (TmpIndex.Key = AShip.Owner);
      // ������ ������� ����� ��� ���������� ���������� ������ �� �������
      if (not AShip.Owner.IsRoleFriend(TmpIndex.Key)) then
        Continue;
      // ������� ���������� ������
      TmpCount := TmpIndex.Value;
      // ������ ������ ���� ��� ��������� �������� ������
      if (AChangeCount and (TmpCount.Exist = 1)) then
      begin
        AShip.Planet.ShipCount.Remove(TmpIndex.Key);
        Continue;
      end;
      // ���� �������� ���� � ������ - �� ��� ��������� � �� ����������� ��� ��������
      Dec(TmpCount.Exist, Ord(AChangeCount));
      Dec(TmpCount.Active, Ord(AShip.IsStateActive));
      // �������� ������� ���������� ��������� ������
      AShip.Planet.ShipCount[TmpIndex.Key] := TmpCount;
    end;
    // �� ������ ������ ��� ������������ ����������
    if (not AChangeCount and (AShip.Mode <> AMode)) then
    begin
      AShip.Mode := AMode;
      // ������� ��������� ���������
      TPlanetarThread(Engine).SocketWriter.ShipUpdateState(AShip);
    end;
    // ����������� �� ���������� ���� ���� (6 ����� ��������� ����� �����������)
    if (TmpCount.Active = I_MAX_SHIP_REFILL) then
      DoStandUpShips(AShip);
    // ������������ ������� ���������
    DoStandUpBlocked(AShip);
    // ������ ������, ���� ����
    TPlanetarThread(Engine).ControlShips.Capture.Execute(AShip, False);
    // ������������ ���������
    TPlanetarThread(Engine).ControlPlanets.Retarget(AShip, AShip.IsTargeted);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.

