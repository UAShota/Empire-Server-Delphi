{**********************************************}
{                                              }
{ ������ ���������� ������������ �����������   }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev A  2016.12.14                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Planetar.Controller.Buildings;

interface

uses
  System.SysUtils,

  SR.Globals.Player,
  SR.Globals.Types,
  SR.Planetar.Classes,
  SR.Planetar.Profile,
  SR.Planetar.Dictionary,
  SR.Planetar.Custom;

type
  TPlanetarBuildingsController = class(TPlanetarCustom)
  private const
    I_CONSTRUCTION_SPEED = 1000;
    I_MAX_BUILDING_LEVEL = 5;
  private
    // �������� �������������
    procedure DoRecalcEnergy(ABuilding: TPlBuilding; ARemove, AForce: Boolean);
    // ���������� ������ �� �������
    procedure DoAdd(APlanet: TPlPlanet; APosition: Integer; ABuilding: TPlBuildingType;
      APlayer: TGlPlayer);
    // ���������� ������ ������
    procedure DoUpgrade(APlanet: TPlPlanet; APosition: Integer;
      APlayer: TGlPlayer);
  public
    // ��������� ���������� ������
    procedure Construct(ABuilding: TPlBuilding);
    // ���������� ��������� ���������� ������
    procedure ConstructDone(ABuilding: TPlBuilding; ARemove: Boolean;
      AForce: Boolean = False);
    // �������� ������ � �������
    procedure Remove(APlanet: TPlPlanet; APosition: Integer;
      APlayer: TGlPlayer);
    // ���������� ������ ������ ��� ������� ������
    procedure UpgradeOrAdd(APlanet: TPlPlanet; APosition: Integer;
      ABuildingType: TPlBuildingType; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPlanetarBuildingsController.DoRecalcEnergy(ABuilding: TPlBuilding;
  ARemove, AForce: Boolean);
var
  TmpRemove: Integer;
  TmpLevel: Integer;
  TmpValue: Integer;
begin
  // ��� ������� ������ ������� �������������
  if (ARemove) then
    TmpRemove := -1
  else
    TmpRemove := 1;
  // � ��� �������������� ��������
  if (ABuilding.BuildingType <> pbtElectro) then
    TmpRemove := -TmpRemove;
  // ������� ��� ���������
  if (ABuilding.BuildingType = pbtElectro) or (AForce) then
    TmpLevel := ABuilding.Level
  else
    TmpLevel := ABuilding.Level + 1;
  // ������ ������������� �����
  TmpValue := TPlanetarDictionary.BuildingTechList[ABuilding.Planet.Owner.Race,
    ABuilding.BuildingType, pttbEnergy].Levels[TmpLevel];
  ABuilding.Planet.Energy := ABuilding.Planet.Energy + TmpValue * TmpRemove;
end;

procedure TPlanetarBuildingsController.DoAdd(APlanet: TPlPlanet; APosition: Integer;
  ABuilding: TPlBuildingType; APlayer: TGlPlayer);
var
  TmpBuilding: TPlBuilding;
  TmpEnergy: Integer;
begin
  TmpEnergy := TPlanetarDictionary.BuildingTechList[raceGaal, ABuilding, pttbEnergy].Levels[1];
  // �������������� ����� ������� ��� 0-� �������
  if ((ABuilding <> pbtElectro) and (APlanet.Energy - TmpEnergy < 0))
    or (TPlanetarProfile(APlayer.PlanetarProfile).TechBuilding(ABuilding, pttbActive) = 0)
  then
    Exit();
  // �������� ������
  TmpBuilding := TPlBuilding.Create();
  TmpBuilding.BuildingType := ABuilding;
  TmpBuilding.Mode := pbModePrimary;
  TmpBuilding.Level := 0;
  TmpBuilding.Position := APosition;
  TmpBuilding.Planet := APlanet;
  // ������� ��� �� �������
  { TODO -omdv : Buildings ���������� �������� �� ��������� }
  {  APlanet.Buildings.Add(APosition, TmpBuilding);}
  // � �� ����� �������
  Construct(TmpBuilding);
end;

procedure TPlanetarBuildingsController.DoUpgrade(APlanet: TPlPlanet; APosition: Integer;
  APlayer: TGlPlayer);
var
  TmpBuilding: TPlBuilding;
  TmpEnergy: Integer;
begin
  TmpBuilding := APlanet.Buildings[APosition];
  TmpEnergy := TPlanetarDictionary.BuildingTechList[TmpBuilding.Planet.Owner.Race,
    TmpBuilding.BuildingType, pttbEnergy].Levels[TmpBuilding.Level + 1];
  // ��� �������� ������ ���� ������ �������������, �������������� ��� � ������� ����������
  if ((TmpBuilding.BuildingType <> pbtElectro) and (APlanet.Energy < TmpEnergy))
    or (TmpBuilding.HP <> 0)
    or (TmpBuilding.Level = I_MAX_BUILDING_LEVEL)
    or (TPlanetarProfile(APlayer.PlanetarProfile).TechBuilding(TmpBuilding.BuildingType, pttbActive) <= TmpBuilding.Level)
  then
    Exit();
  // � �� ����� �������
  Construct(TmpBuilding);
end;

procedure TPlanetarBuildingsController.Construct(ABuilding: TPlBuilding);
begin
  // ������ ����� ����� �� N ���������, �.�. ������ 5-�� ��� �������� � 5 ��� ������
  ABuilding.HP := (ABuilding.Level + 1) * I_CONSTRUCTION_SPEED;
  ABuilding.Active := False;
  // ����������� ������������� ��� ������, ����� �������������� ���������� �����
  if (ABuilding.BuildingType <> pbtElectro) then
    DoRecalcEnergy(ABuilding, False, False);
  // ������� ������ � ������ ��������
  { TODO -omdv : Buildings ���������� �������� �� ��������� }
(*  TPlanetarThread(Engine).ListBuildBuildings.Add(ABuilding);*)
  // �������� ��������� � ������ ���������
  TPlanetarThread(Engine).SocketWriter.PlanetBuildingUpdate(ABuilding);
end;

procedure TPlanetarBuildingsController.ConstructDone(ABuilding: TPlBuilding;
  ARemove: Boolean; AForce: Boolean = False);
var
  TmpRemove: Integer;
  TmpValue: Integer;
begin
  if (ARemove) then
    TmpRemove := -1
  else
    TmpRemove := 1;
  // ����������� ��������������
  if (ABuilding.BuildingType = pbtElectro) or (AForce) then
    DoRecalcEnergy(ABuilding, ARemove, AForce);
  // ����������� ������� �������
  TmpValue := TPlanetarDictionary.BuildingTechList[ABuilding.Planet.Owner.Race,
    ABuilding.BuildingType, pttbCapture].Levels[ABuilding.Level];
  ABuilding.Planet.Level := ABuilding.Planet.Level + TmpRemove * TmpValue;
  // � ���� ����� - ������ ��� �������� ������ ������
  if (ABuilding.BuildingType = pbtWarehouse) then
    TPlanetarThread(Engine).ControlStorages.ChangeStorageCount(ABuilding.Planet, TmpRemove, False);
end;

procedure TPlanetarBuildingsController.Remove(APlanet: TPlPlanet;
  APosition: Integer; APlayer: TGlPlayer);
var
  TmpBuilding: TPlBuilding;
  TmpTech: TPlBuildingTechItem;
begin
  // ������ ������� �� ������� ������� ��� � ���
  if (APlanet.Owner <> APlayer)
    or (APlanet.Timer[ppltmBattle])
  then
    Exit();
  // ����� �������� ��� ��������
  TmpBuilding := APlanet.Buildings[APosition];
  TmpTech := TPlanetarDictionary.BuildingTechList[TmpBuilding.Planet.Owner.Race,
    TmpBuilding.BuildingType, pttbEnergy];
  // ������ ������ �������������, ���� ������� ����� � �����
  if ((TmpBuilding.BuildingType = pbtElectro)
    and (APlanet.Energy < TmpTech.Levels[TmpBuilding.Level]))
  then
    Exit();
  ConstructDone(TmpBuilding, True);
  // ������� ������ �� ������ ��������
  APlanet.Buildings[TmpBuilding.Position] := nil;
  FreeAndNil(TmpBuilding);
  // ����������� ������������
  { TODO -omdv : ������������ ����������� }
{  TPlanetarThread(Engine).WorkerProduction.CalculateProduction(APlanet); }
end;

procedure TPlanetarBuildingsController.UpgradeOrAdd(APlanet: TPlPlanet; APosition: Integer;
  ABuildingType: TPlBuildingType; APlayer: TGlPlayer);
begin
  // ������ ������� �� ������� �������, � ��� ��� ������������� ������
  if (APlanet.Owner <> APlayer)
    or (APlanet.Timer[ppltmBattle])
  then
    Exit();
  // ��������� ��� ������ � ���������
  { TODO -omdv : Buildings ���������� �������� �������� }
(*  if (APlanet.Buildings.ContainsKey(APosition)) then
    DoUpgrade(APlanet, APosition, AInfo)
  else
    DoAdd(APlanet, APosition, ABuildingType, AInfo); *)
  // ��������� ����������� ��������� �������, ������� ������� �.�. ��� ���� ������ ������ ����� ���������
  if (ABuildingType <> pbtElectro) then
    TPlanetarThread(Engine).SocketWriter.PlanetEnergyUpdate(APlanet);
end;

end.
