{**********************************************}
{                                              }
{ ������ ���������� ��������                   }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev A  2016.11.18                            }
{ Rev B  2017.03.30                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Globals.Player;

interface

uses
  System.Generics.Collections,
  System.Classes,
  System.SysUtils,
  System.Math,

  SR.DataAccess,
  SR.Transport.Buffer,
  SR.Globals.Dictionaries,
  SR.Globals.Types;

type
  // ���������������� ������
  TGlStorage = class;
  TGlPlayer = class;

  // �������, �� ������� �������� ������� ���������, ��� �������� �������� �������
  TGlStorageCallback = procedure(AIndex: Integer; AHolding: TGlStorageHolder; APlayer: TGlPlayer) of object;

  // ����� �������� ��������������� �������
  TGlPlayerInfo = class(TObject)
    // ������ �� ������
    Player: TGlPlayer;
    // ������ �� ����������
    Connection: TObject;
    // ����� ������ ������
    Reader: TTransportQueue;
    // ����� ������ ������
    Writer: TTransportQueue;
    // IP �������
    IP: String;
  public
    constructor Create();
    destructor Destroy(); override;
  end;

  // ����� �������� ������
  TGlPlayer = class
  public var
    // �������������
    UID: Integer;
    // ���
    Name: String;
    // ���������� ���������
    Race: TGlRaceType;
    // ���������� ������
    Gold: Integer;
    // ���������� ������
    Credits: Integer;
    // ���������� �������
    Fuel: Integer;
    // ��� ������
    Password: String;
    // ���������
    Storage: TGlStorage;
    // ����������� �������
    PlanetarProfile: TObject;
    // ���������� � ����������
    Info: TGlPlayerInfo;
    // ������� ����
    IsBot: Boolean;
  private
    // �������� ��������� ������
    procedure DoLoadHoldings();
  public
    constructor Create();
    destructor Destroy(); override;
  public
    // ����������� ������, �������� ���������
    procedure Connect(Ainfo: TGlPlayerInfo);
    // ���������� ������, ��� �������� ���������
    procedure Disconnect();

    procedure Load;

    // ���� ���� ������� �� ��������� ���� � �����
    function Role(ALeft, ARight: TGlPlayer): TGlPlayerRole; overload;
    // ���� ���� ������� �� ��������� ���� � �����
    function Role(AVersus: TGlPlayer; AHideEnemy: Boolean = False): TGlPlayerRole; overload;
    // ������� ��������� ���� ����������
    function IsRoleEnemy(ALeft, ARight: TGlPlayer): Boolean; overload;
    // ������� ��������� ���� ����������
    function IsRoleEnemy(AVersus: TGlPlayer): Boolean; overload;
    // ������� ��������� ���� ��������
    function IsRoleFriend(ALeft, ARight: TGlPlayer): Boolean; overload;
    // ������� ��������� ���� ��������
    function IsRoleFriend(AVersus: TGlPlayer): Boolean; overload;
  end;
  // ������� ��������� �������
  TGlPlayerDict = TDictionary<Integer, TGlPlayer>;
  TGlPlayerDictPair = TPair<Integer, TGlPlayer>;

  // ����� ���������
  TGlStorage = class
  private var
    FStorages: TGlStorageList;
    FSize: Integer;
  public
    constructor Create();
    destructor Destroy(); override;
  public
    // ���������� ������� ������� ���������� ��� � ��������� ����
    function IncrementResource(AResource: TGlResourceType; ACount: Integer;
      ACallback: TGlStorageCallback; APlayer: TGlPlayer; AUseFreeSpace: Boolean = False): Integer; overload;
    // ���������� ������� ������� ���������� ��� � ��������� ����
    function IncrementResource(AResource: TGlResourceType; AIndex, ACount: Integer;
      ACallback: TGlStorageCallback; APlayer: TGlPlayer): Integer; overload;
    // ���������� ������� � ��������� �����
    procedure DecrementResource(AIndex, ACount: Integer; ACallback: TGlStorageCallback;
      APlayer: TGlPlayer);
    // ����� ���� ������
    procedure Exchange(ASourceIndex, ATargetIndex: Integer; ACallback: TGlStorageCallback;
      APlayer: TGlPlayer);
  public
    // ����� ���������
    property Storages: TGlStorageList read FStorages;
    // ������ ���������
    property Size: Integer read FSize write FSize;
  end;

implementation

uses
  SR.Planetar.Profile;

constructor TGlPlayer.Create();
begin
  Storage := TGlStorage.Create();
  PlanetarProfile := TPlanetarProfile.Create(Self);
end;

destructor TGlPlayer.Destroy();
begin
  FreeAndNil(PlanetarProfile);
  FreeAndNil(Storage);
end;

procedure TGlPlayer.Load;
begin
  TPlanetarProfile(PlanetarProfile).Load();
end;

procedure TGlPlayer.Connect(AInfo: TGlPlayerInfo);
begin
  Info := AInfo;
  Info.Player := Self;
  // �������� ���� ����������� ��� ����������� � ��� �����������
  if (not Assigned(TPlanetarProfile(PlanetarProfile).Main)) then
  begin
    DoLoadHoldings();
    TPlanetarProfile(PlanetarProfile).Start();
  end else
    TPlanetarProfile(PlanetarProfile).Subscribe();
end;

procedure TGlPlayer.Disconnect();
begin
  TPlanetarProfile(PlanetarProfile).Disconnect();
  Info := nil;
end;

function TGlPlayer.Role(ALeft, ARight: TGlPlayer): TGlPlayerRole;
begin
  if (ALeft.UID = 1) or (ARight.UID = 1) then
    Exit(roleNeutral);
  if (ALeft = ARight) then
    Exit(roleSelf)
  else
    Exit(roleEnemy);
end;

function TGlPlayer.Role(AVersus: TGlPlayer; AHideEnemy: Boolean = False): TGlPlayerRole;
begin
  Result := Role(Self, AVersus);
  if ((AHideEnemy) and (Result = roleEnemy)) then
    Result := roleNeutral;
end;

function TGlPlayer.IsRoleEnemy(ALeft, ARight: TGlPlayer): Boolean;
begin
  Result := Role(ALeft, ARight) = roleEnemy;
end;

function TGlPlayer.IsRoleEnemy(AVersus: TGlPlayer): Boolean;
begin
  Result := IsRoleEnemy(Self, AVersus);
end;

function TGlPlayer.IsRoleFriend(AVersus: TGlPlayer): Boolean;
begin
  Result := IsRoleFriend(Self, AVersus);
end;

function TGlPlayer.IsRoleFriend(ALeft, ARight: TGlPlayer): Boolean;
begin
  Result := Role(ALeft, ARight) in [roleSelf, roleFriends];
end;

procedure TGlPlayer.DoLoadHoldings();
var
  TmpPos: Integer;
begin
  with TDataAccess.Call('SHLoadHolding', [UID]) do
  try
    while ReadRow() do
    begin
      TmpPos := ReadInteger('POSITION');
      Storage.Storages[TmpPos].ResourceType := TGlSlotObjectType(ReadInteger('ID_TYPE'));
      Storage.Storages[TmpPos].Resource := TGlResourceType(ReadInteger('ID_ITEM'));
      Storage.Storages[TmpPos].Count := ReadInteger('COUNT');
    end;
  finally
    Free();
  end;
end;

{ TGlStorage }

constructor TGlStorage.Create();
var
  TmpI: Integer;
begin
  for TmpI := Low(TGlStorageList) to High(TGlStorageList) do
    FStorages[TmpI] := TGlStorageHolder.Create();
end;

destructor TGlStorage.Destroy();
var
  TmpI: Integer;
begin
  for TmpI := Low(TGlStorageList) to High(TGlStorageList) do
    FreeAndNil(FStorages[TmpI]);

  inherited;
end;

function TGlStorage.IncrementResource(AResource: TGlResourceType; ACount: Integer;
  ACallback: TGlStorageCallback; APlayer: TGlPlayer; AUseFreeSpace: Boolean = False): Integer;
var
  TmpMax: Integer;
  TmpI: Integer;
  TmpCount: Integer;
  TmpHolding: TGlStorageHolder;
begin
  Result := 0;
  TmpMax := TGlDictionaries.Resources[AResource].Max;
  for TmpI := 1 to APlayer.Storage.Size  do
  begin
    TmpHolding := Storages[TmpI];
    // ������ ��������� ����� ��� ����� ��� ����
    if ((AResource = TmpHolding.Resource) and (TmpHolding.Count < TmpMax))
      or ((AUseFreeSpace) and (TmpHolding.ResourceType = gsotEmpty)) then
    begin
      TmpCount := TmpMax - TmpHolding.Count;
      TmpCount := Min(TmpCount, ACount);
      Inc(TmpHolding.Count, TmpCount);
      Dec(ACount, TmpCount);
      Inc(Result, TmpCount);
      if (TmpHolding.ResourceType = gsotEmpty) then
      begin
        TmpHolding.Resource := AResource;
        TmpHolding.ResourceType := gsotResource;
      end;
      // �������� ��������� �� ���������� ���������
      ACallback(TmpI, TmpHolding, APlayer);
      // ���� ��� ������� �������, ������ ������ ������ �� �����
      if (ACount = 0) then
        Exit();
    end;
  end;
  // ����� ������� ������ ��������� �� ��������� ������
  if (not AUseFreeSpace) then
    Inc(Result, IncrementResource(AResource, ACount, ACallback, APlayer, True));
end;

function TGlStorage.IncrementResource(AResource: TGlResourceType; AIndex, ACount: Integer;
  ACallback: TGlStorageCallback; APlayer: TGlPlayer): Integer;
var
  TmpHolding: TGlStorageHolder;
  TmpMax: Integer;
begin
  TmpHolding := Storages[AIndex];
  TmpMax := TGlDictionaries.Resources[AResource].Max;
  // �� ������ ������ ��������� ��� � ������ ����� ����� ��� ���� �����
  if ((TmpHolding.Resource <> AResource) and (TmpHolding.ResourceType <> gsotEmpty))
    or (TmpHolding.Count > TmpMax)
  then
    Exit(0);

  Result := Min(TmpMax - TmpHolding.Count, ACount);
  TmpHolding.Resource := AResource;
  TmpHolding.Count := TmpHolding.Count + Result;
  TmpHolding.ResourceType := gsotResource;
  // �������� ��������� �� ���������� ���������
  ACallback(AIndex, TmpHolding, APlayer);
end;

procedure TGlStorage.DecrementResource(AIndex, ACount: Integer; ACallback: TGlStorageCallback;
  APlayer: TGlPlayer);
var
  TmpHolding: TGlStorageHolder;
begin
  TmpHolding := Storages[AIndex];
  // �������� �� ���������� ���������� ��������
  Dec(TmpHolding.Count, Min(TmpHolding.Count, ACount));
  if (TmpHolding.Count = 0) then
  begin
    TmpHolding.ResourceType := gsotEmpty;
    TmpHolding.Resource := resEmpty;
  end;
  // �������� ��������� �� ���������� ���������
  ACallback(AIndex, TmpHolding, APlayer);
end;

procedure TGlStorage.Exchange(ASourceIndex, ATargetIndex: Integer;
  ACallback: TGlStorageCallback; APlayer: TGlPlayer);
var
  TmpHolding: TGlStorageHolder;
begin
  TmpHolding := TGlStorageHolder.Create();
  try
    // �������� �������� �������� �����
    TmpHolding.Update(Storages[ATargetIndex]);
    // ������� ������� � �������� ���������
    Storages[ATargetIndex].Update(Storages[ASourceIndex]);
    ACallback(ATargetIndex, Storages[ATargetIndex], APlayer);
    // ������� �������� � �������� ���������
    Storages[ASourceIndex].Update(TmpHolding);
    ACallback(ASourceIndex, Storages[ASourceIndex], APlayer);
  finally
    FreeAndNil(TmpHolding);
  end;
end;

{$REGION 'TGlPlayerInfo' }

constructor TGlPlayerInfo.Create();
begin
  inherited Create();

  Reader := TTransportQueue.Create();
  Writer := TTransportQueue.Create();
end;

destructor TGlPlayerInfo.Destroy();
begin
  if (Assigned(Player)) then
    Player.Info := nil;

  FreeAndNil(Reader);
  FreeAndNil(Writer);

  inherited Destroy();
end;

{$ENDREGION}

end.
