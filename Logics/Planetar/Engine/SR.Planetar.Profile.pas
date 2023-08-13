{**********************************************}
{                                              }
{ ������ ���������� ����������� ��������       }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Planetar.Profile;

interface

uses
  System.SysUtils,

  SR.Engine.Server,
  SR.DataAccess,
  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.Planetar.Hangar,
  SR.Planetar.Dictionary;

type
  // ����� ���������� ����������� ��������
  TPlanetarProfile = class
  public var
    // ����� ��������� ��������
    Player: TGlPlayer;
    // ������ �� ���� ���������
    Main: TObject;
    // ������ �� ��������� ��������
    Subscribed: TObject;
    // ������ ����� ������� ������
    // ����������� ����� �������
    Hangar: TPlHangar;
    // ��������� ���� ������
    TechShipValues: TPLShipTechValues;
    // ������ �� ���� ���� ������
    TechShipProfile: PPLShipTechProfile;
    // ��������� ���� ��������
    TechBuildingValues: TPlBuildingTechValues;
    // ������ �� ���� ���� ������
    TechBuildingProfile: PPlBuildingTechProfile;
  private
    // �������� ���������� ����������
    procedure DoLoadTechWarShips();
    // �������� ���������� ��������
    procedure DoLoadTechBuildings();
    // �������� ������
    procedure DoLoadHangar();
  public
    constructor Create(APlayer: TGlPlayer);
    destructor Destroy(); override;
    // �������� �������
    procedure Start();
    // �������� �������
    procedure Stop();

    procedure Load();
    // ����������� ������� � ����������
    procedure Subscribe(APlanetarID: Integer); overload;
    // ����������� ������� � ����������
    procedure Subscribe(APlanetar: TObject = nil); overload;
    // ����������� ��������� � ����������
    procedure Connect();
    // ���������� ��������� �� ����������
    procedure Disconnect();
    // ������� ���������� ���������
    procedure BuyTech(AShipType: TPlShipType; ATech: TPlShipTechType; APlayer: TGlPlayer); overload;
    // ������� ���������� ��������
    procedure BuyTech(ABuildingType: TPlBuildingType; APlayer: TGlPlayer); overload;
    // ��������� ���������� ���������� ���������
    function TechShip(AShipType: TPlShipType; ATech: TPlShipTechType): Integer; overload;
    // ��������� ���������� ���������� ��������
    function TechBuilding(ABuildingType: TPlBuildingType; ATech: TPlBuildingTechType): Integer; overload;
  end;

implementation

uses
  SR.Planetar.Thread;

constructor TPlanetarProfile.Create(APlayer: TGlPlayer);
begin
  try
    inherited Create();
    // ������� ��������
    Player := APlayer;
    Hangar := TPlHangar.Create();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

destructor TPlanetarProfile.Destroy();
begin
  try
    FreeAndNil(Hangar);

    inherited Destroy();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.Start();
begin
  try
    Main := TPlanetarThread.Create(Player);
    if (not Player.IsBot) then
      Subscribe(Main);
    TPlanetarThread(Main).Start();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.Stop();
begin
  try
    TPlanetarThread(Main).Free();
    Main := nil;
    Subscribed := nil;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.Load();
begin
  DoLoadTechWarShips();
  DoLoadTechBuildings();
  DoLoadHangar();
end;

procedure TPlanetarProfile.DoLoadTechWarShips();
var
  TmpWarShip: TPlShipType;
  TmpTech: TPlShipTechType;
  TmpLevel: Integer;
  TmpCachedShip: TPlShipType;
  TmpCachedKeys: PPlShipTechKeys;
begin
  try
    TechShipProfile := @TPlanetarDictionary.ShipTechList[Player.Race];
    TmpCachedShip := pshtpEmpty;
    TmpCachedKeys := nil;
    // � ������ ������� ������������ ��� ����������� ������������
    with TDataAccess.Call('PLLoadDataTechShips', [Player.UID]) do
    try
      while ReadRow() do
      begin
        TmpWarShip := TPlShipType(ReadInteger('ID_OBJECT'));
        TmpTech := TPlShipTechType(ReadInteger('ID_TECH'));
        TmpLevel := ReadInteger('LEVEL');
        // ���������� ��������� �� ���� �������
        if (TmpWarShip <> TmpCachedShip) then
        begin
          TmpCachedShip := TmpWarShip;
          TmpCachedKeys := @TechShipValues[TmpWarShip];
        end;
        // ��������� ��������
        TmpCachedKeys[TmpTech] := TmpLevel;
      end;
    finally
      Free();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.DoLoadTechBuildings();
var
  TmpWarBuilding: TPlBuildingType;
  TmpTech: TPlBuildingTechType;
  TmpLevel: Integer;
  TmpCachedBuilding: TPlBuildingType;
  TmpCachedKeys: PPlBuildingTechKeys;
