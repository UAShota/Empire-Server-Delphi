{**********************************************}
{                                              }
{ Модуль обработчика всех процессов планетарки }
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
  // Класс обработчика всех процессов планетарки
  TPlanetarThread = class(TThread)
  private var
    // Время последней работы
    FTickTime: Integer;
  public var
    // Признак доступности созвездия
    Available: Boolean;
    // Подключенные к созвездию клиенты
    Clients: TPlClientsDict;
    // Контроллер строений
    ControlBuildings: TPlanetarBuildingsController;
    // Контоллер планет
    ControlPlanets: TPlanetarPlanetsController;
    // Контроллер кораблей
    ControlShips: TPlanetarShipsController;
    // Контроллер хранилищ
    ControlStorages: TPlanetarStorageController;
    // Количество захваченных планет
    MannedCount: Integer;
    // Размер созвездия
    PlanetarSize: TSize;
    // Ссылка на глобальный объект игрока
    Player: TGlPlayer;
    // Сокет чтения
    SocketReader: TPlanetarSocketReader;
    // Сокет записи
    SocketWriter: TPlanetarSocketWriter;
    // Время активности пульсара
    TimePulsarActive: Integer;
    // Время активности ЧТ
    TimeWormholeActive: Integer;
    // Время открытия ЧТ
    TimeWormholeOpen: Integer;
    // Обработка корабликов
    WorkerShips: TPlanetarWorkerShips;
    // Обработка планет
    WorkerPlanets: TPlanetarWorkerPlanets;
  protected
    // Весь жизненный цикл идет внутри потока
    procedure Execute(); override;
  private
    // Загрузка параметров созвездия
    procedure DoLoadParams();
  public
    // Поток создается спящим
    constructor Create(APlayer: TGlPlayer); reintroduce;
    // Освобождение рабочих потоков
    destructor Destroy(); override;
    // Подписка на систему
    procedure Connect(APlayer: TGlPlayer);
    // Отписка от планеты
    procedure Disconnect(APlayer: TGlPlayer);

    function Subscribe(APlayer: TGlPlayer): Boolean;
  end;

implementation

constructor TPlanetarThread.Create(APlayer: TGlPlayer);
begin
  try
    inherited Create(True);
    // Сохраним ссылку игрока для быстрого доступа
    Player := APlayer;
    Clients := TPlClientsDict.Create();
    // Контроллеры
    ControlPlanets := TPlanetarPlanetsController.Create(Self);
    ControlShips := TPlanetarShipsController.Create(Self);
    ControlBuildings := TPlanetarBuildingsController.Create(Self);
    ControlStorages := TPlanetarStorageController.Create(Self);
    ControlShips := TPlanetarShipsController.Create(Self);
    // Сокеты чтения и записи
    SocketReader := TPlanetarSocketReader.Create(Self);
    SocketWriter := TPlanetarSocketWriter.Create(Self);
    // Обработчики ситуаций
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
    // Обработчики ситуаций
    FreeAndNil(WorkerShips);
    FreeAndNil(WorkerPlanets);
    // Контроллеры объектов
    FreeAndNil(ControlBuildings);
    FreeAndNil(ControlStorages);
    FreeAndNil(ControlPlanets);
    FreeAndNil(ControlShips);
    // Сокеты чтения и записи
    FreeAndNil(SocketReader);
    FreeAndNil(SocketWriter);
    // Очистим клиентов
    FreeAndNil(Clients);
    // Дефолт
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
    // Загрузка параметров созвездия
    DoLoadParams();
    // Контроллеры
    ControlPlanets.Start();
    ControlShips.Start();
    // Загрузка завершена
    Available := True;
    // Время загрузки
    TLogAccess.Write(ClassName, Format(' #%d ticks %d', [Player.UID, GetTickCount64() - TmpTime]));
    // Отправим игроку приглашение присоединиться
    if (not Player.IsBot) then
      SocketWriter.PlanetarActivated(Player);
    // Запускаем поток обработки
    while (not Terminated) do
    try
      GetLocalTime(TmpSystemTime);
      if (TmpSystemTime.wSecond <> FTickTime) then
      begin
        FTickTime := TmpSystemTime.wSecond;
        // Кораблики
        try
          WorkerShips.Work();
        except
          on E: Exception do
            TLogAccess.Write(E);
        end;
        // Планеты
        try
          WorkerPlanets.Work();
        except
          on E: Exception do
            TLogAccess.Write(E);
        end;
      end;
      // Сокетные команды
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
      // Ну, подождем
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
  // Профиль для передачи технологий
  TmpProfile := TPlanetarProfile(APlayer.PlanetarProfile);
  // Сообщим что готовы передать планетарные данные
  SocketWriter.SystemLoadBegin(APlayer);
  // Отправим данные пользователя
  SocketWriter.PlayerInfoUpdate(APlayer);
  // Отправим данные технологий корабликов
  SocketWriter.PlayerTechWarShipLoad(TmpProfile.TechShipProfile, TmpProfile.TechShipValues, APlayer);
  // Отправим данные технологий строений
  SocketWriter.PlayerTechBuildingLoad(TmpProfile.TechBuildingProfile, TmpProfile.TechBuildingValues, APlayer);
  // Отправим размер хранилища
  SocketWriter.PlayerStorageChange(APlayer.Storage.Size, APlayer.Storage.Storages, APlayer);
  // Отправим ангар
  for TmpI := 0 to TPlanetarProfile(APlayer.PlanetarProfile).Hangar.Size do
  begin
    SocketWriter.PlayerHangarUpdate(TmpI,
      TPlanetarProfile(APlayer.PlanetarProfile).Hangar.Slots[TmpI].Count,
      TPlanetarProfile(APlayer.PlanetarProfile).Hangar.Slots[TmpI].ShipType, APlayer);
  end;
  // Сообщим что передача готова
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
