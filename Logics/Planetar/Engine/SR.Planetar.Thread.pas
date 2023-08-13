{**********************************************}
{                                              }
{ ������ ����������� ���� ��������� ���������� }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev A  2016.12.14                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Planetar.Thread;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Classes,

  SR.DataAccess,
  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.Planetar.Profile,
  SR.Planetar.Socket.Reader,
  SR.Planetar.Socket.Writer,
  SR.Planetar.Worker.Ships,
  SR.Planetar.Worker.Planet,
  SR.Planetar.Controller.Buildings,
  SR.Planetar.Controller.Storage,
  SR.Planetar.Controller.Ships,
  SR.Planetar.Controller.Planets;

type
  // ����� ����������� ���� ��������� ����������
  TPlanetarThread = class(TThread)
  private var
    // ����� ��������� ������
    FTickTime: Integer;
  public var
    // ������� ����������� ���������
    Available: Boolean;
    // ������������ � ��������� �������
    Clients: TPlClientsDict;
    // ���������� ��������
    ControlBuildings: TPlanetarBuildingsController;
    // ��������� ������
    ControlPlanets: TPlanetarPlanetsController;
    // ���������� ��������
    ControlShips: TPlanetarShipsController;
    // ���������� ��������
    ControlStorages: TPlanetarStorageController;
    // ���������� ����������� ������
    MannedCount: Integer;
    // ������ ���������
    PlanetarSize: TSize;
    // ������ �� ���������� ������ ������
    Player: TGlPlayer;
    // ����� ������
    SocketReader: TPlanetarSocketReader;
    // ����� ������
    SocketWriter: TPlanetarSocketWriter;
    // ����� ���������� ��������
    TimePulsarActive: Integer;
    // ����� ���������� ��
    TimeWormholeActive: Integer;
    // ����� �������� ��
    TimeWormholeOpen: Integer;
    // ��������� ����������
    WorkerShips: TPlanetarWorkerShips;
    // ��������� ������
    WorkerPlanets: TPlanetarWorkerPlanets;
  protected
    // ���� ��������� ���� ���� ������ ������
    procedure Execute(); override;
  private
    // �������� ���������� ���������
    procedure DoLoadParams();
  public
    // ����� ��������� ������
    constructor Create(APlayer: TGlPlayer); reintroduce;
    // ������������ ������� �������
    destructor Destroy(); override;
    // �������� �� �������
    procedure Connect(APlayer: TGlPlayer);
    // ������� �� �������
    procedure Disconnect(APlayer: TGlPlayer);

    function Subscribe(APlayer: TGlPlayer): Boolean;
  end;

implementation

constructor TPlanetarThread.Create(APlayer: TGlPlayer);
begin
  try
    inherited Create(True);
    // �������� ������ ������ ��� �������� �������
    Player := APlayer;
    Clients := TPlClientsDict.Create();
    // �����������
    ControlPlanets := TPlanetarPlanetsController.Create(Self);
    ControlShips := TPlanetarShipsController.Create(Self);
    ControlBuildings := TPlanetarBuildingsController.Create(Self);
    ControlStorages := TPlanetarStorageController.Create(Self);
    ControlShips := TPlanetarShipsController.Create(Self);
    // ������ ������ � ������
    SocketReader := TPlanetarSocketReader.Create(Self);
    SocketWriter := TPlanetarSocketWriter.Create(Self);
    // ����������� ��������
    WorkerShips := TPlanetarWorkerShips.Create(Self);
    WorkerPlanets := TPlanetarWorkerPlanets.Create(Self);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

destructor TPlanetarThread.Destroy();
begin
  try
    // ����������� ��������
    FreeAndNil(WorkerShips);
    FreeAndNil(WorkerPlanets);
    // ����������� ��������
    FreeAndNil(ControlBuildings);
    FreeAndNil(ControlStorages);
    FreeAndNil(ControlPlanets);
    FreeAndNil(ControlShips);
    // ������ ������ � ������
    FreeAndNil(SocketReader);
    FreeAndNil(SocketWriter);
    // ������� ��������
    FreeAndNil(Clients);
    // ������
    inherited Destroy();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarThread.DoLoadParams();
