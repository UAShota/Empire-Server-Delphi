{**********************************************}
{                                              }
{      Модуль чтения данных с сокета           }
{       Copyright (c) 2016 UAShota              }
{                                              }
{**********************************************}
unit SR.Planetar.Socket.Reader;

interface

uses
  System.SysUtils,
  System.Generics.Collections,

  SR.Engine.Server,
  SR.Globals.Log,
  SR.Globals.Player,
  SR.Transport.Buffer,
  SR.Planetar.Classes,
  SR.Planetar.Custom,
  SR.Planetar.Profile;

type
  TPlanetarSocketReader = class(TPlanetarCustom)
  private const
    CMD_SHIP_MERGE = $1000;
    CMD_SHIP_MOVETO = $1001;
    CMD_SHIP_ATTACHTO = $1002;
    CMD_PLANET_TRADE_PATH = $1003;
    CMD_SHIP_FROM_HANGAR = $1004;
    CMD_PLANET_SUBSCRIBE = $1005;
    CMD_SHIP_MOVE_TO_HANGAR = $1006;
    CMD_PLANET_SHOW_DETAILS = $1007;
    CMD_RESOURCE_MOVE = $1008;
    CMD_SHIP_CONSTRUCT = $1009;
    CMD_TECH_WARSHIP_BUY = $100A;
    CMD_BUILDING_CONSTRUCT = $100B;
    CMD_TECH_BUILDING_BUY = $100C;
    CMD_SHIP_CHANGE_ACTIVE = $100D;
    CMD_SHIP_HYPODISPERSION = $100E;
    CMD_SHIP_MOVETO_GROUP = $100F;
    CMD_SHIP_SEPARATE = $1010;
    CMD_SHIP_PORTAL_OPEN = $1012;
    CMD_SHIP_DESTROY = $1013;
    CMD_SHIP_PORTAL_CLOSE = $1014;
    CMD_SHIP_PORTAL_JUMP = $1015;
    CMD_SHIP_ANNIHILATION = $1016;
    CMD_SHIP_SKILL_CONSTRUCTOR = $1017;
    CMD_SHIP_HANGAR_SWAP = $1018;
  private var
    FBuffer: TTransportBuffer;
    FPlayer: TGlPlayer;
  private
    function ReadPlanet(): TPlPlanet;
    function ReadShip(): TPlShip;
    procedure ShipMerge();
    procedure ShipSeparate();
    procedure ShipMoveTo();
    procedure ShipMoveToGroup();
    procedure ShipAttachTo();
    procedure ShipFromHangar();
    procedure ShipToHangar();
    procedure ShipConstruct();
    procedure ShipChangeActive();
    procedure ShipChangeHypodispersion();
    procedure ShipPortalOpen();
    procedure ShipPortalClose();
    procedure ShipPortalJump();
    procedure ShipDestroy();
    procedure ShipSkillConstructor();
    procedure ShipAnnihilation();
    procedure ShipHangarSwap();
    procedure PlanetTradePath();
    procedure PlanetSubscribe();
    procedure PlanetShowDetails();
    procedure ResourceMove();
    procedure BuildingConstruct();
    procedure TechWarShipBuy();
    procedure TechBuildingBuy();
  public
    procedure Work(); override;
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPlanetarSocketReader.Work();
var
  TmpClient: TPlClientsDictPair;
