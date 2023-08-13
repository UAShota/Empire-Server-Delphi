{**********************************************}
{                                              }
{ ���� : ������������ �����                    }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Retarget;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ������������ �����
  TPLShipsControlRetarget = class(TPLShipsControlCustom)
  public
    // ������� ����������
    procedure Execute(APlanet: TPlPlanet);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlRetarget.Execute(APlanet: TPlPlanet);
var
  TmpPlanet: TPlPlanet;
  TmpShip: TPlShip;
begin
  try
    // �������� ��������� � �������� ������ ������ ���� �� ������� ���� ���
    if (APlanet.Timer[ppltmBattle]) then
    begin
      for TmpPlanet in APlanet.Links do
      begin
        if (TmpPlanet.Timer[ppltmBattle])
          or (TmpPlanet.PlanetType = pltHole)
        then
          Continue;
        // ���������� ����������, ����������� � ���������� �������
        for TmpShip in TmpPlanet.Ships do
        begin
          if (TmpShip.CanRangeAutoTarget) then
            TPlanetarThread(Engine).ControlShips.TargetMarker.Highlight(TmpShip, APlanet, True);
        end;
      end;
      // �������� �� ���� ��������� �����������
      for TmpShip in APlanet.Ships do
        if (TmpShip.IsAutoTarget) then
      begin
        TPlanetarThread(Engine).ControlShips.Attach.Execute(TmpShip, nil, False);
        TPlanetarThread(Engine).ControlShips.TargetLocal.Execute(TmpShip);
      end;
    end else
    // �������� ��������� � ���� ������� �� ������
    begin
      for TmpShip in APlanet.Ships do
        TPlanetarThread(Engine).ControlShips.TargetMarker.Auto(TmpShip);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
