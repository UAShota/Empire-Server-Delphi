{**********************************************}
{                                              }
{ ���� : ���������� ������                     }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Separate;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ���������� ������
  TPLShipsControlSeparate = class(TPLShipsControlCustom)
  public
    // ������� ����������
    procedure Execute(AShip: TPlShip; ASlot, ACount: Integer);
    // ���������� ������� ������
    procedure Player(AShip: TPlShip; ASlot, ACount: Integer; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlSeparate.Execute(AShip: TPlShip; ASlot, ACount: Integer);
var
  TmpShip: TPlShip;
begin
  try
    // �������� �� ����������� �����
    if (not CheckMoveTo(AShip, AShip.Planet, ASlot, False)) then
    begin
      TLogAccess.Write(ClassName, 'Check');
      Exit();
    end;
    // ���� ���������� �� ������� ��� ��������� - ��������� ��������
    if (ACount <= 0) or (ACount >= AShip.Count) then
      ACount := AShip.Count div 2;
    // ������� � ������� �����
    Dec(AShip.Count, ACount);
    // ������� � ����������� ����� ����
    TmpShip := CreateShip(AShip.Planet, AShip.ShipType, ASlot, ACount, AShip.Owner);
    // ��������� �������
    TmpShip.Fuel := AShip.Fuel;
    // ��������� ���������
    TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(AShip);
    TPlanetarThread(Engine).SocketWriter.ShipCreate(TmpShip);
    // ��� ������� � ���� �������� ��� ���������� �������� �����
    if (AShip.Planet.Timer[ppltmBattle]) then
      TPlanetarThread(Engine).ControlShips.Fly.Execute(TmpShip, pshstParking);
    // �������� � ����� ���� ��������
    TPlanetarThread(Engine).ControlShips.AddToPlanet.Execute(
      TmpShip, TmpShip.Planet, False, not AShip.Planet.Timer[ppltmBattle], AShip.Planet.Timer[ppltmBattle]);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlSeparate.Player(AShip: TPlShip; ASlot, ACount: Integer; APlayer: TGlPlayer);
begin
  try
    // ������ ������ ���� ��������
    if (not TPlLanding.Valid(ASlot)) then
    begin
      TLogAccess.Write(ClassName, 'Slot');
      Exit();
    end;
    // ������ ������ ���� ��������
    if (AShip.Count = 1) then
    begin
      TLogAccess.Write(ClassName, 'Count');
      Exit();
    end;
    // �������� ������ ���� ��������
    if (not AShip.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'Operable');
      Exit();
    end;
    // �������� �� ���
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // �������� �������
    Execute(AShip, ASlot, ACount);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
