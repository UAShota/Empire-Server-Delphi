{**********************************************}
{                                              }
{ ������ �������� ��������� �������            }
{ Copyright (c) 2016 UAShota                    }
{                                              }
{ Rev A  2016.12.06                            }
{**********************************************}

unit SR.Planetar.Socket.Writer;

interface

uses
  System.DateUtils,
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,

  SR.Transport.Buffer,
  SR.Globals.Player,
  SR.Globals.Types,
  SR.Planetar.Profile,
  SR.Planetar.Classes,
  SR.Planetar.Custom;

type
  // ����� �������� ��������� �������
  TPlanetarSocketWriter = class(TPlanetarCustom)
  private const
    CMD_PLANETAR_ACTIVATED = $1000;
    // ������� ������� �������� ��������� �������
    CMD_LOAD_SYSTEM_BEGIN = $1001;
    // ������� ����������� �������
    CMD_SHIP_MOVE_TO = $1002;
    // ������� �������� �������
    CMD_SHIP_CREATE = $1003;
    // ������� �������� �������
    CMD_SHIP_DELETE = $1005;
    // ������� ���������� ������� �������
    CMD_PLANET_UPDATE_TIMER = $1006;
    // ������� ���������� HP �������
    CMD_SHIP_UPDATE_HP = $1007;
    // ������� ����� ������ �������
    CMD_SHIP_CHANGE_ATTACH = $1008;
    // ������� ����� ���� �������
    CMD_SHIP_CHANGE_TARGET = $1009;
    // ������� ���������� ��������� �������
    CMD_SHIP_UPDATE_STATE = $100A;
    // ������� �������� �������
    CMD_PLANET_PORTAL_OPEN = $100B;
    // ������� ��������� ��������� ������
    CMD_PLAYER_STORAGE_CHANGE = $100C;
    // ������� ���������� ������ ������ �����
    CMD_PLAYER_HANGAR_UPDATE = $100D;
    // ������� ������ ���� ������� �������
    CMD_PLANET_DETAILS_SHOW = $100E;
    // ������� ���������� ������ ��������� �������
    CMD_PLANET_STORAGE_UPDATE = $100F;
    // ������� ������� ����� ��������� �������
    CMD_PLANET_STORAGE_CLEAR = $1011;
    // ������� ���������� ������ ��������� ������
    CMD_PLAYER_STORAGE_UPDATE = $1012;
    // ������� �������� ���������� ����������
    CMD_PLAYER_TECH_WARSHIP_CREATE = $1013;
    // ������� ���������� ���������� ����������
    CMD_PLAYER_TECH_WARSHIP_UPDATE = $1014;
    // ������� ���������� �������� ��������� �������
    CMD_LOAD_SYSTEM_COMPLETE = $1015;
    // ������� �������� ���������� ��������
    CMD_PLAYER_TECH_BUILDING_CREATE = $1016;
    // ������� ���������� ������ ��������
    CMD_PLANET_BUILDING_UPDATE = $1017;
    // ������� ���������� ���������� ��������
    CMD_PLAYER_TECH_BUILDING_UPDATE = $1018;
    // ������� ���������� ������������ ������ ������
    CMD_PLAYER_INFO_UPDATE = $1019;
    // ������� �������� ������ ��������
    CMD_INFO_BUILDINGS_LOAD = $101A;
    // ������� �������� ������ ����������
    CMD_INFO_WARSHIPS_LOAD = $101B;
    // ������� ���������� ��������� ����������
    CMD_PLANET_STATE_UPDATE = $101C;
    // ������� ��������� ������� ������� ������������ ���������
    CMD_PLANET_STATE_TIME = $101D;
    // ������� ���������� ������ ��������� ����������
    CMD_PLANET_VISIBILITY_UPDATE = $101E;
    // ������� ����� ��������� �������� �� ���������
    CMD_PLANET_SUBSCRIPTION_CHANGED = $101F;
    // ������� ����� ��������� ����������
    CMD_PLANET_OWNER_CHANGED = $1020;
    // ������� ���������� ���� �������� ����������
    CMD_PLANET_COVERAGE_UPDATE = $1021;
    // ������� ����� ����������� ��������� ����
    CMD_PLANET_TRADEPATH_UPDATE = $1022;
    // ������� �������� �������
    CMD_PLANET_PORTAL_CLOSE = $1023;
    // ������� ���������� ������� ��������������
    CMD_PLANET_ELECTRO_UPDATE = $1024;
    // ������� ����� �������� ������� ����������
    CMD_PLANET_CAPTURE_UPDATE = $1025;
    // ������� ���������� �������� ������� ���
    CMD_SUBSCRIBE = $1026;
    // ������� ����� ������� ��������� ����������
    CMD_PLANET_STORAGE_RESIZE = $1027;
    // ������� ���������� ���������� ������� �� ����������
    CMD_PLANET_MODULES_UPDATE = $1028;
    // ������� ���������� �������� ������� ���������
    CMD_SHIP_UPDATE_TIMER = $1029;
    // ������� ���������� ���������� �������
    CMD_PLANET_PORTAL_UPDATE = $1030;
     // ������� ���������� �������� ������ ����������
    CMD_PLANET_LOWGRAVITY_UPDATE = $1031;
    // ������� ������������� ����������� �������
    CMD_SHIP_JUMP_TO = $1032;
    // ������� ���������� ������ �������
    CMD_SHIP_REFILL = $1033;
  private
    // ��������� ������ ������
    FBuffer: TTransportBuffer;
  private
    // ������� ���������� ��������
    function Disabled(): Boolean;
    // ����������� ������� ���������� � ��� ���
    function ConvertPlanetToID(APlanet: TPlPlanet): Integer;
    // �������� �� �������� � ��������
    procedure SendBuffer(APlanet: TPlPlanet = nil; APlayer: TGlPlayer = nil;
      AFriends: TGlPlayer = nil; ASendRole: TGlPlayer = nil); overload;
    // �������� ����������� ������
    procedure SendBuffer(APlayer: TGlPlayer); overload;
  public
    // ������������� ������������ ��������
    constructor Create(Engine: TObject); override;
    // ��������������� ������������ ��������
    destructor Destroy(); override;
  public
    procedure Work(); override;
    // �������� �������
    procedure ShipCreate(AShip: TPlShip; APlayer: TGlPlayer = nil);
    // �������� �������
    procedure ShipDelete(AShip: TPlShip; AExplosive: Boolean);
    // ����������� �������
    procedure ShipMoveTo(AShip: TPlShip; ATargetPlanet: TPlPlanet; ATargetSlot: Integer);
    // ����������� �������
    procedure ShipJumpTo(AShip: TPlShip; ASourcePlanet: TPlPlanet; ATargetSlot: Integer);
    // ���������� HP �������
    procedure ShipUpdateHP(AShip: TPlShip);
    // ����� ���� �������
    procedure ShipRetarget(AShip: TPlShip; AWeapon: TPlShipWeaponType; APlayer: TGlPlayer = nil);
    // ����� ������ �������
    procedure ShipChangeAttach(AShip: TPlShip);
    // ���������� ������� �������
    procedure ShipUpdateState(AShip: TPlShip);
    // ���������� ������ �������
    procedure ShipRefill(AShip: TPlShip);
    // ���������� ������� �������
    procedure ShipUpdateTimer(AShip: TPlShip; ATimer: TPlShipTimer; ASeconds: Integer);

    function PlanetSubscribe(APlayer: TGlPlayer; APlanet: TPlPlanet): Boolean;
    function PlanetUnsubscribe(APlayer: TGlPlayer; APlanet: TPlPlanet): Boolean;

    // ������� ���������� �������� �� �������
    procedure PlanetSubscriptionChange(APlanet: TPlPlanet; ASubscribed: Boolean; APlayer: TGlPlayer);
    // ������� ����� ��������� ����������
    procedure PlanetOwnerChanged(APlanet: TPlPlanet; APlayer: TGlPlayer = nil);
    // ������� ���������� ��������� �������
    procedure PlanetStateUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer = nil);
    // ������� ���������� �������� ����������
    procedure PlanetCoverageUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer; AIncrement: Boolean);
    // ������� ���������� ��������� ����������
    procedure PlanetVisibilityUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer; AHardLight, AIncrement: Boolean);
    procedure PlanetPortalOpen(ASource, ATarget: TPlPlanet; AEnter: Boolean; APlayer: TGlPlayer = nil);
    procedure PlanetPortalUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer = nil);
    procedure PlanetPortalClose(APlanet: TPlPlanet; APlayer: TGlPlayer = nil);
    procedure PlanetCaptureUpdate(APlanet: TPlPlanet);
    procedure PlanetLowGravityUpdate(APlanet: TPlPlanet; AEnabled: Boolean; APlayer: TGlPlayer = nil);
    procedure PlanetEnergyUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer = nil);
    procedure PlanetModulesUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer = nil);
    procedure PlanetTradePathUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer = nil);
    procedure PlanetStorageResize(APlanet: TPlPlanet; AClear: Boolean; APlayer: TGlPlayer = nil);
    procedure PlanetUpdateTimer(APlanet: TPlPlanet; ATimer: TPlPlanetTimer; ASeconds: Integer);
    // ������� ����������� ������� �������
    procedure PlanetDetailsShow(APlanet: TPlPlanet; APlayer: TGlPlayer);
    // ������� ���������� ������� ��������
    procedure PlanetBuildingUpdate(ABuiling: TPlBuilding; APlayer: TGlPlayer = nil);
    // ������� ���������� ������ ���������
    procedure PlanetStorageUpdate(APlanet: TPlPlanet; AStorage: TPlStorage; APlayer: TGlPlayer = nil);
    // ������� ������� ���������
    procedure PlanetStorageClear(APlanet: TPlPlanet; AIndex: Integer);
    // ������� ���������� �������������� ���������� ���������
    procedure PlayerInfoUpdate(APlayer: TGlPlayer);
    // ������� ���������� ������ ������
    procedure PlayerHangarUpdate(ASlot: Integer; ACount: Integer; AShipType: TPlShipType;
      APlayer: TGlPlayer);
    // ������� �������� ��������� ������
    procedure PlayerStorageChange(ASize: Integer; AHoldings: TGlStorageList; APlayer: TGlPlayer);
    // ������� ���������� ��������� ������
    procedure PlayerStorageUpdate(AIndex: Integer; AHolding: TGlStorageHolder; APlayer: TGlPlayer);
    // ������� �������� ���������� ���������
    procedure PlayerTechWarShipLoad(ATechList: PPLShipTechProfile;
      APlayerList: TPLShipTechValues; APlayer: TGlPlayer);
    // ������� ���������� ���������� ���������
    procedure PlayerTechWarShipUpdate(AShipType: TPlShipType; ATechType: TPlShipTechType;
      APlayer: TGlPlayer);
    // ������� �������� ���������� ������
    procedure PlayerTechBuildingLoad(ATechList: PPlBuildingTechProfile;
      AUserList: TPlBuildingTechValues; APlayer: TGlPlayer);
    // ������� ���������� ���������� ������
    procedure PlayerTechBuildingUpdate(ABuildingType: TPlBuildingType;
      APlayer: TGlPlayer);

    // �������� ������ ��������
    { TODO -omdv : Buildings �������� �������� � ������ }
{    procedure InfoBuildingsLoad(ABuildings: TPLBuildingInfoList; APlayer: TGlPlayer);}

    // ���������� ������� �� ����������� � ���������
    procedure PlanetarActivated(APlayer: TGlPlayer);
    // ��������� � ������ �������� ���������
    procedure SystemLoadBegin(APlayer: TGlPlayer);
    // ��������� � ���������� �������� ���������
    procedure SystemLoadEnd(APlayer: TGlPlayer);

    // ���������� ������� �� ����������� � ���������
    procedure GalaxyLoadAccept(APlayer: TGlPlayer);
    procedure GalaxyLoadBegin(APlayer: TGlPlayer);

    procedure Subscribe(APlayer: TGlPlayer; AValue: Boolean);
  end;

