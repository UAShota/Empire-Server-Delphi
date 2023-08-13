{**********************************************}
{                                              }
{ ���� : �������� � �����                      }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.MoveToHangar;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Hangar,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� �������� � �����
  TPLShipsControlMoveToHangar = class(TPLShipsControlCustom)
  public
    // ������� ����������
    function Execute(AHangarSlot: Integer; AShip: TPlShip): Boolean;
    // ���������� ������� ������
    procedure Player(AHangarSlot: Integer; AShip: TPlShip; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Profile,
  SR.Planetar.Thread;

function TPLShipsControlMoveToHangar.Execute(AHangarSlot: Integer; AShip: TPlShip): Boolean;
var
  TmpHangar: TPlHangar;
  TmpHangarSlot: TPlHangarSlot;
begin
  Result := False;
  try
    TmpHangar := TPlanetarProfile(AShip.Owner.PlanetarProfile).Hangar;
    // �������� �������
    if (AShip.Fuel < I_FUEL_FOR_HANGAR) then
    begin
      TLogAccess.Write(ClassName, 'NoFuel');
      Exit()
    end;
    // ���� �� ������ ��� �� ��������
    if (AHangarSlot < 0)
      or (AHangarSlot > TmpHangar.Size) then
    begin
      TLogAccess.Write(ClassName, 'Invalid');
      Exit();
    end;
    // ����� � ����
    TmpHangarSlot := TmpHangar.Slots[AHangarSlot];
    // � ������ � ���� ����� ������� �����-�� ����
    if (TmpHangarSlot.ShipType = AShip.ShipType) then
      Result := TmpHangar.Change(AHangarSlot, AShip.Count, AShip.Owner)
    else
    // � ������ � ���� ����� �����
    if (TmpHangarSlot.ShipType = pshtpEmpty) then
      Result := TmpHangar.Add(AHangarSlot, AShip.Count, AShip.ShipType, AShip.Owner)
    else
    // ���� �����
    begin
      TLogAccess.Write(ClassName, 'Type');
      Exit();
    end;
    // �������� �� ����������
    if (not Result) then
      TLogAccess.Write(ClassName, 'Full')
    else
      TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(AShip, True, False, False);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlMoveToHangar.Player(AHangarSlot: Integer; AShip: TPlShip;
  APlayer: TGlPlayer);
begin
  try
    // ������ ��������� ����� ��������
    if (AShip.Owner <> APlayer) then
    begin
      TLogAccess.Write(ClassName, 'Owner');
      Exit();
    end;
    // ������ ���������� � ����� ������������ ����
    if (AShip.TechActive(plttStationary)) then
    begin
      TLogAccess.Write(ClassName, 'Stationary');
      Exit();
    end;
    // ������ ���������� � ����� �� �����
    if (AShip.Planet.Timer[ppltmBattle]) then
    begin
      TLogAccess.Write(ClassName, 'Battle');
      Exit();
    end;
    // ������ ���������� ���� �� � �������
    if (not AShip.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'Battle');
      Exit();
    end;
    // ������� ����������
    Execute(AHangarSlot, AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
