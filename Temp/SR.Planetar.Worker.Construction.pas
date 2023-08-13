{**********************************************}
{                                              }
{ ������ ����������� �������� ��������� ������ }
{       Copyright (c) 2016 UAShota              }
{                                              }
{**********************************************}
unit SR.Planetar.Worker.Construction;

interface

uses
  System.SysUtils,
  System.Math,
  System.DateUtils,
  System.Generics.Collections,

  SR.Planetar.Classes,
  SR.Planetar.Dictionary,
  SR.Planetar.Custom;

type
  TPlanetarWorkerConstruction = class(TPlanetarCustom)
  private
    procedure DoPlanetarBuildings();
  public
    procedure Work(); reintroduce;
  end;

implementation

uses
  SR.Planetar.Thread;

{ TWorkerConstruction }

procedure TPlanetarWorkerConstruction.Work();
begin
  DoPlanetarBuildings();
end;

procedure TPlanetarWorkerConstruction.DoPlanetarBuildings();
var
  TmpBuilding: TPlBuilding;
begin
(*  for TmpBuilding in TPlanetarThread(Engine).ListBuildBuildings do
  begin
    TmpBuilding.HP := Max(0, TmpBuilding.HP - 100);
    // ������ ������� ��������� ��� ���������
    if (TmpBuilding.HP > 0) then
    begin
      TPlanetarThread(Engine).SocketWriter.PlanetBuildingUpdate(TmpBuilding);
      Continue;
    end;
    // ������� ��� �� ������ ��������
    TPlanetarThread(Engine).ListBuildBuildings.Remove(TmpBuilding);
    // ��������� ��������� ������
    Inc(TmpBuilding.Level);
    TPlanetarThread(Engine).SocketWriter.PlanetBuildingUpdate(TmpBuilding);
    // ��������� ����������� ��������� �������
    TPlanetarThread(Engine).ControlBuildings.ConstructDone(TmpBuilding, False);
  end;*)
end;

end.