implementation

uses
  SR.Planetar.Thread;

constructor TPlanetarSocketWriter.Create(Engine: TObject);
begin
  inherited Create(Engine);

  FBuffer := TTransportBuffer.Create();
end;

destructor TPlanetarSocketWriter.Destroy();
begin
  FreeAndNil(FBuffer);

  inherited Destroy();
end;

procedure TPlanetarSocketWriter.Work();
var
  TmpClient: TPlClientsDictPair;
begin
  for TmpClient in TPlanetarThread(Engine).Clients do
  begin
    if (TmpClient.Key.Info.Writer.Buffer.Size > 0) then
      TmpClient.Key.Info.Writer.Commit();
  end;
end;

function TPlanetarSocketWriter.Disabled(): Boolean;
begin
  with TPlanetarThread(Engine) do
    Result := (Clients.Count = 0) or (not Available);
end;

function TPlanetarSocketWriter.ConvertPlanetToID(APlanet: TPlPlanet): Integer;
begin
  if (Assigned(APlanet)) then
    Result := APlanet.ID
  else
    Result := -1;
end;

procedure TPlanetarSocketWriter.SendBuffer(APlanet: TPlPlanet; APlayer, AFriends: TGlPlayer;
  ASendRole: TGlPlayer);
var
  TmpHandler: TPlClientsDictPair;