begin
  try
    TechBuildingProfile := @TPlanetarDictionary.BuildingTechList[Player.Race];
    TmpCachedBuilding := pbtEmpty;
    TmpCachedKeys := nil;
    // � ������ ������� ������������ ��� ����������� ������������
    with TDataAccess.Call('PLLoadDataTechBuildings', [Player.UID]) do
    try
      while ReadRow() do
      begin
        TmpWarBuilding := TPlBuildingType(ReadInteger('ID_OBJECT'));
        TmpTech := TPlBuildingTechType(ReadInteger('ID_TECH'));
        TmpLevel := ReadInteger('LEVEL');
        // ���������� ��������� �� ���� �������
        if (TmpWarBuilding <> TmpCachedBuilding) then
        begin
          TmpCachedBuilding := TmpWarBuilding;
          TmpCachedKeys := @TechBuildingValues[TmpWarBuilding];
        end;
        // ��������� ��������
        TmpCachedKeys[TmpTech] := TmpLevel;
      end;
    finally
      Free();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.DoLoadHangar();
var
  TmpID: Integer;
begin
  try
    { TODO -omdv : ������ � ���������� ��������� }
    Hangar.Size := 6;
    FillChar(Hangar.Slots, SizeOf(Hangar.Slots), 0);
    {}
    with TDataAccess.Call('PLLoadHangar', [Player.UID]) do
    try
      for TmpID := 0 to Hangar.Size do
      begin
        Hangar.Add(TmpID, ReadInteger('COUNT_' + IntToStr(TmpID)),
          TPlShipType(ReadInteger('ID_TYPE_' + IntToStr(TmpID))));
      end;
    finally
      Free();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlanetarProfile.TechBuilding(ABuildingType: TPlBuildingType;
  ATech: TPlBuildingTechType): Integer;
begin
  Result := 0;
  try
    Result := TechBuildingProfile[ABuildingType, ATech].Levels[TechBuildingValues[ABuildingType, ATech]];
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlanetarProfile.TechShip(AShipType: TPlShipType; ATech: TPlShipTechType): Integer;
begin
  Result := 0;
  try
    Result := TechShipProfile[AShipType, ATech].Levels[TechShipValues[AShipType, ATech]];
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.BuyTech(AShipType: TPlShipType; ATech: TPlShipTechType; APlayer: TGlPlayer);
var
  TmpProfile: TPLShipTechItem;
  TmpValue: PInteger;
begin
  try
    TmpProfile := TechShipProfile[AShipType, ATech];
    TmpValue := @TechShipValues[AShipType, ATech];
    // �������� ��� ���� ����� �������������
    if (TmpProfile.Count = TmpValue^) then
      Exit();
    // ��������� ����
    Inc(TmpValue^);
    // �������� ��������� �� �������� ��������
    TPlanetarThread(TPlanetarProfile(Player.PlanetarProfile).Subscribed).SocketWriter.PlayerTechWarShipUpdate(
      AShipType, ATech, APlayer);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.BuyTech(ABuildingType: TPlBuildingType; APlayer: TGlPlayer);
var
  TmpTech: TPlBuildingTechType;
  TmpInfo: TPlBuildingTechItem;
begin
  try
    TmpInfo := TPlanetarDictionary.BuildingTechList[APlayer.Race, ABuildingType, pttbActive];
    // �������� ��� ���� ����� �������������
    if (TechBuildingValues[ABuildingType, pttbActive] = TmpInfo.Count) then
      Exit();
    // ��������� ����
    for TmpTech := Low(TPlBuildingTechType) to High(TPlBuildingTechType) do
    begin
      TechBuildingValues[ABuildingType, TmpTech] := TechBuildingValues[ABuildingType, TmpTech] + 1;
    end;
    // �������� ��������� �� �������� ��������
    TPlanetarThread(TPlanetarProfile(Player.PlanetarProfile).Subscribed).SocketWriter.PlayerTechBuildingUpdate(
      ABuildingType, APlayer);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.Subscribe(APlanetar: TObject);
begin
  try
    if (not Assigned(APlanetar)) then
      APlanetar := Main;
    if TPlanetarThread(APlanetar).Subscribe(Player) then
      Subscribed := APlanetar;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.Subscribe(APlanetarID: Integer);
var
  TmpPlayer: TGlPlayer;
begin
  try
    // ������� ������ ���� �������
    TmpPlayer := TEngineServer.FindPlayer(APlanetarID);
    // ������� �������� �� ����� �������
    if (Assigned(TmpPlayer)) then
      Subscribe(TPlanetarProfile(TmpPlayer.PlanetarProfile).Main);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.Connect();
begin
  try
    TPlanetarThread(Subscribed).Connect(Player);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarProfile.Disconnect();
begin
  try
    if (Assigned(Subscribed)) then
    begin
      TPlanetarThread(Subscribed).Disconnect(Player);
      Subscribed := nil;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
