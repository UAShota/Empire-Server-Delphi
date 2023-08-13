{**********************************************}
{                                              }
{ ���� : ����� ���� �� ������ ������� ��       }
{        ������� ��������� �������� �����      }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.TargetMarker;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ������ ��������� ���� �� �������� �������
  TPLShipsControlTargetMarker = class(TPLShipsControlCustom)
  public
    // �������������� ����� ���� �� �������� ��������
    procedure Auto(AShip: TPlShip);
    // ����� ������������ ����
    procedure Highlight(AShip: TPlShip; APlanet: TPlPlanet; AAutoTarget: Boolean);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlTargetMarker.Auto(AShip: TPlShip);
var
  TmpPlanet: TPlPlanet;
begin
  try
    // ���������� ��� ������� ����
    if (not AShip.CanRangeAutoTarget) then
      Exit();
    // ���������� ������� ��� ���
    for TmpPlanet in AShip.Planet.Links do
    begin
      if (not TmpPlanet.Timer[ppltmBattle]) then
        Continue;
      Highlight(AShip, TmpPlanet, True);
      // ���� ���� ������� - �� ��������� � ���������� ���������
      if (AShip.IsTargeted) then
        Break;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetMarker.Highlight(AShip: TPlShip; APlanet: TPlPlanet; AAutoTarget: Boolean);
var
  TmpShip: TPlShip;
  TmpTargetRocket: TPlShip;
begin
  try
    TmpTargetRocket := nil;
    // �������� ��� ���������� �������� �������� ��������
    if (AShip.IsStateActive) then
    begin
      // ����� ������� ����������, �������� ��������� ��� ��������
      for TmpShip in APlanet.Ships do
      begin
        // ���������� �� ���� �������, ����������� ������� ��� ���� ���������� �� ������ �������
        if (not TmpShip.IsStateActive)
          or (TmpShip.IsAttachedRange(True))
          or (TmpShip.Owner.IsRoleEnemy(AShip.Owner))
        then
          Continue;
        // ������ �������� �� �������� �� ������ �������
        if (Assigned(TmpShip.Targets[pswCenter])
          and (not TmpShip.Targets[pswCenter].TechActive(plttRangeDefence)))
        then
          TmpTargetRocket := TmpShip.Targets[pswCenter]
        else
        // ���� ����� ����
        if (Assigned(TmpShip.Targets[pswLeft]))
          and (not TmpShip.Targets[pswLeft].TechActive(plttRangeDefence))
        then
          TmpTargetRocket := TmpShip.Targets[pswLeft]
        else
        // ���� ������ ����
        if (Assigned(TmpShip.Targets[pswRight]))
          and (not TmpShip.Targets[pswRight].TechActive(plttRangeDefence))
        then
          TmpTargetRocket := TmpShip.Targets[pswRight];
        // �������� ������� ����
        if (Assigned(TmpTargetRocket)) then
          Break;
      end;
    end;
    // �������� ����� ����
    if (AShip.Targets[pswRocket] <> TmpTargetRocket) then
    begin
      // ���������� �������������� �������
      if (AAutoTarget) then
      begin
        if (Assigned(TmpTargetRocket)) then
          TPlanetarThread(Engine).ControlShips.Attach.Execute(AShip, APlanet, True)
        else
          TPlanetarThread(Engine).ControlShips.Attach.Execute(AShip, nil, True);
      end;
      AShip.Targets[pswRocket] := TmpTargetRocket;
      // �������� ����� ����
      TPlanetarThread(Engine).SocketWriter.ShipRetarget(AShip, pswRocket);
      // ������ ����� ���� ��� ���������� ���������
      if (AAutoTarget) then
        Auto(AShip);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