begin
  if (not FBuffer.Validated and not Assigned(ASendRole)) then
    raise Exception.Create('No validated buffer');
  try
  // ��������� ��������� ������������ ��� ��������
  if (Assigned(APlayer)) then
  begin
    APlayer.Info.Writer.Buffer.WriteBuffer(FBuffer);
    Exit();
  end;
  // �������������
  for TmpHandler in TPlanetarThread(Engine).Clients do
  begin
    // ������ �������
    if (Assigned(AFriends)) then
    begin
      if (AFriends.IsRoleFriend(TmpHandler.Key)) then
        TmpHandler.Key.Info.Writer.Buffer.WriteBuffer(FBuffer)
    end else
    // ���� ��� �����������
    if (not Assigned(APlanet) or (TmpHandler.Value.Contains(APlanet))) then
    begin
      if (not Assigned(ASendRole)) then
        TmpHandler.Key.Info.Writer.Buffer.WriteBuffer(FBuffer)
      else
        TmpHandler.Key.Info.Writer.Buffer.WriteBuffer(FBuffer, Integer(ASendRole.Role(TmpHandler.Key)));
    end;
  end;
  finally
    FBuffer.Rollback();
  end;
end;

procedure TPlanetarSocketWriter.SendBuffer(APlayer: TGlPlayer);
begin
  SendBuffer(nil, APlayer);
