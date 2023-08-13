{**********************************************}
{                                              }
{ ���� : �������� ����� � ����������           }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.RemoveFromPlanet;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� �������� ����� � ����������
  TPLShipsControlRemoveFromPlanet = class(TPLShipsControlCustom)
  private
    // ������� ����� ����������
    procedure DoReplaceDeleted(AShip: TPlShip);
  public
    // ������� ����������
    procedure Execute(AShip: TPlShip; APhisycal, AExplosive, ARecalc: Boolean);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlRemoveFromPlanet.DoReplaceDeleted(AShip: TPlShip);
var
  TmpShip: TPlShip;
begin
  try
    // ������ �������� �����������, ���� � ������ ����
    if (AShip.Landing.IsLowOrbit)
      or (AShip.TechActive(plttStationary))
      or (AShip.TechActive(plttWeaponRocket))
    then
      Exit();
    // ��������� ��� ����������� �������
    for TmpShip in AShip.Planet.RangeAttackers do
    begin
      if (TmpShip.ShipType = AShip.ShipType)
        and TPlanetarThread(Engine).ControlShips.MoveToPlanet.Execute(TmpShip, AShip.Planet, AShip.Landing, True, True) then
      begin
        if (AShip.Mode = pshmdOffline) then
          TmpShip.Mode := AShip.Mode;
        Break;
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlRemoveFromPlanet.Execute(AShip: TPlShip; APhisycal, AExplosive, ARecalc: Boolean);
begin
  try
    // ������ �� ������ �������
    AShip.Planet.Landings.Remove(AShip);
    // ���� ����� ��������
    if (ARecalc) then
    begin
      // ������ ��������
      if (Assigned(AShip.Attached)) then
        TPlanetarThread(Engine).ControlShips.Attach.Execute(AShip, nil, True);
      // ������� ��������� �������
      TPlanetarThread(Engine).ControlPlanets.UpdateShipList(AShip, -AShip.Count);
    end;
    // ��������� ������ ��������
    TPlanetarThread(Engine).ControlShips.StandDown.Execute(AShip, AShip.Mode, True);
    // �������� ��������� ��������� ��������
    TPlanetarThread(Engine).ControlPlanets.PlayerControlChange(
      AShip.Planet, AShip.Owner, False, AShip.Landing.IsLowOrbit);
    // �������� � ����� ��������
    if (APhisycal) then
    begin
      // ������ ��� �������
      TPlanetarThread(Engine).WorkerShips.TimerRemove(AShip);
      // ������ �� ������
      if (Assigned(AShip.Group)) then
        AShip.Group.Remove(AShip);
      // �������� ���������
      TPlanetarThread(Engine).SocketWriter.ShipDelete(AShip, AExplosive);
      // ������ �������� �� �������
      TPlanetarThread(Engine).ControlShips.ListShips[AShip.ID] := nil;
      // ������� ��������, ���� �����
      DoReplaceDeleted(AShip);
      // ���������� ��� ������ �� ������ �����
      FreeAndNil(AShip);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