begin
  for TmpClient in TPlanetarThread(Engine).Clients do
  try
    FPlayer := TmpClient.Key;
    // Очередь пуста
    if (FPlayer.Info.Reader.Queue.QueueSize = 0) then
      Continue;
    // Обработаем пакет
    FBuffer := FPlayer.Info.Reader.Queue.PopItem();
    case FBuffer.ReadCommand() of
      CMD_SHIP_MERGE:
        ShipMerge();
      CMD_SHIP_SEPARATE:
        ShipSeparate();
      CMD_SHIP_MOVETO:
        ShipMoveTo();
      CMD_SHIP_MOVETO_GROUP:
        ShipMoveToGroup();
      CMD_SHIP_ATTACHTO:
        ShipAttachTo();
      CMD_PLANET_TRADE_PATH:
        PlanetTradePath();
      CMD_SHIP_FROM_HANGAR:
        ShipFromHangar();
      CMD_SHIP_MOVE_TO_HANGAR:
        ShipToHangar();
      CMD_SHIP_CONSTRUCT:
        ShipConstruct();
      CMD_SHIP_CHANGE_ACTIVE:
        ShipChangeActive();
      CMD_SHIP_HYPODISPERSION:
        ShipChangeHypodispersion();
      CMD_PLANET_SUBSCRIBE:
        PlanetSubscribe();
      CMD_PLANET_SHOW_DETAILS:
        PlanetShowDetails();
      CMD_RESOURCE_MOVE:
        ResourceMove();
      CMD_TECH_WARSHIP_BUY:
        TechWarShipBuy();
      CMD_TECH_BUILDING_BUY:
        TechBuildingBuy();
      CMD_BUILDING_CONSTRUCT:
        BuildingConstruct();
      CMD_SHIP_PORTAL_OPEN:
        ShipPortalOpen();
      CMD_SHIP_PORTAL_CLOSE:
        ShipPortalClose();
      CMD_SHIP_PORTAL_JUMP:
        ShipPortalJump();
      CMD_SHIP_DESTROY:
        ShipDestroy();
      CMD_SHIP_ANNIHILATION:
        ShipAnnihilation();
      CMD_SHIP_SKILL_CONSTRUCTOR:
        ShipSkillConstructor();
      CMD_SHIP_HANGAR_SWAP:
        ShipHangarSwap();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlanetarSocketReader.ReadPlanet(): TPlPlanet;
var
  TmpID: Integer;
begin
  TmpID := FBuffer.ReadInteger();
  if (TmpID >= TPlanetarThread(Engine).ControlPlanets.ListPlanets.Count) or (TmpID < 0) then
    Result := nil
  else
    Result := TPlanetarThread(Engine).ControlPlanets.ListPlanets[TmpID];
end;

function TPlanetarSocketReader.ReadShip(): TPlShip;
var
  TmpID: Integer;
begin
  TmpID := FBuffer.ReadInteger();
  if (TmpID >= TPlanetarThread(Engine).ControlShips.ListShips.Count) or (TmpID < 0) then
    Result := nil
  else
    Result := TPlanetarThread(Engine).ControlShips.ListShips[TmpID];
end;

procedure TPlanetarSocketReader.ShipMoveTo();
var
  TmpShipPlanet: TPlPlanet;
  TmpShip: TPlShip;
  TmpTargetPlanet: TPlPlanet;
  TmpTargetSlot: Integer;
begin
  TmpShipPlanet := ReadPlanet();
  TmpShip := ReadShip();
  TmpTargetPlanet := ReadPlanet();
  TmpTargetSlot := FBuffer.ReadInteger();
  // Основная валидация
  if (not Assigned(TmpShipPlanet)
    or not Assigned(TmpShip)
    or not Assigned(TmpTargetPlanet))
  then
    Exit();
  // Дополнительная валидация
  if (TmpShipPlanet <> TmpShip.Planet) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.MoveToPlanet.Player(TmpShip, TmpTargetPlanet, TmpTargetSlot, FPlayer);
end;

procedure TPlanetarSocketReader.ShipMoveToGroup();
var
  TmpI: Integer;
  TmpShipCount: Integer;
  TmpPlanetCount: Integer;
  TmpShip: TPlShip;
  TmpPlanet: TPlPlanet;
  TmpPlanetList: TPlPlanetList;
  TmpShipList: TPlShipList;
begin
  TmpPlanetCount := FBuffer.ReadInteger();
  TmpShipCount := FBuffer.ReadInteger();
  TmpPlanetList := TPlPlanetList.Create();
  TmpShipList := TPlShipList.Create();
  try
    // Сбор планет
    for TmpI := 1 to TmpPlanetCount do
    begin
      TmpPlanet := ReadPlanet();
      if (Assigned(TmpPlanet)) then
        TmpPlanetList.Add(TmpPlanet);
    end;
    // Сбор корабликов
    for TmpI := 1 to TmpShipCount do
    begin
      TmpPlanet := ReadPlanet();
      TmpShip := ReadShip();
      if (TmpPlanet = TmpShip.Planet)
        and (not TmpShip.Landing.IsLowOrbit)
      then
        TmpShipList.Add(TmpShip);
    end;
    // Отправим команду на исполнение
    TPlanetarThread(Engine).ControlShips.Group.Player(TmpPlanetList, TmpShipList, FPlayer);
  finally
    FreeAndNil(TmpPlanetList);
    FreeAndNil(TmpShipList);
  end;