end;

procedure TPlanetarSocketWriter.ShipCreate(AShip: TPlShip; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_SHIP_CREATE) do
  begin
    WriteInteger(AShip.ID);
    WriteInteger(AShip.Owner.UID);
    WriteInteger(AShip.Planet.ID);
    WriteInteger(AShip.Landing);
    WriteInteger(Integer(AShip.ShipType));
    WriteInteger(Integer(AShip.State));
    WriteInteger(Integer(AShip.Mode));
    WriteInteger(ConvertPlanetToID(AShip.Attached));
    WriteInteger(AShip.Count);
    WriteInteger(AShip.HP);
    WriteInteger(AShip.Fuel);
    WriteBoolean(AShip.IsCapture);
    WriteBoolean(AShip.IsAutoTarget);
    Commit();
  end;
  SendBuffer(AShip.Planet, APlayer);
end;

procedure TPlanetarSocketWriter.ShipDelete(AShip: TPlShip; AExplosive: Boolean);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_SHIP_DELETE) do
  begin
    WriteInteger(AShip.ID);
    WriteBoolean(AExplosive);
    Commit();
  end;
  SendBuffer(AShip.Planet);
end;

procedure TPlanetarSocketWriter.ShipJumpTo(AShip: TPlShip; ASourcePlanet: TPlPlanet;
  ATargetSlot: Integer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_SHIP_JUMP_TO) do
  begin
    WriteInteger(AShip.ID);
    WriteInteger(AShip.Planet.ID);
    WriteInteger(ATargetSlot);
    Commit();
  end;
  SendBuffer(ASourcePlanet);
end;

procedure TPlanetarSocketWriter.ShipMoveTo(AShip: TPlShip;
  ATargetPlanet: TPlPlanet; ATargetSlot: Integer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_SHIP_MOVE_TO) do
  begin
    WriteInteger(AShip.ID);
    WriteInteger(ATargetPlanet.ID);
    WriteInteger(ATargetSlot);
    Commit();
  end;
  SendBuffer(AShip.Planet);
end;

procedure TPlanetarSocketWriter.ShipRefill(AShip: TPlShip);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_SHIP_REFILL) do
  begin
    WriteInteger(AShip.ID);
    WriteInteger(AShip.Fuel);
    Commit();
  end;
  SendBuffer(AShip.Planet);
end;

procedure TPlanetarSocketWriter.ShipUpdateHP(AShip: TPlShip);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_SHIP_UPDATE_HP) do
  begin
    WriteInteger(AShip.ID);
    WriteInteger(AShip.Count);
    WriteInteger(AShip.HP);
    WriteInteger(AShip.Destructed);
    Commit();
  end;
  SendBuffer(AShip.Planet);
end;

procedure TPlanetarSocketWriter.ShipRetarget(AShip: TPlShip; AWeapon: TPlShipWeaponType; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_SHIP_CHANGE_TARGET) do
  begin
    WriteInteger(AShip.ID);
    WriteInteger(Integer(AWeapon));
    if (Assigned(AShip.Targets[AWeapon])) then
    begin
      WriteInteger(AShip.Targets[AWeapon].Planet.ID);
      WriteInteger(AShip.Targets[AWeapon].ID);
    end else
    begin
      WriteInteger(-1);
      WriteInteger(-1);
    end;
    Commit();
  end;
  SendBuffer(AShip.Planet, APlayer);
end;

