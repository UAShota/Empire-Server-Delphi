{**********************************************}
{                                              }
{ Модуль управления планетарными постройками   }
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
    // Пересчет электричества
    procedure DoRecalcEnergy(ABuilding: TPlBuilding; ARemove, AForce: Boolean);
    // Добавление здания на планету
    procedure DoAdd(APlanet: TPlPlanet; APosition: Integer; ABuilding: TPlBuildingType;
      APlayer: TGlPlayer);
    // Увеличение уровня здания
    procedure DoUpgrade(APlanet: TPlPlanet; APosition: Integer;
      APlayer: TGlPlayer);
  public
    // Постройка указанного здания
    procedure Construct(ABuilding: TPlBuilding);
    // Завершение постройки указанного здания
    procedure ConstructDone(ABuilding: TPlBuilding; ARemove: Boolean;
      AForce: Boolean = False);
    // Удаление здания с планеты
    procedure Remove(APlanet: TPlPlanet; APosition: Integer;
      APlayer: TGlPlayer);
    // Увеличение уровня здания или покупка нового
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
  // Для обычных зданий затраты увеличиваются
  if (ARemove) then
    TmpRemove := -1
  else
    TmpRemove := 1;
  // А для электростанций наоборот
  if (ABuilding.BuildingType <> pbtElectro) then
    TmpRemove := -TmpRemove;
  // Уровень при постройке
  if (ABuilding.BuildingType = pbtElectro) or (AForce) then
    TmpLevel := ABuilding.Level
  else
    TmpLevel := ABuilding.Level + 1;
  // Убавим электричество сразу
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
  // Электростанции можно строить при 0-й энергии
  if ((ABuilding <> pbtElectro) and (APlanet.Energy - TmpEnergy < 0))
    or (TPlanetarProfile(APlayer.PlanetarProfile).TechBuilding(ABuilding, pttbActive) = 0)
  then
    Exit();
  // Создадим здание
  TmpBuilding := TPlBuilding.Create();
  TmpBuilding.BuildingType := ABuilding;
  TmpBuilding.Mode := pbModePrimary;
  TmpBuilding.Level := 0;
  TmpBuilding.Position := APosition;
  TmpBuilding.Planet := APlanet;
  // Добавим его на планету
  { TODO -omdv : Buildings добавление строения на планетоид }
  {  APlanet.Buildings.Add(APosition, TmpBuilding);}
  // И да будет стройка
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
  // Для апгрейда должно быть лишнее электричество, немаксимальный лвл и открыта технология
  if ((TmpBuilding.BuildingType <> pbtElectro) and (APlanet.Energy < TmpEnergy))
    or (TmpBuilding.HP <> 0)
    or (TmpBuilding.Level = I_MAX_BUILDING_LEVEL)
    or (TPlanetarProfile(APlayer.PlanetarProfile).TechBuilding(TmpBuilding.BuildingType, pttbActive) <= TmpBuilding.Level)
  then
    Exit();
  // И да будет стройка
  Construct(TmpBuilding);
end;

procedure TPlanetarBuildingsController.Construct(ABuilding: TPlBuilding);
begin
  // Каждый левел имеет по N структуры, т.е. здание 5-го лвл строится в 5 раз дольше
  ABuilding.HP := (ABuilding.Level + 1) * I_CONSTRUCTION_SPEED;
  ABuilding.Active := False;
  // Пересчитаем электричество для зданий, кроме электростанции отнимается сразу
  if (ABuilding.BuildingType <> pbtElectro) then
    DoRecalcEnergy(ABuilding, False, False);
  // Добавим здание в список строений
  { TODO -omdv : Buildings добавление строения на планетоид }
(*  TPlanetarThread(Engine).ListBuildBuildings.Add(ABuilding);*)
  // Отправим сообщение о начале постройки
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
  // Пересчитаем электроэнергию
  if (ABuilding.BuildingType = pbtElectro) or (AForce) then
    DoRecalcEnergy(ABuilding, ARemove, AForce);
  // Пересчитаем уровень планеты
  TmpValue := TPlanetarDictionary.BuildingTechList[ABuilding.Planet.Owner.Race,
    ABuilding.BuildingType, pttbCapture].Levels[ABuilding.Level];
  ABuilding.Planet.Level := ABuilding.Planet.Level + TmpRemove * TmpValue;
  // А если склад - убрать или добавить лишние ячейки
  if (ABuilding.BuildingType = pbtWarehouse) then
    TPlanetarThread(Engine).ControlStorages.ChangeStorageCount(ABuilding.Planet, TmpRemove, False);
end;

procedure TPlanetarBuildingsController.Remove(APlanet: TPlPlanet;
  APosition: Integer; APlayer: TGlPlayer);
var
  TmpBuilding: TPlBuilding;
  TmpTech: TPlBuildingTechItem;
begin
  // Нельзя строить на несвоей планете или в бою
  if (APlanet.Owner <> APlayer)
    or (APlanet.Timer[ppltmBattle])
  then
    Exit();
  // Поиск строения для удаления
  TmpBuilding := APlanet.Buildings[APosition];
  TmpTech := TPlanetarDictionary.BuildingTechList[TmpBuilding.Planet.Owner.Race,
    TmpBuilding.BuildingType, pttbEnergy];
  // Нельзя удлять электростанци, если энергия уйдет в минус
  if ((TmpBuilding.BuildingType = pbtElectro)
    and (APlanet.Energy < TmpTech.Levels[TmpBuilding.Level]))
  then
    Exit();
  ConstructDone(TmpBuilding, True);
  // Удалить здание из списка строений
  APlanet.Buildings[TmpBuilding.Position] := nil;
  FreeAndNil(TmpBuilding);
  // Пересчитать производство
  { TODO -omdv : Производство пересчитать }
{  TPlanetarThread(Engine).WorkerProduction.CalculateProduction(APlanet); }
end;

procedure TPlanetarBuildingsController.UpgradeOrAdd(APlanet: TPlPlanet; APosition: Integer;
  ABuildingType: TPlBuildingType; APlayer: TGlPlayer);
begin
  // Нельзя строить на несвоей планете, в бою или недостроенное здание
  if (APlanet.Owner <> APlayer)
    or (APlanet.Timer[ppltmBattle])
  then
    Exit();
  // Определим что делать с строением
  { TODO -omdv : Buildings обновление строения включить }
(*  if (APlanet.Buildings.ContainsKey(APosition)) then
    DoUpgrade(APlanet, APosition, AInfo)
  else
    DoAdd(APlanet, APosition, ABuildingType, AInfo); *)
  // Отправить обновленные параметры планеты, электро игнорим т.к. она дает плюшки только после постройки
  if (ABuildingType <> pbtElectro) then
    TPlanetarThread(Engine).SocketWriter.PlanetEnergyUpdate(APlanet);
end;

end.