end;

procedure TPlanetarSocketReader.ShipAnnihilation();
var
  TmpShipPlanet: TPlPlanet;
  TmpShip: TPlShip;
begin
  TmpShipPlanet := ReadPlanet();
  TmpShip := ReadShip();
  // Основная валидация
  if (not Assigned(TmpShipPlanet)
    or not Assigned(TmpShip))
  then
    Exit();
  // Дополнительная валидация
  if (TmpShipPlanet <> TmpShip.Planet) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.Annihilation.Player(TmpShip, FPlayer);
end;

procedure TPlanetarSocketReader.ShipAttachTo();
var
  TmpShipPlanet: TPlPlanet;
  TmpShip: TPlShip;
  TmpTargetPlanet: TPlPlanet;
begin
  TmpShipPlanet := ReadPlanet();
  TmpShip := ReadShip();
  TmpTargetPlanet := ReadPlanet();
  // Основная валидация
  if (not Assigned(TmpShipPlanet)
    or not Assigned(TmpShip))
  then
    Exit();
  // Дополнительная валидация
  if (TmpShipPlanet <> TmpShip.Planet) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.Attach.Player(TmpShip, TmpTargetPlanet, FPlayer);
end;

procedure TPlanetarSocketReader.ShipMerge();
var
  TmpPlanet: TPlPlanet;
  TmpSource: TPlShip;
  TmpDestination: TPlShip;
  TmpCount: Integer;
begin
  TmpPlanet := ReadPlanet();
  TmpSource := ReadShip();
  TmpDestination := ReadShip();
  TmpCount := FBuffer.ReadInteger();
  // Основная валидация
  if (not Assigned(TmpPlanet)
    or not Assigned(TmpSource)
    or not Assigned(TmpDestination))
  then
    Exit();
  // Дополнительная валидация
  if (TmpSource.Planet <> TmpPlanet)
    or (TmpDestination.Planet <> TmpPlanet)
  then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.Merge.Player(TmpSource, TmpDestination, TmpCount, FPlayer);
end;

procedure TPlanetarSocketReader.ShipSeparate();
var
  TmpPlanet: TPlPlanet;
  TmpSource: TPlShip;
  TmpSlot: Integer;
  TmpCount: Integer;
begin
  TmpPlanet := ReadPlanet();
  TmpSource := ReadShip();
  TmpSlot := FBuffer.ReadInteger();
  TmpCount := FBuffer.ReadInteger();
  // Основная валидация
  if (not Assigned(TmpPlanet)
    or not Assigned(TmpSource))
  then
    Exit();
  // Дополнительная валидация
  if (TmpPlanet <> TmpSource.Planet) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.Separate.Player(TmpSource, TmpSlot, TmpCount, FPlayer);
end;

procedure TPlanetarSocketReader.ShipSkillConstructor();
var
  TmpPlanet: TPlPlanet;
  TmpSource: TPlShip;
  TmpDestination: TPlShip;
begin
  TmpPlanet := ReadPlanet();
  TmpSource := ReadShip();
  TmpDestination := ReadShip();
  // Основная валидация
  if (not Assigned(TmpPlanet)
    or not Assigned(TmpSource)
    or not Assigned(TmpDestination))
  then
    Exit();
  // Дополнительная валидация
  if (TmpSource.Planet <> TmpPlanet)
    or (TmpDestination.Planet <> TmpPlanet)
  then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.SkillConstruct.Player(TmpSource, TmpDestination, FPlayer);
end;

procedure TPlanetarSocketReader.ShipFromHangar();
var
  TmpHangarSlot: Integer;
  TmpPlanet: TPlPlanet;
  TmpSlot: Integer;
  TmpCount: Integer;
begin
  TmpHangarSlot := FBuffer.ReadInteger();
  TmpPlanet := ReadPlanet();
  TmpSlot := FBuffer.ReadInteger();
  TmpCount := FBuffer.ReadInteger();
  // Основная валидация
  if (not Assigned(TmpPlanet)) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.MoveFromHangar.Player(TmpHangarSlot, TmpPlanet, TmpSlot, TmpCount, FPlayer);