procedure TPlanetarSocketWriter.ShipChangeAttach(AShip: TPlShip);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_SHIP_CHANGE_ATTACH) do
  begin
    WriteInteger(AShip.ID);
    WriteInteger(ConvertPlanetToID(AShip.Attached));
    WriteBoolean(AShip.IsCapture);
    WriteBoolean(AShip.IsAutoTarget);
    Commit();
  end;
  SendBuffer(AShip.Planet);
end;

procedure TPlanetarSocketWriter.ShipUpdateState(AShip: TPlShip);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_SHIP_UPDATE_STATE) do
  begin
    WriteInteger(AShip.ID);
    WriteInteger(Integer(AShip.State));
    WriteInteger(Integer(AShip.Mode));
    WriteBoolean(AShip.IsCapture);
    Commit();
  end;
  SendBuffer(AShip.Planet)
end;

procedure TPlanetarSocketWriter.ShipUpdateTimer(AShip: TPlShip; ATimer: TPlShipTimer;
  ASeconds: Integer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_SHIP_UPDATE_TIMER) do
  begin
    WriteInteger(AShip.ID);
    WriteInteger(Integer(ATimer));
    WriteInteger(ASeconds);
    Commit();
  end;
  SendBuffer(AShip.Planet)
end;

function TPlanetarSocketWriter.PlanetSubscribe(APlayer: TGlPlayer; APlanet: TPlPlanet): Boolean;
var
  TmpList: TPlPlanetList;
begin
  TmpList := TPlanetarThread(Engine).Clients[APlayer];
  // ���� �������� ��� ���� - ������ ���������
  if (TmpList.Contains(APlanet)) then
    Exit(False)
  else
  begin
    TmpList.Add(APlanet);
    Result := True;
  end;
end;

function TPlanetarSocketWriter.PlanetUnsubscribe(APlayer: TGlPlayer; APlanet: TPlPlanet): Boolean;
var
  TmpList: TPlPlanetList;
begin
  TmpList := TPlanetarThread(Engine).Clients[APlayer];
  // ���� �������� ��� ��� - ������ ���������
  if (not TmpList.Contains(APlanet)) then
    Exit(False)
  else
  begin
    TmpList.Remove(APlanet);
    Result := True;
  end;
end;

procedure TPlanetarSocketWriter.PlanetUpdateTimer(APlanet: TPlPlanet; ATimer: TPlPlanetTimer;
  ASeconds: Integer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_UPDATE_TIMER) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(Integer(ATimer));
    WriteInteger(ASeconds);
    Commit();
  end;
  SendBuffer(APlanet)
end;

procedure TPlanetarSocketWriter.PlanetSubscriptionChange(APlanet: TPlPlanet; ASubscribed: Boolean;
  APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_SUBSCRIPTION_CHANGED) do
  begin
    WriteInteger(APlanet.ID);
    WriteBoolean(ASubscribed);
    Commit();
  end;
  SendBuffer(APlanet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetTradePathUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_TRADEPATH_UPDATE) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(ConvertPlanetToID(APlanet.ResPathOut));
    Commit();
  end;
  SendBuffer(APlanet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetStateUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_STATE_UPDATE) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(Integer(APlanet.State));
    WriteBoolean(APlanet.IsBigHole);
    Commit();
  end;
  SendBuffer(APlayer);
  // ������� ����� ��� �������������
  with FBuffer.Command(CMD_PLANET_STATE_TIME) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(APlanet.StateTime);
    Commit();
  end;
  SendBuffer(APlanet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetCoverageUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer;
  AIncrement: Boolean);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_COVERAGE_UPDATE) do
  begin
    WriteInteger(APlanet.ID);
    WriteBoolean(AIncrement);
  end;
  SendBuffer(nil, nil, nil, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetVisibilityUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer;
  AHardLight, AIncrement: Boolean);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_VISIBILITY_UPDATE) do
  begin
    WriteInteger(APlanet.ID);
    WriteBoolean(AHardLight);
    WriteBoolean(AIncrement);
    Commit();
  end;
  // ���������� ������ �������������
  if (AIncrement) then
    SendBuffer(nil, APlayer)
  else
    SendBuffer(APlanet, APlayer)
end;

