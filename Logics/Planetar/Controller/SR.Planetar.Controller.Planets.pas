{**********************************************}
{                                              }
{ Модуль управления планетами                  }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev B  2017.03.31                            }
{ Rev C  2017.10.27                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Planetar.Controller.Planets;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  System.Generics.Collections,

  SR.DataAccess,
  SR.Engine.Server,
  SR.Globals.Log,
  SR.Globals.Types,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.Planetar.Custom,

  SR.PL.Planets.Battle,
  SR.PL.Planets.Capture,
  SR.PL.Planets.Pulsar,
  SR.PL.Planets.Wormhole;

type
  // Класс управления планетами
  TPlanetarPlanetsController = class(TPlanetarCustom)
  private type
    // Сектор игрока
    PPlSector = ^TPlSector;
    TPlSector = class
      X: Integer;
      Y: Integer;
      Planets: TPlPlanetList;
    end;
    // Матрица секторов
    TPlSectorMatrix = array of array of TPlSector;
  private var
    // Идентификатор последней обработанной планеты
    FCachePlanetID: Integer;
    // Объект последней обработанной планеты
    FCachePlanet: TPlPlanet;
    // Матрица секторов созвездия
    FSectorMatrix: TPlSectorMatrix;
  public var
    // Боевка
    Battle: TPLPlanetsControlBattle;
    // Захват
    Capture: TPLPlanetsControlCapture;
    // Боевка
    Pulsar: TPLPlanetsControlPulsar;
    // Черная дыра
    Wormhole: TPLPlanetsControlWormhole;
    // Планеты
    ListPlanets: TPlPlanetList;
  private
    // Загрузка данных системы
    procedure DoLoadPlanetData();
    // Загрузка секторов
    procedure DoLoadPlanetLinks();
    // Наличие дружелюбного порталера
    function GetFriendlyPortalerPresent(APlanet: TPlPlanet; AOwner: TGlPlayer): Boolean;
    // Наличие вражеского покрытия
    function GetCoverageByEnemy(APlanet: TPlPlanet; APlayer: TGlPlayer): Boolean;
    // Пересчет складов
    procedure DoUpdateShipStorages(AShip: TPlShip; ACount: Integer);
    // Пересчет научек
    procedure DoUpdateShipPortalers(AShip: TPlShip; ACount: Integer);
    // Обновление списка наличия кораблей определенного типа на орбите
    function DoUpdateShipList(AList: TPlShipsCountDict; AShip: TPlShip; ACount: Integer): Integer;
    // Обновление видимости планетоида
    procedure DoPlayerVisibilityChange(APlanet: TPlPlanet; APlayer: TGlPlayer; AHardLight, AIncrement: Boolean);
    // Обновление карты покрытия
    procedure DoPlayerCoverageChange(APlanet: TPlPlanet; APlayer: TGlPlayer; AIncrement: Boolean);
  public
    // Инициализация
    constructor Create(AEngine: TObject); override;
    // Финализация
    destructor Destroy(); override;
    // Загрузка данных
    procedure Start(); override;
    // Получение планеты по ее номеру в списке
    function PlanetByID(AID: Integer): TPlPlanet;
    // Получение планеты по ее индексу в базу
    function PlanetByRaw(AUID: Integer): TPlPlanet;
    // Смена торгоого пути планеты
    procedure ChangeTradePath(ASource, ADestination: TPlPlanet; APlayer: TGlPlayer);
    // Открытие портала планеты
    procedure OpenPortal(ASource: TPlShip; ATarget: TPlPlanet; APlayer: TGlPlayer); overload;
    // Открытие портала планеты
    procedure OpenPortal(ASource, ATarget: TPlPlanet; ABreakable, AFastTransfer: Boolean;
      AOwner: TGlPlayer = nil; ALimit: Integer = -1); overload;
    // Закрытие портала планеты
    procedure ClosePortal(APlanet: TPlPlanet); overload;
    // Закрытие портала планеты
    procedure ClosePortal(APlanet: TPlPlanet; APlayer: TGlPlayer); overload;
    // Отправка планеты на переприцеливание
    procedure Retarget(AShip: TPlShip; ACheckBattle: Boolean); overload;
    // Обновление параметров планеты в зависимости от наличия юнитов
    procedure UpdateShipList(AShip: TPlShip; ACount: Integer);
    // Отправка деталей планеты
    procedure ShowDetails(APlanet: TPlPlanet; APlayer: TGlPlayer);
    // Подписка на действия на планете
    procedure Subscribe(APlanet: TPlPlanet; APlayer: TGlPlayer);
    // Обновление карты контроля
    procedure PlayerControlChange(APlanet: TPlPlanet; APlayer: TGlPlayer; AIncrement, AOnlyCurrent: Boolean);
  end;

implementation

uses
  SR.Planetar.Thread;

constructor TPlanetarPlanetsController.Create(AEngine: TObject);
begin
  inherited Create(AEngine);

  ListPlanets := TPlPlanetList.Create();

  Battle := TPLPlanetsControlBattle.Create(AEngine);
  Capture := TPLPlanetsControlCapture.Create(AEngine);
  Pulsar := TPLPlanetsControlPulsar.Create(AEngine);
  Wormhole := TPLPlanetsControlWormhole.Create(AEngine);
end;

destructor TPlanetarPlanetsController.Destroy();
begin
  FreeAndNil(ListPlanets);

  FreeAndNil(Wormhole);
  FreeAndNil(Pulsar);
  FreeAndNil(Capture);
  FreeAndNil(Battle);

  inherited Destroy();
end;

procedure TPlanetarPlanetsController.Start();
begin
  // Инициализируем массив секторов
  SetLength(FSectorMatrix,
    TPlanetarThread(Engine).PlanetarSize.Width, TPlanetarThread(Engine).PlanetarSize.Height);
  // Загрузим данные планеты
  DoLoadPlanetData();
  // Загрузим ссылки между ними
  DoLoadPlanetLinks();
end;

function TPlanetarPlanetsController.GetFriendlyPortalerPresent(APlanet: TPlPlanet;
  AOwner: TGlPlayer): Boolean;
var
  TmpShip: TPlShip;
begin
  Result := False;
  try
    // Ищем союзные порталеры
    for TmpShip in APlanet.Ships do
    begin
      if (TmpShip.TechActive(plttStablePortal))
        and (AOwner.IsRoleFriend(TmpShip.Owner))
      then
        Exit(True);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlanetarPlanetsController.PlanetByID(AID: Integer): TPlPlanet;
begin
  // Проверим на границы
  if (AID < 0)
    or (AID >= ListPlanets.Count)
  then
    Exit(nil)
  else
    Result := ListPlanets[AID];
end;

function TPlanetarPlanetsController.PlanetByRaw(AUID: Integer): TPlPlanet;
var
  TmpStart: Integer;
  TmpEnd: Integer;
  TmpI: Integer;
  TmpPlanet: TPlPlanet;
begin
  Result := nil;
  // Проверим на кэш
  if (FCachePlanetID = AUID) then
    Exit(FCachePlanet);
  // Выставим границы
  TmpStart := 0;
  TmpEnd := Pred(ListPlanets.Count);
  // переберем весь список
  while (Result = nil) do
  begin
    // В отладку если не найдена
    if (TmpStart = TmpEnd) then
      raise Exception.Create('Wrong planet UID ' + IntToStr(AUID) + ' in ' + IntToStr(TPlanetarThread(Engine).Player.UID));
    // Определим границы
    TmpI := TmpStart + (TmpEnd - TmpStart) div 2;
    TmpPlanet := ListPlanets[TmpI];
    // Планета найдена
    if (TmpPlanet.UID = AUID) then
      Result := TmpPlanet
    else
    // Планета ниже
    if (TmpPlanet.UID > AUID) then
      TmpEnd := TmpI
    // Планета выше
    else
      TmpStart := TmpI;
  end;
end;

procedure TPlanetarPlanetsController.DoLoadPlanetData();
var
  TmpPlanet: TPlPlanet;
  TmpSectorX: Integer;
  TmpSectorY: Integer;
  TmpSector: PPlSector;
begin
  with TDataAccess.Call('PLLoadPlanets', [TPlanetarThread(Engine).Player.UID]) do
  try
    while ReadRow do
    begin
      TmpPlanet := TPlPlanet.Create();
      // Загрузка данных с БД
      TmpPlanet.UID := ReadInteger('UID');
      TmpPlanet.ID := ListPlanets.Count;
      TmpPlanet.Owner := TEngineServer.FindPlayer(ReadInteger('ID_OWNER'));
      TmpPlanet.Name := ReadString('NAME');
      TmpPlanet.CoordX := ReadInteger('COORD_X');
      TmpPlanet.CoordY := ReadInteger('COORD_Y');
      TmpPlanet.PlanetType := TPlanetType(ReadInteger('ID_PLANET_TYPE') - 1);
      TmpPlanet.ResFactory := TGlResourceType(ReadInteger('ID_RESOURCE'));
      TmpPlanet.StateTime := ReadInteger('TIME_STATE');
      TmpPlanet.State := TPlPlanetState(ReadInteger('ID_STATE'));
      // Всякие объекты
      TmpPlanet.Storages := TPlStorages.Create();
      TmpPlanet.StoragesFree := TIntegerList.Create();
      TmpPlanet.StoragesInactive := TIntegerList.Create();
      TmpPlanet.Ships := TPlShipList.Create();
      TmpPlanet.Constructors := TPlShipsCountDict.Create();
      TmpPlanet.ShipCount := TPlShipsCountDict.Create();
      TmpPlanet.RangeAttackers := TPlShipList.Create();
      TmpPlanet.ResPathIn := TPlPlanetList.Create();
      (*      TmpPlanet.Buildings := TPlBuildingDict.Create();*)
      TmpPlanet.Links := TPlPlanetList.Create();
      TmpPlanet.PlayerLightSoft := TPlShipsCountDict.Create();
      TmpPlanet.PlayerLightHard := TPlShipsCountDict.Create();
      TmpPlanet.PlayerCoverage := TPlShipsCountDict.Create();
      // Стартовый уровень
      TmpPlanet.Level := 10;
      // Стартовая топка
      TmpPlanet.Fuel := 30;
      // По типу планеты добавки
      case TmpPlanet.PlanetType of
        pltSmall, pltBig:
        begin
          // Доп хранилище
          TPlanetarThread(Engine).ControlStorages.ChangeStorageCount(TmpPlanet, 1, False);
          // Имя для подконтрольной планеты
          if (TmpPlanet.Owner.UID > 1) then
            TmpPlanet.Name := TmpPlanet.Owner.Name;
        end;
     (*   pltHole:
          Wormhole.Execute(TmpPlanet);
        pltPulsar:
          Pulsar.Execute(TmpPlanet);*)
      end;
      ListPlanets.Add(TmpPlanet);
      // Включим сектор обитания
      TmpSectorX := ReadInteger('POS_X');
      TmpSectorY := ReadInteger('POS_Y');
      TmpSector := @FSectorMatrix[TmpSectorX, TmpSectorY];
      if (not Assigned(TmpSector^)) then
      begin
        TmpSector^ := TPlSector.Create();
        TmpSector.Planets := TPlPlanetList.Create();
        TmpSector.X := TmpSectorX;
        TmpSector.Y := TmpSectorY;
      end;
      TmpSector.Planets.Add(TmpPlanet);

      (*      if (TmpPlanet.Owner = TPlanetarThread(Engine).Player) then
      Inc(FCapturedColonyCount);*)
    end;
  finally
    Free();
  end;
end;

procedure TPlanetarPlanetsController.DoLoadPlanetLinks();
var
  TmpSectorFrom: TPlSector;
  TmpSectorTo: TPlSector;
  TmpPlanetFrom: TPlPlanet;
  TmpPlanetTo: TPlPlanet;
  TmpSectorX: Integer;
  TmpSectorY: Integer;
  TmpX: Integer;
  TmpY: Integer;
begin
  // Переберем массив секторов
  for TmpSectorY := 0 to Pred(TPlanetarThread(Engine).PlanetarSize.Height) do
  begin
    // Переберем столбцы
    for TmpSectorX := 0 to Pred(TPlanetarThread(Engine).PlanetarSize.Width) do
    begin
      // Пропустим пустые сектора
      TmpSectorFrom := FSectorMatrix[TmpSectorX, TmpSectorY];
      if (not Assigned(TmpSectorFrom)) then
        Continue;
      // Найдем соединение с планетами своего сектора
      for TmpPlanetFrom in TmpSectorFrom.Planets do
      begin
        for TmpPlanetTo in TmpSectorFrom.Planets do
          if (TmpPlanetFrom <> TmpPlanetTo) then
            TmpPlanetFrom.Links.Add(TmpPlanetTo);
      end;
      // Переберем соседние сектора
      for TmpX := -1 to 1 do
        for TmpY := -1 to 1 do
      begin
        // Отсечем выход за пределы, игнорируем ссылку сам на себя 0 -> 0
        if ((TmpX = 0) and (TmpY = 0))
          or (TmpSectorFrom.X + TmpX < 0)
          or (TmpSectorFrom.Y + TmpY < 0)
          or (TmpSectorFrom.X + TmpX = TPlanetarThread(Engine).PlanetarSize.Width)
          or (TmpSectorFrom.Y + TmpY = TPlanetarThread(Engine).PlanetarSize.Height)
        then
          Continue;
        // Найдем таргетный сектор
        TmpSectorTo := FSectorMatrix[TmpSectorFrom.X + TmpX, TmpSectorFrom.Y + TmpY];
        if (not Assigned(TmpSectorTo)) then
          Continue;
        // Найдем соединение с соседними секторами
        for TmpPlanetFrom in TmpSectorFrom.Planets do
        begin
          for TmpPlanetTo in TmpSectorTo.Planets do
            if TmpPlanetFrom.IsValidDistance(TmpPlanetTo) then
              TmpPlanetFrom.Links.Add(TmpPlanetTo);
        end;
      end;
    end;
  end;
end;

function TPlanetarPlanetsController.DoUpdateShipList(AList: TPlShipsCountDict; AShip: TPlShip;
  ACount: Integer): Integer;
var
  TmpResult: TPlShipsCount;
  TmpFound: Boolean;
begin
  Result := 0;
  try
    // Найдем количество флота для указанного владельца
    TmpFound := AList.TryGetValue(AShip.Owner, TmpResult);
    if (not TmpFound) then
      TmpResult.Value := 0;
    // Изменим количество
    Inc(TmpResult.Value, ACount);
    // Если кораблик удаляется
    if (ACount < 0) then
    begin
      // Если улетает последний кораблик владельца, почистить ресурсы
      if (TmpResult.Value = 0) then
        AList.Remove(AShip.Owner)
      else
        AList[AShip.Owner] := TmpResult
    end else
    begin
      // Если прилетает новый кораблик - добавить об этом запись
      if (not TmpFound) then
        AList.Add(AShip.Owner, TmpResult)
      else
        AList[AShip.Owner] := TmpResult;
    end;
    // Вернем
    Result := TmpResult.Value;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.DoUpdateShipStorages(AShip: TPlShip; ACount: Integer);
begin
  (*обновить экономику*)
  try
    // Для сервиски также обновляем количество складов
    TPlanetarThread(Engine).ControlStorages.ChangeStorageCount(AShip.Planet, ACount, True);
    // Пересчитаем производ. т.к. сервиска может вырабатывать газ
(*    TPlanetarThread(Engine).WorkerProduction.CalculateProduction(AShip.Planet);*)
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.DoUpdateShipPortalers(AShip: TPlShip; ACount: Integer);
begin
  try
    // Если юнит удаляется - смотрим, есть ли еще такие
    if (ACount < 0)
      and (Assigned(AShip.Planet.Portal))
      and (not GetFriendlyPortalerPresent(AShip.Planet, AShip.Owner))
    then
      ClosePortal(AShip.Planet, AShip.Planet.Portal.Owner);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.DoPlayerCoverageChange(APlanet: TPlPlanet; APlayer: TGlPlayer;
  AIncrement: Boolean);
var
  TmpCount: TPlShipsCount;
begin
  try
    // Локальные или ЧТ не имеют контроля
    if (APlayer.UID = 1)
      or (APlanet.PlanetType = pltHole)
    then
      Exit();
    // Проверим его наличие
    if (not APlanet.PlayerCoverage.TryGetValue(APlayer, TmpCount)) then
      TmpCount.Value := 0;
    // Увеличим счетчик или добавим новый
    if (AIncrement) then
    begin
      Inc(TmpCount.Value);
      if (TmpCount.Value = 1) then
      begin
        APlanet.PlayerCoverage.Add(APlayer, TmpCount);
        TPlanetarThread(Engine).SocketWriter.PlanetCoverageUpdate(APlanet, APlayer, True);
        Exit();
      end
    end else
    // Уменьшим счетчик или удалим пустой
    begin
      Dec(TmpCount.Value);
      if (TmpCount.Value = 0) then
      begin
        APlanet.PlayerCoverage.Remove(APlayer);
        TPlanetarThread(Engine).SocketWriter.PlanetCoverageUpdate(APlanet, APlayer, False);
        Exit();
      end
    end;
    // Если данные уже есть, то просто обновим
    APlanet.PlayerCoverage[APlayer] := TmpCount;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.DoPlayerVisibilityChange(APlanet: TPlPlanet; APlayer: TGlPlayer;
  AHardLight, AIncrement: Boolean);
var
  TmpDict: TPlShipsCountDict;
  TmpCount: TPlShipsCount;
begin
  try
    // Локальные не имеют контроля
    if (APlayer.UID = 1) then
      Exit();
    // Выберем тип списка
    if (AHardLight) then
      TmpDict := APlanet.PlayerLightHard
    else
      TmpDict := APlanet.PlayerLightSoft;
    // Проверим его наличие
    if (not TmpDict.TryGetValue(APlayer, TmpCount)) then
      TmpCount.Value := 0;
    // Увеличим счетчик или добавим новый
    if (AIncrement) then
    begin
      Inc(TmpCount.Value);
      if (TmpCount.Value = 1) then
      begin
        TmpDict.Add(APlayer, TmpCount);
        TPlanetarThread(Engine).SocketWriter.PlanetVisibilityUpdate(APlanet, APlayer, AHardLight, True);
        Exit();
      end
    end else
    // Уменьшим счетчик или удалим пустой
    begin
      Dec(TmpCount.Value);
      if (TmpCount.Value = 0) then
      begin
        TmpDict.Remove(APlayer);
        TPlanetarThread(Engine).SocketWriter.PlanetVisibilityUpdate(APlanet, APlayer, AHardLight, False);
        Exit();
      end;
    end;
    // Если данные уже есть, то просто обновим
    TmpDict[APlayer] := TmpCount;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.UpdateShipList(AShip: TPlShip; ACount: Integer);
begin
  try
    if (AShip.TechActive(plttFix)) then
      DoUpdateShipList(AShip.Planet.Constructors, AShip, ACount)
    else
    if (AShip.TechActive(plttStablePortal)) then
      DoUpdateShipPortalers(AShip, ACount)
    else
    if (AShip.TechActive(plttStorage)) then
      DoUpdateShipStorages(AShip, ACount);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.OpenPortal(ASource, ATarget: TPlPlanet;
  ABreakable, AFastTransfer: Boolean; AOwner: TGlPlayer; ALimit: Integer);
var
  TmpPortal: TPlPortal;
begin
  try
    // Создадим безлимитный портал
    TmpPortal := TPlPortal.Create();
    TmpPortal.Enter := ASource;
    TmpPortal.Exit := ATarget;
    TmpPortal.Limit := ALimit;
    TmpPortal.Breakable := ABreakable;
    TmpPortal.FastTransfer := AFastTransfer;
    TmpPortal.Owner := AOwner;
    // Применим к планете
    ASource.Portal := TmpPortal;
    ATarget.Portal := TmpPortal;
    // Отправим сообщение о создании портала между планетами
    TPlanetarThread(Engine).SocketWriter.PlanetPortalOpen(ASource, ATarget, True, AOwner);
    TPlanetarThread(Engine).SocketWriter.PlanetPortalOpen(ATarget, ASource, False, AOwner);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.OpenPortal(ASource: TPlShip; ATarget: TPlPlanet; APlayer: TGlPlayer);
begin
  try
    // Нельзя кидать порталы на самого себя, на чт, на врагов и без научки
    if (ATarget.PlanetType = pltHole)
      or (ASource.Planet.PlanetType = pltHole)
      or (ASource.Planet = ATarget)
      or (Assigned(ASource.Planet.Portal))
      or (Assigned(ATarget.Portal))
      or (not ASource.TechActive(plttStablePortal))
      or (not APlayer.IsRoleFriend(ASource.Owner))
      or (not GetFriendlyPortalerPresent(ATarget, ASource.Owner)) then
    begin
      WriteLn('Wrong ship portal');
      Exit();
    end;
    // Построим планетарный портал
    OpenPortal(ASource.Planet, ATarget, True, False, ASource.Owner);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.ClosePortal(APlanet: TPlPlanet);
var
  TmpShip: TPlShip;
begin
  try
    // Отправим сообщение о закрытии портала между планетами
    TPlanetarThread(Engine).SocketWriter.PlanetPortalClose(APlanet);
    // Удалим из памяти если это закрытие последнего портала
    if (APlanet = APlanet.Portal.Exit) then
      FreeAndNil(APlanet.Portal)
    else
      APlanet.Portal := nil;
    // Отменим порталинг юнитов
    for TmpShip in APlanet.Ships do
    begin
      if (TmpShip.State = pshstPortalJump) then
      begin
        TPlanetarThread(Engine).WorkerShips.TimerRemove(TmpShip, pshtmOpPortalJump);
        TPlanetarThread(Engine).ControlShips.StandUp.Execute(TmpShip, True, False);
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.ClosePortal(APlanet: TPlPlanet; APlayer: TGlPlayer);
var
  TmpPortal: TPlPortal;
begin
  try
    // Нельзя закрыть неоткрытый, не свой портал или бчт портал
    if (not Assigned(APlanet.Portal))
      or (not Assigned(APlanet.Portal.Owner))
      or (not APlanet.Portal.Owner.IsRoleFriend(APlayer)) then
    begin
      Writeln('Wrong close portal');
      Exit();
    end;
    // Выявим портал
    TmpPortal := APlanet.Portal;
    // Закрываем вход портала
    ClosePortal(TmpPortal.Enter);
    // Закрываем выход портала
    ClosePortal(TmpPortal.Exit);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlanetarPlanetsController.GetCoverageByEnemy(APlanet: TPlPlanet; APlayer: TGlPlayer): Boolean;
var
  TmpPlayer: TGlPlayer;
begin
  // Поищем первого попавшегося врага
  for TmpPlayer in APlanet.PlayerCoverage.Keys do
  begin
    if (TmpPlayer.Role(APlayer, tmpPlayer) = roleEnemy) then
      Exit(True);
  end;
  Result := False;
end;

procedure TPlanetarPlanetsController.ChangeTradePath(ASource, ADestination: TPlPlanet;
  APlayer: TGlPlayer);
begin
  try
    // Проверим исходную планету
    if (ASource.PlanetType = pltHole)
      or (ASource = ADestination)
      or (GetCoverageByEnemy(ASource, APlayer))
      or (not ASource.VisibleByPlayer(APlayer)) then
    begin
      WriteLn('Wrong change trade path source');
      Exit();
    end;
    // Проверим таргетную планету
    if (Assigned(ADestination)) then
    begin
      if (ADestination.PlanetType = pltHole)
        or (not ADestination.Links.Contains(ASource))
        or (GetCoverageByEnemy(ADestination, APlayer))
        or (not ADestination.VisibleByPlayer(APlayer))
        then
      begin
        WriteLn('Wrong change trade path destination');
        Exit();
      end;
    end;
    // Повторная установка убирает путь
    if (ASource.ResPathOut = ADestination) then
      ASource.ResPathOut := nil
    else
      ASource.ResPathOut := ADestination;
    // Отправим сообщение
    TPlanetarThread(Engine).SocketWriter.PlanetTradePathUpdate(ASource);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.Retarget(AShip: TPlShip; ACheckBattle: Boolean);
begin
  try
(* непонятно нужн ли
    // Переприцелим планету ранжевой атаки
    if (AShip.IsAttachedRange(True)) then
      AShip.Attached.IsRetarget := AShip.Attached.Timer[ppltmBattle]; *)
    // Планета уже в бою или ЧТ
    if (AShip.Planet.IsRetarget)
      or (AShip.Planet.PlanetType = pltHole)
    then
      Exit();
    // Включим переприцел
    if (ACheckBattle or AShip.Planet.Timer[ppltmBattle]) then
    begin
      AShip.Planet.IsRetarget := True;
      if (not AShip.Planet.Timer[ppltmBattle]) then
        TPlanetarThread(Engine).ControlPlanets.Battle.Execute(AShip.Planet);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.Subscribe(APlanet: TPlPlanet; APlayer: TGlPlayer);
var
  TmpShip: TPlShip;
  TmpWeapon: TPlShipWeaponType;
begin
  try
    // Нельзя подписаться на неактивную, уже подписанную или невидимую игроку планету
    if (APlanet.State = plsInactive)
      or (not TPlanetarThread(Engine).SocketWriter.PlanetSubscribe(APlayer, APlanet))
      or (not APlanet.VisibleByPlayer(APlayer)) then
    begin
      Writeln('Wrong subscribe hole ', APlanet.IsBigHole,'  ID: ', APlanet.ID, ' state ', Integer(APlanet.State), ' visible ', APlanet.VisibleByPlayer(APlayer));
      Exit();
    end;
    // Отправим сообщение о текущем состоянии
    TPlanetarThread(Engine).SocketWriter.PlanetStateUpdate(APlanet, APlayer);
    // Отправим сообщение о владельце
    TPlanetarThread(Engine).SocketWriter.PlanetOwnerChanged(APlanet, APlayer);
    // Отправим пользователю данные о флоте, чтобы потом можно было выбрать цель
    for TmpShip in APlanet.Ships do
      TPlanetarThread(Engine).SocketWriter.ShipCreate(TmpShip, APlayer);
    // Отправим прицеливание корабликов
    for TmpShip in APlanet.Ships do
    begin
      for TmpWeapon := Low(TPlShipWeaponType) to High(TPlShipWeaponType) do
      begin
        if (Assigned(TmpShip.Targets[TmpWeapon])) then
          TPlanetarThread(Engine).SocketWriter.ShipRetarget(TmpShip, TmpWeapon, APlayer);
      end;
    end;
    // Отправим торговые пути
    if (Assigned(APlanet.ResPathOut)) then
      TPlanetarThread(Engine).SocketWriter.PlanetTradePathUpdate(APlanet, APlayer);
    // Отправим сообщение о портале
    if (Assigned(APlanet.Portal)) then
    begin
      TPlanetarThread(Engine).SocketWriter.PlanetPortalOpen(APlanet.Portal.Enter,
        APlanet.Portal.Exit, True, APlayer);
      TPlanetarThread(Engine).SocketWriter.PlanetPortalOpen(APlanet.Portal.Exit,
        APlanet.Portal.Enter, False, APlayer);
    end;
    // Отправим сообщение что игрок подписан
    TPlanetarThread(Engine).SocketWriter.PlanetSubscriptionChange(APlanet, True, APlayer);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.PlayerControlChange(APlanet: TPlPlanet; APlayer: TGlPlayer;
  AIncrement, AOnlyCurrent: Boolean);
var
  TmpRing1: TPlPlanet;
  TmpRing2: TPlPlanet;
begin
  try
    // Отправим текущую планету
    DoPlayerVisibilityChange(APlanet, APlayer, False, AIncrement);
    // Большую видимость и видимость окраин, только если освещаемый
    if (not AOnlyCurrent) then
      DoPlayerVisibilityChange(APlanet, APlayer, True, AIncrement)
    else
      Exit();
    // Отправим кольца
    for TmpRing1 in APlanet.Links do
    begin
      // Отправим видимость первого кольца
      DoPlayerVisibilityChange(TmpRing1, APlayer, False, AIncrement);
      // Отправим контроль первого кольца
      DoPlayerCoverageChange(TmpRing1, APlayer, AIncrement);
      // Отправим контроль второго кольца
      for TmpRing2 in TmpRing1.Links do
        DoPlayerCoverageChange(TmpRing2, APlayer, AIncrement);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarPlanetsController.ShowDetails(APlanet: TPlPlanet; APlayer: TGlPlayer);
var
  TmpI: TPlStoragesPair;
(*  TmpB: TPlBuildingDictPair;*)
begin
  try
    // Нельзя увидеть свойства невидимой планеты, ЧТ и пульсаров
    if (not APlanet.VisibleByPlayer(APlayer))
      or (APlanet.PlanetType = pltHole)
      or (APlanet.PlanetType = pltPulsar) then
    begin
      WriteLn('Wrong show details');
      Exit();
    end;
    // Отправим размер хранилища
    TPlanetarThread(Engine).SocketWriter.PlanetStorageResize(APlanet, True, APlayer);
    // Отправим данные слотов
    for TmpI in APlanet.Storages do
      TPlanetarThread(Engine).SocketWriter.PlanetStorageUpdate(APlanet, TmpI.Value, APlayer);
    // Отправим данные строений
(*    for TmpB in APlanet.Buildings do
      TPlanetarThread(Engine).SocketWriter.PlanetBuildingUpdate(TmpB.Value, APlayer);*)
    // Отправим количество модулей
    TPlanetarThread(Engine).SocketWriter.PlanetModulesUpdate(APlanet, APlayer);
    // Отправим количество энергии
    TPlanetarThread(Engine).SocketWriter.PlanetEnergyUpdate(APlanet, APlayer);
    // Отправим сообщение что можно показать окно деталей
    TPlanetarThread(Engine).SocketWriter.PlanetDetailsShow(APlanet, APlayer);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