end;

procedure TPlanetarSocketReader.ShipHangarSwap();
var
  TmpHangarFrom: Integer;
  TmpHangarTo: Integer;
begin
  TmpHangarFrom := FBuffer.ReadInteger();
  TmpHangarTo := FBuffer.ReadInteger();
  // Отправим команду на исполнение
  TPlanetarProfile(TPlanetarThread(Engine).Player.PlanetarProfile).Hangar.Swap(TmpHangarFrom, TmpHangarTo, FPlayer);
end;

procedure TPlanetarSocketReader.ShipToHangar();
var
  TmpPlanet: TPlPlanet;
  TmpShip: TPlShip;
  TmpHangarSlot: Integer;
begin
  TmpPlanet := ReadPlanet();
  TmpShip := ReadShip();
  TmpHangarSlot := FBuffer.ReadInteger();
  // Основная валидация
  if (not Assigned(TmpPlanet)
    or not Assigned(TmpShip))
  then
    Exit();
  // Дополнительная валидация
  if (TmpShip.Planet <> TmpPlanet) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.MoveToHangar.Player(TmpHangarSlot, TmpShip, FPlayer);
end;

procedure TPlanetarSocketReader.ShipChangeActive();
var
  TmpPlanet: TPlPlanet;
  TmpShip: TPlShip;
begin
  TmpPlanet := ReadPlanet();
  TmpShip := ReadShip();
  // Основная валидация
  if (not Assigned(TmpPlanet)
    or not Assigned(TmpShip))
  then
    Exit();
  // Дополнительная валидация
  if (TmpShip.Planet <> TmpPlanet) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.ChangeActivity.Player(TmpShip, FPlayer);
end;

procedure TPlanetarSocketReader.ShipConstruct();
var
  TmpPlanet: TPlPlanet;
  TmpShipType: TPlShipType;
  TmpCount: Integer;
begin
  TmpPlanet := ReadPlanet();
  TmpShipType := TPlShipType(FBuffer.ReadInteger());
  TmpCount := FBuffer.ReadInteger();
  // Основная валидация
  if (not Assigned(TmpPlanet)) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.Construct.Player(TmpPlanet, TmpShipType, TmpCount, FPlayer);
end;

procedure TPlanetarSocketReader.ShipPortalOpen();
var
  TmpShip: TPlShip;
  TmpPlanet: TPlPlanet;
  TmpDestinaton: TPlPlanet;
begin
  TmpPlanet := ReadPlanet();
  TmpShip := ReadShip();
  TmpDestinaton := ReadPlanet();
  // Основная валидация
  if (not Assigned(TmpPlanet)
    or not Assigned(TmpShip))
    or not Assigned(TmpDestinaton)
  then
    Exit();
  // Дополнительная валидация
  if (TmpShip.Planet <> TmpPlanet) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlPlanets.OpenPortal(TmpShip, TmpDestinaton, FPlayer);
end;

procedure TPlanetarSocketReader.ShipPortalClose();
var
  TmpPlanet: TPlPlanet;
begin
  TmpPlanet := ReadPlanet();
  // Основная валидация
  if (not Assigned(TmpPlanet)) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlPlanets.ClosePortal(TmpPlanet, FPlayer);
end;

procedure TPlanetarSocketReader.ShipPortalJump();
var
  TmpShip: TPlShip;
  TmpPlanet: TPlPlanet;
begin
  TmpPlanet := ReadPlanet();
  TmpShip := ReadShip();
  // Основная валидация
  if (not Assigned(TmpPlanet)
    or not Assigned(TmpShip))
  then
    Exit();
  // Дополнительная валидация
  if (TmpShip.Planet <> TmpPlanet) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.Portal.Player(TmpShip, FPlayer);
end;

procedure TPlanetarSocketReader.ShipDestroy();
var
  TmpPlanet: TPlPlanet;
  TmpShip: TPlShip;
begin
  TmpPlanet := ReadPlanet();
  TmpShip := ReadShip();
  // Основная валидация
  if (not Assigned(TmpPlanet)
    or not Assigned(TmpShip))
  then
    Exit();
  // Дополнительная валидация
  if (TmpShip.Planet <> TmpPlanet) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.Destruct.Player(TmpShip, FPlayer);