procedure TPlanetarSocketWriter.PlanetOwnerChanged(APlanet: TPlPlanet; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_OWNER_CHANGED) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(APlanet.Owner.UID);
    Commit();
  end;
  SendBuffer(APlanet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetPortalOpen(ASource, ATarget: TPlPlanet; AEnter: Boolean;
  APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_PORTAL_OPEN) do
  begin
    WriteInteger(ASource.ID);
    WriteInteger(ATarget.ID);
    WriteBoolean(ASource.Portal.Breakable);
    WriteInteger(ASource.Portal.Limit);
    Commit();
  end;
  // �������� �������� ���� ������������� �� ������� ��� ���� ��� ��
  if (ASource.PlanetType = pltHole) then
    SendBuffer()
  else
    SendBuffer(ASource, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetPortalUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_PORTAL_UPDATE) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(APlanet.Portal.Limit);
    Commit();
  end;
  // �������� �������� ���� ������������� �� �������
  SendBuffer(APlanet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetPortalClose(APlanet: TPlPlanet; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_PORTAL_CLOSE) do
  begin
    WriteInteger(APlanet.ID);
    Commit();
  end;
  // �������� �������� ���� ������������� �� ������� ��� ���� ��� ��
  if (APlanet.PlanetType = pltHole) then
    SendBuffer()
  else
    SendBuffer(APlanet);
end;

procedure TPlanetarSocketWriter.PlanetEnergyUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_ELECTRO_UPDATE) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(APlanet.Energy);
    Commit();
  end;
  SendBuffer(APlanet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetLowGravityUpdate(APlanet: TPlPlanet; AEnabled: Boolean;
  APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_LOWGRAVITY_UPDATE) do
  begin
    WriteInteger(APlanet.ID);
    WriteBoolean(AEnabled);
    Commit();
  end;
  SendBuffer(APlanet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetModulesUpdate(APlanet: TPlPlanet; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_MODULES_UPDATE) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(APlanet.ResAvailIn[resModules]);
    Commit();
  end;
  SendBuffer(APlanet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetCaptureUpdate(APlanet: TPlPlanet);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_CAPTURE_UPDATE) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(APlanet.CapturePlayer.UID);
    WriteInteger(Trunc(APlanet.CaptureValue));
    Commit();
  end;
  SendBuffer(APlanet);
end;

procedure TPlanetarSocketWriter.PlanetDetailsShow(APlanet: TPlPlanet; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  // �������� ������� ��� ����� �������� ������
  with FBuffer.Command(CMD_PLANET_DETAILS_SHOW) do
  begin
    Commit();
  end;
  SendBuffer(APlayer);
end;

procedure TPlanetarSocketWriter.PlanetStorageUpdate(APlanet: TPlPlanet; AStorage: TPlStorage;
  APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_STORAGE_UPDATE) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(AStorage.Position);
    WriteInteger(Integer(AStorage.Holder.Resource));
    WriteInteger(AStorage.Holder.Count);
    { TODO -omdv : Storage ����������� ����� ����� ��������� }
{    Write(AStorage.Flags);}
    WriteBoolean(AStorage.Active);
    Commit();
  end;
  SendBuffer(APlanet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetBuildingUpdate(ABuiling: TPlBuilding; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_BUILDING_UPDATE) do
  begin
    WriteInteger(ABuiling.Planet.ID);
    WriteInteger(ABuiling.Position);
    WriteInteger(Integer(ABuiling.BuildingType));
    WriteInteger(ABuiling.Level);
    WriteInteger(ABuiling.HP);
    Commit();
  end;
  SendBuffer(ABuiling.Planet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetStorageClear(APlanet: TPlPlanet; AIndex: Integer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_STORAGE_CLEAR) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(AIndex);
    Commit();
  end;
  SendBuffer(APlanet);
end;

procedure TPlanetarSocketWriter.PlanetStorageResize(APlanet: TPlPlanet; AClear: Boolean;
  APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLANET_STORAGE_RESIZE) do
  begin
    WriteInteger(APlanet.ID);
    WriteInteger(APlanet.StoragesCount);
    WriteBoolean(AClear);
    Commit();
  end;
  SendBuffer(APlanet, APlayer);
end;

procedure TPlanetarSocketWriter.PlanetarActivated(APlayer: TGlPlayer);
begin
  // ������� ����� ������
  with APlayer.Info.Writer.Buffer.Command(CMD_PLANETAR_ACTIVATED) do
  begin
    WriteInteger(APlayer.UID);
    Commit();
  end;
  APlayer.Info.Writer.Commit();
end;

procedure TPlanetarSocketWriter.SystemLoadBegin(APlayer: TGlPlayer);
var
  TmpPlanet: TPlPlanet;
  TmpLink: TPlPlanet;
  TmpState: TPlPlanetState;
  TmpSoftLight: Boolean;
  TmpHardLight: Boolean;
  TmpCountSelf: Integer;
  TmpCountFriend: Integer;
  TmpCountEnemy: Integer;
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_LOAD_SYSTEM_BEGIN) do
  begin
    // ������ �������� ���������, � ��������
    WriteInteger(TPlanetarThread(Engine).PlanetarSize.Width);
    WriteInteger(TPlanetarThread(Engine).PlanetarSize.Height);
    // ������ ���������� ������������ ������
    WriteInteger(TPlanetarThread(Engine).ControlPlanets.ListPlanets.Count);
    // �������� ������ �������
    for TmpPlanet in TPlanetarThread(Engine).ControlPlanets.ListPlanets do
    begin
      // ��������� ���� ������� - ����� ������ �������� �������
      TmpHardLight := TmpPlanet.VisibleByPlayer(APlayer, True, True);
      TmpSoftLight := TmpHardLight or TmpPlanet.VisibleByPlayer(APlayer, False, True);
      TmpState := TmpPlanet.StateByVisible(TmpSoftLight);
      TmpCountSelf := TmpPlanet.CoverageByPlayer(APlayer, True, TmpCountFriend, TmpCountEnemy);
      // � ������� � �����
      WriteInteger(TmpPlanet.ID);
      WriteInteger(TmpPlanet.CoordX);
      WriteInteger(TmpPlanet.CoordY);
      WriteInteger(Integer(TmpPlanet.PlanetType));
      WriteInteger(TmpPlanet.Owner.UID);
      WriteInteger(Integer(TmpState));
      WriteBoolean(TmpHardLight);
      WriteBoolean(TmpSoftLight);
      WriteInteger(TmpCountSelf);
      WriteInteger(TmpCountFriend);
      WriteInteger(TmpCountEnemy);
      WriteBoolean(TmpPlanet.IsBigHole);
    end;
    // �������� ������ ������
    for TmpPlanet in TPlanetarThread(Engine).ControlPlanets.ListPlanets do
    begin
      WriteInteger(TmpPlanet.Links.Count);
      for TmpLink in TmpPlanet.Links do
        WriteInteger(TmpLink.ID);
    end;
    Commit();
  end;
  SendBuffer(APlayer);
end;

procedure TPlanetarSocketWriter.SystemLoadEnd(APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_LOAD_SYSTEM_COMPLETE) do
  begin
    Commit();
  end;
  SendBuffer(APlayer);
end;

procedure TPlanetarSocketWriter.PlayerHangarUpdate(ASlot: Integer; ACount: Integer;
  AShipType: TPlShipType; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLAYER_HANGAR_UPDATE) do
  begin
    WriteInteger(ASlot);
    WriteInteger(Integer(AShipType));
    WriteInteger(ACount);
    Commit();
  end;
  SendBuffer(APlayer);
end;

procedure TPlanetarSocketWriter.PlayerStorageChange(ASize: Integer; AHoldings: TGlStorageList;
  APlayer: TGlPlayer);
var
  TmpI: Integer;
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLAYER_STORAGE_CHANGE) do
  begin
    WriteInteger(ASize);
    Commit();
  end;
  SendBuffer(APlayer);
  // ����� �������� ��������� � ������ �����
  for TmpI := 1 to ASize do
  begin
    if (AHoldings[TmpI].Resource <> resEmpty) then
      PlayerStorageUpdate(TmpI, AHoldings[TmpI], APlayer);
  end;
end;

procedure TPlanetarSocketWriter.PlayerStorageUpdate(Aindex: Integer; AHolding: TGlStorageHolder;
  APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLAYER_STORAGE_UPDATE) do
  begin
    WriteInteger(AIndex);
    WriteInteger(Integer(AHolding.Resource));
    WriteInteger(AHolding.Count);
    Commit();
  end;
  SendBuffer(APlayer);
end;

procedure TPlanetarSocketWriter.PlayerTechWarShipLoad(ATechList: PPLShipTechProfile;
  APlayerList: TPLShipTechValues; APlayer: TGlPlayer);
var
  TmpWarShip: TPlShipType;
  TmpTech: TPlShipTechType;
  TmpItem: TPLShipTechItem;
  TmpIndex: Integer;
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLAYER_TECH_WARSHIP_CREATE) do
  begin
    // ������� ��� ������ ����������
    for TmpWarShip := Succ(pshtpEmpty) to High(TPlShipType) do
    begin
      for TmpTech := Low(TPlShipTechType) to High(TPlShipTechType) do
      begin
        TmpItem := ATechList[TmpWarShip, TmpTech];
        // ������� ����� � ��������
        WriteInteger(APlayerList[TmpWarShip, TmpTech]);
        WriteInteger(TmpItem.Count);
        WriteBoolean(TmpItem.Supported);
        // ������� ���� �������� �������
        for TmpIndex := 0 to 5 do
          WriteInteger(TmpItem.Levels[TmpIndex]);
      end;
    end;
    Commit();
  end;
  // ����� ���������� � ������ ������
  SendBuffer(APlayer);
end;

procedure TPlanetarSocketWriter.PlayerTechBuildingLoad(ATechList: PPlBuildingTechProfile;
  AUserList: TPlBuildingTechValues; APlayer: TGlPlayer);
var
  TmpBuilding: TPlBuildingType;
  TmpTech: TPlBuildingTechType;
  TmpItem: TPlBuildingTechItem;
  TmpIndex: Integer;
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLAYER_TECH_BUILDING_CREATE) do
  begin
    // ������� ��� ������ ����������
    for TmpBuilding := Succ(pbtEmpty) to High(TPlBuildingType) do
    begin
      for TmpTech := Low(TPlBuildingTechType) to High(TPlBuildingTechType) do
      begin
        TmpItem := ATechList[TmpBuilding, TmpTech];
        // ������� ����� � ��������
        WriteInteger(AUserList[TmpBuilding, TmpTech]);
        WriteInteger(TmpItem.Count);
        WriteBoolean(TmpItem.Supported);
        // ������� ���� �������� �������
        for TmpIndex := 0 to 5 do
          WriteInteger(TmpItem.Levels[TmpIndex]);
      end;
    end;
    Commit();
  end;
  SendBuffer(APlayer);
end;

procedure TPlanetarSocketWriter.PlayerTechWarShipUpdate(AShipType: TPlShipType;
  ATechType: TPlShipTechType; APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLAYER_TECH_WARSHIP_UPDATE) do
  begin
    WriteInteger(Integer(AShipType));
    WriteInteger(Integer(ATechType));
    Commit();
  end;
  SendBuffer(APlayer);
end;

procedure TPlanetarSocketWriter.PlayerTechBuildingUpdate(ABuildingType: TPlBuildingType;
  APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLAYER_TECH_BUILDING_UPDATE) do
  begin
    WriteInteger(Integer(ABuildingType));
    Commit();
  end;
  SendBuffer(APlayer);
end;

procedure TPlanetarSocketWriter.PlayerInfoUpdate(APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  with FBuffer.Command(CMD_PLAYER_INFO_UPDATE) do
  begin
    WriteInteger(APlayer.Gold);
    WriteInteger(APlayer.Credits);
    WriteInteger(APlayer.Fuel);
    Commit();
  end;
  SendBuffer(APlayer);
end;

{procedure TPlanetarSocketWriter.InfoBuildingsLoad(
  ABuildings: TPLBuildingInfoList; APlayer: TGlPlayer);
var
  TmpBuilding: TPLBuildingInfo;
  TmpResCount: Integer;
begin
  with FBuffer.Command(CMD_INFO_BUILDINGS_LOAD) do
  begin
    for TmpBuilding in ABuildings do
    begin
      Write(TmpBuilding.Name);
      Write(TmpBuilding.Description);
      for TmpResCount := 0 to ResWork do
      begin
        Write(Integer(TmpBuilding.ResourceIn[0][TmpResCount]));
        Write(Integer(TmpBuilding.ResourceIn[1][TmpResCount]));
        Write(Integer(TmpBuilding.ResourceOut[TmpResCount]));
        Write(TmpBuilding.ResOutCount[TmpResCount]);
      end;
    end;
    Commit();
  end;
  SendBuffer(APlayer);
end;   }

procedure TPlanetarSocketWriter.GalaxyLoadAccept(APlayer: TGlPlayer);
begin
  // ����������� ��������
  if (Disabled) then
    Exit();
  // ������� ����� ������
  { TODO -omdv : Galaxy ���������� �������� }
  with FBuffer.Command($2000) do
  begin
    Commit();
  end;
  SendBuffer(APlayer);
end;

procedure TPlanetarSocketWriter.GalaxyLoadBegin(APlayer: TGlPlayer);
//var
//
begin
//  FBuffer.Command($2002);
  // ����� ���������� � ������ ������
//  SendCommand(TmpStream, AInfo);
end;

procedure TPlanetarSocketWriter.Subscribe(APlayer: TGlPlayer; AValue: Boolean);
begin
  // ������� ����� ������
  with APlayer.Info.Writer.Buffer.Command(CMD_SUBSCRIBE) do
  begin
    WriteBoolean(AValue);
    Commit();
  end;
  APlayer.Info.Writer.Commit();
end;

end.