begin
  try
    with TDataAccess.Call('PLLoadPlanetar', [Player.UID]) do
    try
      PlanetarSize.Width := ReadInteger('WIDTH');
      PlanetarSize.Height := ReadInteger('HEIGHT');
      TimeWormholeOpen := ReadInteger('WORMHOLE_TIME_OPEN');
      TimeWormholeActive := ReadInteger('WORMHOLE_TIME_ACTIVE');
      TimePulsarActive := ReadInteger('PULSAR_TIME_ACTIVE');
    finally
      Free();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarThread.Execute();
var
  TmpSystemTime: TSystemTime;
  TmpTime: UInt64;
begin
  try
    TmpTime := GetTickCount64();
    // �������� ���������� ���������
    DoLoadParams();
    // �����������
    ControlPlanets.Start();
    ControlShips.Start();
    // �������� ���������
    Available := True;
    // ����� ��������
    TLogAccess.Write(ClassName, Format(' #%d ticks %d', [Player.UID, GetTickCount64() - TmpTime]));
    // �������� ������ ����������� ��������������
    if (not Player.IsBot) then
      SocketWriter.PlanetarActivated(Player);
    // ��������� ����� ���������
    while (not Terminated) do
    try
      GetLocalTime(TmpSystemTime);
      if (TmpSystemTime.wSecond <> FTickTime) then
      begin
        FTickTime := TmpSystemTime.wSecond;
        // ���������
        try
          WorkerShips.Work();
        except
          on E: Exception do
            TLogAccess.Write(E);
        end;
        // �������
        try
          WorkerPlanets.Work();
        except
          on E: Exception do
            TLogAccess.Write(E);
        end;
      end;
      // �������� �������
      try
        TMonitor.Enter(Clients);
        try
          SocketReader.Work();
          SocketWriter.Work();
        finally
          TMonitor.Exit(Clients);
        end;
      except
        on E: Exception do
          TLogAccess.Write(E);
      end;
      // ��, ��������
      WaitForSingleObject(Handle, 1);
    except
      on E: Exception do
        TLogAccess.Write(E);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlanetarThread.Subscribe(APlayer: TGlPlayer): Boolean;
begin
  Result := Available;
  SocketWriter.Subscribe(APlayer, Result);
end;

procedure TPlanetarThread.Connect(APlayer: TGlPlayer);
var
  TmpI: Integer;
  TmpProfile: TPlanetarProfile;
begin
  TMonitor.Enter(Clients);
  try
    Clients.Add(APlayer, TPlPlanetList.Create());
  finally
    TMonitor.Exit(Clients);
  end;
  // ������� ��� �������� ����������
  TmpProfile := TPlanetarProfile(APlayer.PlanetarProfile);
  // ������� ��� ������ �������� ����������� ������
  SocketWriter.SystemLoadBegin(APlayer);
  // �������� ������ ������������
  SocketWriter.PlayerInfoUpdate(APlayer);
  // �������� ������ ���������� ����������
  SocketWriter.PlayerTechWarShipLoad(TmpProfile.TechShipProfile, TmpProfile.TechShipValues, APlayer);
  // �������� ������ ���������� ��������
  SocketWriter.PlayerTechBuildingLoad(TmpProfile.TechBuildingProfile, TmpProfile.TechBuildingValues, APlayer);
  // �������� ������ ���������
  SocketWriter.PlayerStorageChange(APlayer.Storage.Size, APlayer.Storage.Storages, APlayer);
  // �������� �����
  for TmpI := 0 to TPlanetarProfile(APlayer.PlanetarProfile).Hangar.Size do
  begin
    SocketWriter.PlayerHangarUpdate(TmpI,
      TPlanetarProfile(APlayer.PlanetarProfile).Hangar.Slots[TmpI].Count,
      TPlanetarProfile(APlayer.PlanetarProfile).Hangar.Slots[TmpI].ShipType, APlayer);
  end;
  // ������� ��� �������� ������
  SocketWriter.SystemLoadEnd(APlayer);
end;

procedure TPlanetarThread.Disconnect(APlayer: TGlPlayer);
var
  TmpPlanetList: TPlPlanetList;
begin
  TMonitor.Enter(Clients);
  try
    if Clients.TryGetValue(APlayer, TmpPlanetList) then
    begin
      FreeAndNil(TmpPlanetList);
      Clients.Remove(APlayer);
    end;
  finally
    TMonitor.Exit(Clients);
  end;
end;

end.