end;

procedure TPlanetarSocketReader.ShipChangeHypodispersion();
var
  TmpPlanet: TPlPlanet;
  TmpShip: TPlShip;
begin
  TmpPlanet := ReadPlanet();
  TmpShip := ReadShip();
  // Основная валидация
  if (not Assigned(TmpPlanet)
    or not Assigned(TmpShip))
  then
    Exit();
  // Дополнительная валидация
  if (TmpShip.Planet <> TmpPlanet) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlShips.Hypodispersion.Player(TmpShip, FPlayer);
end;

procedure TPlanetarSocketReader.PlanetSubscribe();
var
  TmpPlanet: TPlPlanet;
begin
  TmpPlanet := ReadPlanet();
  // Основная валидация
  if (not Assigned(TmpPlanet)) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlPlanets.Subscribe(TmpPlanet, FPlayer);
end;

procedure TPlanetarSocketReader.PlanetTradePath();
var
  TmpPlanetSource: TPlPlanet;
  TmpPlanetTarget: TPlPlanet;
begin
  TmpPlanetSource := ReadPlanet();
  TmpPlanetTarget := ReadPlanet();
  // Основная валидация
  if (not Assigned(TmpPlanetSource)
    or not Assigned(TmpPlanetTarget))
  then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlPlanets.ChangeTradePath(TmpPlanetSource, TmpPlanetTarget, FPlayer);
end;

procedure TPlanetarSocketReader.ResourceMove();
var
  TmpPlanetSource: TPlPlanet;
  TmpSourceSlot: Integer;
  TmpPlanetTarget: TPlPlanet;
  TmpTargetSlot: Integer;
  TmpCount: Integer;
  TmpOnePlace: Boolean;
begin
  TmpPlanetSource := ReadPlanet();
  TmpSourceSlot := FBuffer.ReadInteger();
  TmpPlanetTarget := ReadPlanet();
  TmpTargetSlot := FBuffer.ReadInteger();
  TmpCount := FBuffer.ReadInteger();
  TmpOnePlace := FBuffer.ReadBoolean();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlStorages.MoveResource(TmpPlanetSource, TmpPlanetTarget,
    TmpOnePlace, TmpSourceSlot, TmpTargetSlot, TmpCount, FPlayer);
end;

procedure TPlanetarSocketReader.PlanetShowDetails();
var
  TmpPlanet: TPlPlanet;
begin
  TmpPlanet := ReadPlanet();
  // Основная валидация
  if (not Assigned(TmpPlanet)) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlPlanets.ShowDetails(TmpPlanet, FPlayer);
end;

procedure TPlanetarSocketReader.TechWarShipBuy();
var
  TmpShipType: TPlShipType;
  TmpTech: TPlShipTechType;
begin
  TmpShipType := TPlShipType(FBuffer.ReadInteger());
  TmpTech := TPlShipTechType(FBuffer.ReadInteger());
  // Отправим команду на исполнение
  TPlanetarProfile(FPlayer.PlanetarProfile).BuyTech(TmpShipType, TmpTech, FPlayer);
end;

procedure TPlanetarSocketReader.TechBuildingBuy();
var
  TmpBuildingType: TPlBuildingType;
begin
  TmpBuildingType := TPlBuildingType(FBuffer.ReadInteger());
  // Отправим команду на исполнение
  TPlanetarProfile(FPlayer.PlanetarProfile).BuyTech(TmpBuildingType, FPlayer);
end;

procedure TPlanetarSocketReader.BuildingConstruct();
var
  TmpPlanet: TPlPlanet;
  TmpPosition: Integer;
  TmpBuildingType: TPlBuildingType;
begin
  TmpPlanet := ReadPlanet();
  TmpPosition := FBuffer.ReadInteger();
  TmpBuildingType := TPlBuildingType(FBuffer.ReadInteger());
  // Основная валидация
  if (not Assigned(TmpPlanet)) then
    Exit();
  // Отправим команду на исполнение
  TPlanetarThread(Engine).ControlBuildings.UpgradeOrAdd(TmpPlanet, TmpPosition, TmpBuildingType, FPlayer);
end;

end.
