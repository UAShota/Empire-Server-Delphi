{**********************************************}
{                                              }
{ Модуль управления клетками хранения          }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev B  2017.03.31                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Planetar.Controller.Storage;

interface

uses
  System.SysUtils,
  System.Math,
  System.Classes,
  System.Generics.Collections,

  SR.Globals.Log,
  SR.Globals.Types,
  SR.Globals.Player,
  SR.Globals.Dictionaries,
  SR.Planetar.Classes,
  SR.Planetar.Custom;

type
  // Класс управления клетками хранения
  TPlanetarStorageController = class(TPlanetarCustom)
  private const
    I_MAX_STORAGE_COUNT = 20;
    I_MAX_STORAGE_SERVICE = 4;
  private var
    FResCache: TIntegerList;
  private                                 (**)
    procedure SlotAdd(APlanet: TPlPlanet);
    procedure SlotDelete(APlanet: TPlPlanet);
    procedure SlotClear(APlanet: TPlPlanet; AStorage: TPlStorage);
    procedure SlotReserve(APlanet: TPlPlanet; var AStorage: TPlStorage; AIndex: Integer);

    // Поиск свободного слота на указанной планете
    function StorageSlotExists(APlanet: TPlPlanet; ACheckActive: Boolean;
      out AStorageIndex: Integer): Boolean;

    procedure MoveStorageToHolding(APlanetSource: TPlPlanet;
      ASlotSource, ASlotTarget: Integer; ACount: Integer; APlayer: TGlPlayer);
    procedure MoveHoldingToStorage(APlanetTarget: TPlPlanet;
      ASlotSource, ASlotTarget: Integer; ACount: Integer; APlayer: TGlPlayer);
    procedure MoveHoldingToHolding(ASlotSource, ASlotTarget: Integer;
      APlayer: TGlPlayer);
    procedure MoveStorageToStorage(APlanetSource: TPlPlanet; ASlotSource, ASlotTarget: Integer;
      APlayer: TGlPlayer);

  public
    constructor Create(AEngine: TObject); override;
    destructor Destroy(); override;

    function IncrementResource(AResource: TGlResourceType; APlanet: TPlPlanet; ACount: Integer;
      AUseActiveOnly: Boolean = False; ASlotID: Integer = 0; AIgnoreMax: Boolean = False): Integer;
    procedure DecrementResource(AResource: TGlResourceType; APlanet: TPlPlanet; ACount: Integer;
      ASlotID: Integer = 0);
    procedure ExchangeResource(APlanet: TPlPlanet; ASlotSource, ASlotTarget: Integer);

    function LoadResToShip(AResource: TGlResourceType; AShip: TPlShip): Boolean;
    function LoadResToPlanet(AShip: TPlShip): Boolean;

    procedure MoveResource(APlanetSource, APlanetTarget: TPlPlanet; AOnePlace: Boolean;
      ASlotSource, ASlotTarget: Integer; ACount: Integer; APlayer: TGlPlayer);

    function SetFlag(APlanet: TPlPlanet; APosition: Integer; AFlags: Integer): Boolean;
    procedure ChangeStorageCount(APlanet: TPlPlanet; ACount: Integer; AShip: Boolean);
  end;

implementation

uses
  SR.Planetar.Thread;

constructor TPlanetarStorageController.Create(AEngine: TObject);
begin
  try
    inherited Create(AEngine);
    FResCache := TIntegerList.Create();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

destructor TPlanetarStorageController.Destroy();
begin
  try
    FreeAndNil(FResCache);
    inherited;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.SlotAdd(APlanet: TPlPlanet);
var
  TmpStorage: TPlStorage;
begin
  try
    Inc(APlanet.StoragesCount);
    // Игнорируем, если объект хранилища уже есть
    if (APlanet.Storages.TryGetValue(APlanet.StoragesCount, TmpStorage)) then
      Exit();
    // Добавляем резервные слоты
    if (APlanet.StoragesCount < I_MAX_STORAGE_COUNT) then
    begin
      { TODO : Storage оптимизировать работу с слотами }
      if (APlanet.StoragesCount <= APlanet.StoragesCount) then
      begin
        APlanet.StoragesFree.Add(APlanet.StoragesCount);
        APlanet.StoragesFree.Sort();
        APlanet.StoragesInactive.Remove(APlanet.StoragesCount);
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.SlotDelete(APlanet: TPlPlanet);
var
  TmpStorage: TPlStorage;
begin
  try
    // Удалить объект хранилища, если он есть и пустой
    if (APlanet.Storages.TryGetValue(APlanet.StoragesCount, TmpStorage)) then
      Exit();
    // Удаляем резервные слоты
      { TODO : Storage оптимизировать работу с слотами }
    if (APlanet.StoragesCount < I_MAX_STORAGE_COUNT) then
    begin
      if (APlanet.StoragesCount <= APlanet.StoragesCount) then
      begin
        APlanet.StoragesFree.Remove(APlanet.StoragesCount);
        APlanet.StoragesInactive.Add(APlanet.StoragesCount);
        APlanet.StoragesInactive.Sort();
      end;
    end;
    Dec(APlanet.StoragesCount);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.SlotClear(APlanet: TPlPlanet;
  AStorage: TPlStorage);
begin
  try
    // Добавляем резервные слоты
    if (AStorage.Position <= APlanet.StoragesCount) then
    begin
      APlanet.StoragesFree.Add(AStorage.Position);
      APlanet.StoragesFree.Sort();
    end else
    begin
      APlanet.StoragesInactive.Add(AStorage.Position);
      APlanet.StoragesInactive.Sort();
    end;
    // Если хранилище полностью опустошено, удалим его
    TPlanetarThread(Engine).SocketWriter.PlanetStorageClear(APlanet, AStorage.Position);
    // Физически удаляем слот
    FreeAndNil(AStorage.Holder);
    APlanet.Storages.Remove(AStorage.Position);
    FreeAndNil(AStorage);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.SlotReserve(APlanet: TPlPlanet;
  var AStorage: TPlStorage; AIndex: Integer);
begin
  try
    // Создадим сам склад
    AStorage := TPlStorage.Create();
    AStorage.Holder := TGlStorageHolder.Create();
    // Добавим его в список и выставим активность
    APlanet.Storages.Add(AIndex, AStorage);
    AStorage.Active := (AIndex <= APlanet.StoragesCount);
    AStorage.Position := AIndex;
    // Убираем резервные слоты
    if (AStorage.Active) then
      APlanet.StoragesFree.Remove(AIndex)
    else
      APlanet.StoragesInactive.Remove(AIndex);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlanetarStorageController.StorageSlotExists(APlanet: TPlPlanet;
  ACheckActive: Boolean; out AStorageIndex: Integer): Boolean;
begin
  Result := False;
  try
    AStorageIndex := 0;

    if (APlanet.StoragesFree.Count > 0) then
      AStorageIndex := APlanet.StoragesFree.First
    else
      if (not ACheckActive)
        and (APlanet.StoragesInactive.Count > 0)
      then
        AStorageIndex := APlanet.StoragesInactive.First;

    Result := (AStorageIndex <> 0);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlanetarStorageController.IncrementResource(AResource: TGlResourceType;
  APlanet: TPlPlanet; ACount: Integer; AUseActiveOnly: Boolean = False;
  ASlotID: Integer = 0; AIgnoreMax: Boolean = False): Integer;
var
  TmpI: Integer;
  TmpMax: Integer;
  TmpMaxIndex: Integer;
  TmpMaxSlot: Integer;
  TmpStorage: TPlStorage;

  procedure Check(AIndex: Integer; AUseCache: Boolean);
  begin
    try
      if (APlanet.Storages[AIndex].Holder.Resource = AResource)
        and (APlanet.Storages[AIndex].Holder.Count < TmpMaxSlot)
      then
      begin
        // Добавить слот в кэш для дальнейших операций с этим типом товара
        if (not AUseCache) then
          FResCache.Add(AIndex);
        if (APlanet.Storages[AIndex].Holder.Count > TmpMax) then
        begin
          TmpMax := APlanet.Storages[AIndex].Holder.Count;
          TmpMaxIndex := Aindex;
        end;
      end;
    except
      on E: Exception do
        TLogAccess.Write(E);
    end;
  end;

begin
  Result := 0;
  try
    FResCache.Clear();
    if (AIgnoreMax) then
      TmpMaxSlot := ACount
    else
      TmpMaxSlot := TGlDictionaries.Resources[AResource].Max;
    TmpMaxIndex := ASlotID;
    TmpMax := 0;

    while (ACount > 0) do
    begin
      // При добавлении товара в указанном слоте - добавлении только указанный объем
      if (ASlotID = 0) then
      begin
        // Поиск слота с наибольшим количеством товара
        if (FResCache.Count = 0) then
        begin
          // Поиск по всем хранилищам напрямую
          for TmpI in APlanet.Storages.Keys do
            Check(TmpI, False);
        end else
        begin
          // Поиск по всем хранилищам через кэш
          for TmpI := 0 to Pred(FResCache.Count) do
            Check(FResCache[TmpI], True);
        end;
      end else
      // Если добавляет в неполный слот - добавляется без перераспределения
      begin
        if (APlanet.Storages.ContainsKey(ASlotID)) then
        begin
          // Попытка прокинуть ресурс на занятый слот с другим ресурсом
          if (APlanet.Storages[TmpMaxIndex].Holder.Resource = AResource) then
            TmpMax := APlanet.Storages[TmpMaxIndex].Holder.Count
          else
            Exit(0);
        end;
      end;

      // Слот для складывания не найден
      if (TmpMax = 0) then
      begin
        if (TmpMaxIndex = 0) then
          StorageSlotExists(APlanet, AUseActiveOnly, TmpMaxIndex);
        if (TmpMaxIndex = 0) then
          Break;
        TmpMax := Min(ACount, TmpMaxSlot);
        SlotReserve(APlanet, TmpStorage, TmpMaxIndex);
        TmpStorage.Holder.Resource := AResource;
        TmpStorage.Holder.ResourceType := gsotResource;
        Inc(APlanet.ResAvailOut[AResource], TmpMaxSlot);
      end else
      begin
        // Если в слоте с товаром товара больше лимита, то в этот слот ложить нельзя
        if (TmpMax < TmpMaxSlot) then
          TmpMax := Min(TmpMaxSlot - TmpMax, ACount)
        else
          Exit(0);
      end;
      // Положить товар на склад
      Inc(APlanet.Storages[TmpMaxIndex].Holder.Count, TmpMax);
      // Отправим сообщение о смене количества товара на планете
      TPlanetarThread(Engine).SocketWriter.PlanetStorageUpdate(APlanet, APlanet.Storages[TmpMaxIndex]);
      // Проверка на наличие остатка товаров для раскладывания
      Dec(ACount, TmpMax);
      Inc(Result, TmpMax);
      // Выйти после первого цикла если сброс в определенную ячейку, иначе поиск следующей ячейки
      if (ASlotID <> 0) then
        Break
      else begin
        TmpMax := 0;
        TmpMaxIndex := 0;
      end;
    end;

    // Увеличить количество используемого ресурса на планете
    APlanet.ResAvailIn[AResource] := APlanet.ResAvailIn[AResource] + Result;
    APlanet.ResAvailOut[AResource] := APlanet.ResAvailOut[AResource] - Result;

    // Отправим изменение количества модулей
    if (AResource = resModules) then
      TPlanetarThread(Engine).SocketWriter.PlanetModulesUpdate(APlanet);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.DecrementResource(AResource: TGlResourceType;
  APlanet: TPlPlanet; ACount: Integer; ASlotID: Integer = 0);
var
  TmpI: Integer;
  TmpMin: Integer;
  TmpMinIndex: Integer;

  procedure Check(AIndex: Integer; AUseCache: Boolean);
  begin
    try
      if (APlanet.Storages[AIndex].Holder.Resource = AResource)
        and (APlanet.Storages[AIndex].Holder.Count > 0)
      then
      begin
        if (not AUseCache) then
          FResCache.Add(AIndex);
        if (APlanet.Storages[AIndex].Holder.Count < TmpMin) then
        begin
          TmpMin := APlanet.Storages[AIndex].Holder.Count;
          TmpMinIndex := Aindex;
        end;
      end;
    except
      on E: Exception do
        TLogAccess.Write(E);
    end;
  end;

begin
  try
    // Уменьшить количество используемого ресурса на планете
    APlanet.ResAvailIn[AResource] := APlanet.ResAvailIn[AResource] - ACount;
    APlanet.ResAvailOut[AResource] := APlanet.ResAvailOut[AResource] + ACount;

    FResCache.Clear();

    while (ACount > 0) do
    begin
      // При убавлении товара в указанном слоте - убавляется только указанный объем
      if (ASlotID = 0) then
      begin
        // Поиск слота с наименьшим количеством товара
        TmpMin := MaxInt;
        TmpMinIndex := 0;
        if (FResCache.Count = 0) then
        begin
          // Поиск по всем хранилищам напрямую
          for TmpI in APlanet.Storages.Keys do
            Check(TmpI, False);
        end else
        begin
          // Поиск по всем хранилищам через кэш
          for TmpI := 0 to Pred(FResCache.Count) do
            Check(FResCache[TmpI], True);
        end;
      end else
      begin
        TmpMinIndex := ASlotID;
        TmpMin := ACount;
      end;

      // Запрашиваемого товара меньше чем в слоте
      if (ACount <= TmpMin) then
      begin
        Dec(APlanet.Storages[TmpMinIndex].Holder.Count, ACount);
        ACount := 0;
      end else
      // Запрашиваемого товара больше чем в слоте
      begin
        APlanet.Storages[TmpMinIndex].Holder.Count := 0;
        ACount := ACount - TmpMin;
      end;
      // Отправить сообщение об изменении количества товара
      TPlanetarThread(Engine).SocketWriter.PlanetStorageUpdate(APlanet, APlanet.Storages[TmpMinIndex]);
      // Сделать слот пустым
(*      if (not APlanet.Storages[TmpMinIndex].HaveProduction)
        and (APlanet.Storages[TmpMinIndex].Holder.Count = 0) then*)
      begin
        FResCache.Remove(TmpMinIndex);
        SlotClear(APlanet, APlanet.Storages[TmpMinIndex]);
        Dec(APlanet.ResAvailOut[AResource],
          TGlDictionaries.Resources[AResource].Max);
      end;
    end;

    // Отправим изменение количества модулей
    if (AResource = resModules) then
      TPlanetarThread(Engine).SocketWriter.PlanetModulesUpdate(APlanet);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.ExchangeResource(APlanet: TPlPlanet;
  ASlotSource, ASlotTarget: Integer);
var
  TmpHolding: TGlStorageHolder;
begin
  try
    TmpHolding := TGlStorageHolder.Create();
    try
      // Сохраним значения целевого слота
      TmpHolding.Update(APlanet.Storages[ASlotTarget].Holder);
      // Заменим целевой
      APlanet.Storages[ASlotTarget].Holder.Update(APlanet.Storages[ASlotSource].Holder);
      TPlanetarThread(Engine).SocketWriter.PlanetStorageUpdate(APlanet, APlanet.Storages[ASlotTarget]);
      // Заменим исходный
      APlanet.Storages[ASlotSource].Holder.Update(TmpHolding);
      TPlanetarThread(Engine).SocketWriter.PlanetStorageUpdate(APlanet, APlanet.Storages[ASlotSource]);
      // В случае переноса с неактивного слота - убираем неактивный слот
      if (APlanet.Storages[ASlotSource].Holder.Resource = resEmpty) then
        SlotClear(APlanet, APlanet.Storages[ASlotSource]);
    finally
      FreeAndNil(TmpHolding);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlanetarStorageController.LoadResToShip(AResource: TGlResourceType;
  AShip: TPlShip): Boolean;
{var
  TmpPlanet: TPlanet;
  TmpCount: Integer;}
begin
  Result := True;
  // Если корабль с ресурсами - он едет дальше
(*  if (AShip.ResCount > 0) then
    Exit(True);

  // Проверка товара который можно загрузить
//  TmpPlanet := AShip.TargetPlanet;
  TmpCount := TmpPlanet.ResAvailIn[AResource] - TmpPlanet.ResUseIn[AResource] * ProductMultiplier;
  if (TmpCount <= 0) then
  begin
    AShip.Resource := prtEmpty;
    AShip.ResCount := 0;
    Exit(False);
  end;
  // Загрузка товара на корабль
  TmpCount := Min(AShip.Count * TransportToUp, TmpCount);
  AShip.ResCount := TmpCount;
  AShip.Resource := AResource;
  // Выгрузка товара с планеты
  DecrementResource(AResource, TmpPlanet, TmpCount);
  // Отправим сообщение
  TPlanetarEngine(Engine).SocketWriter.ShipUpdateResources(AShip);*)
end;

function TPlanetarStorageController.LoadResToPlanet(AShip: TPlShip): Boolean;
//var
//  TmpPlanet: TPlanet;
begin
  Result := True;
  // Если корабль пустой - стоит дальше
(*  if (AShip.ResCount = 0) then
    Exit(True);
  // Если на планете места нет, едет обратно
//  TmpPlanet := AShip.TargetPlanet;
  if (TmpPlanet.ResAvailOut[AShip.Resource] < AShip.ResCount)
    and (TmpPlanet.StoragesFree.Count = 0)
    and (TmpPlanet.StoragesInactive.Count = 0)
  then
    Exit(True);
  // Если место есть - сгрузить с корабля и обнулить на корабле
  IncrementResource(AShip.Resource, TmpPlanet, AShip.ResCount);
  AShip.ResCount := 0;
  AShip.Resource := prtEmpty;
  // Отправим сообщение
  TPlanetarEngine(Engine).SocketWriter.ShipUpdateResources(AShip);*)
end;

function TPlanetarStorageController.SetFlag(APlanet: TPlPlanet; APosition: Integer;
  AFlags: Integer): Boolean;
begin
  Result := False;
  try
(*    APlanet.Storages[APosition].Flags := AFlags; *)
(*    TPlanetarThread(Engine).WorkerProduction.CalculateProduction(APlanet); *)

    Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.ChangeStorageCount(APlanet: TPlPlanet;
  ACount: Integer; AShip: Boolean);
var
  TmpI: Integer;
  TmpCount: Integer;
  TmpFlag: Boolean;
begin
  try
    TmpFlag := (ACount > 0);
    // Если корабль - обновим количество сервисок
    if (AShip) then
    begin
      // Если корабль добавляется - добавим только корабли, вмещающиеся в 4 единицы
      if (TmpFlag) then
        TmpCount := Max(0, Min(ACount, I_MAX_STORAGE_SERVICE - APlanet.Services))
      // Иначе нужно удалить только те слоты, которые вмещались в 4 стека
      else
        TmpCount := -Min(0, I_MAX_STORAGE_SERVICE - APlanet.Services + ACount);
      Inc(APlanet.Services, ACount);
    end else
      TmpCount := ACount;
    // Проверим, нужно ли обновление
    if (TmpCount = 0) then
      Exit();
    TmpI := Abs(TmpCount);
    // Если слотов больше максимума - уберем множитель слотов
    while (TmpI > 0) do
    begin
      if (TmpFlag) then
        SlotAdd(APlanet)
      else
        SlotDelete(APlanet);
      // И так все слоты
      Dec(TmpI);
    end;
    // Отправим сообщение об изменении размера хранилища
    TPlanetarThread(Engine).SocketWriter.PlanetStorageResize(APlanet, False);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.MoveResource(APlanetSource, APlanetTarget: TPlPlanet;
  AOnePlace: Boolean; ASlotSource, ASlotTarget: Integer; ACount: Integer; APlayer: TGlPlayer);
begin
  try
    if (not AOnePlace) then
    begin
      // С планеты в хранилище
      if (Assigned(APlanetSource)) and (not Assigned(APlanetTarget)) then
        MoveStorageToHolding(APlanetSource, ASlotSource, ASlotTarget, ACount, APlayer)
      else
      // С хранилища на планету
      if (not Assigned(APlanetSource)) and (Assigned(APlanetTarget)) then
        MoveHoldingToStorage(APlanetTarget, ASlotSource, ASlotTarget, ACount, APlayer)
    end else
    begin
      // Обмен в хранилище
      if (not Assigned(APlanetSource)) then
        MoveHoldingToHolding(ASlotSource, ASlotTarget, APlayer)
      else
      // Обмен на планете
        MoveStorageToStorage(APlanetSource, ASlotSource, ASlotTarget, APlayer);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.MoveStorageToHolding(APlanetSource: TPlPlanet;
  ASlotSource, ASlotTarget: Integer; ACount: Integer; APlayer: TGlPlayer);
var
  TmpHolding: TGlStorageHolder;
  TmpCount: Integer;
begin
  try
    // Нельзя сбрасывать ресурсы с чужой планеты или с планету с боем
    if (APlanetSource.Owner <> APlayer)
      or (APlanetSource.Timer[ppltmBattle])
    then
      Exit();
    TmpHolding := APlanetSource.Storages[ASlotSource].Holder;
    // Взять минимум который есть на планете, т.к. он мог смениться за квант времени
    TmpCount := Min(TmpHolding.Count, ACount);
    if (TmpCount <= 0) then
      Exit();
    // Попытка добавить товар в трюм
    if (ASlotTarget = 0) then
      TmpCount := APlayer.Storage.IncrementResource(TmpHolding.Resource, TmpCount,
       TPlanetarThread(Engine).SocketWriter.PlayerStorageUpdate, APlayer)
    else
      TmpCount := APlayer.Storage.IncrementResource(TmpHolding.Resource, ASlotTarget,
        TmpCount, TPlanetarThread(Engine).SocketWriter.PlayerStorageUpdate, APlayer);
    // Декремент товара на планете в размере переложенного в трюм
    if (TmpCount > 0) then
      DecrementResource(TmpHolding.Resource, APlanetSource, TmpCount, ASlotSource);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.MoveHoldingToStorage(
  APlanetTarget: TPlPlanet; ASlotSource, ASlotTarget: Integer; ACount: Integer;
  APlayer: TGlPlayer);
var
  TmpCount: Integer;
  TmpHolding: TGlStorageHolder;
begin
  try
    // Нельзя сбрасывать ресурсы на чужую планету или на планету с боем
    if (APlanetTarget.Owner <> APlayer)
      or (APlanetTarget.Timer[ppltmBattle])
    then
      Exit();
    TmpHolding := APlayer.Storage.Storages[ASlotSource];
    // Попытка положить товар из трюма на планету
    TmpCount := IncrementResource(TmpHolding.Resource, APlanetTarget,
      TmpHolding.Count, True, ASlotTarget);
    if (TmpCount > 0) then
    begin
      // Убрать из хранилища количество переложенного ресурса
      APlayer.Storage.DecrementResource(ASlotSource, TmpCount,
        TPlanetarThread(Engine).SocketWriter.PlayerStorageUpdate, APlayer);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.MoveHoldingToHolding(ASlotSource,
  ASlotTarget: Integer; APlayer: TGlPlayer);
var
  TmpCount: Integer;
  TmpHoldingSource: TGlStorageHolder;
  TmpHoldingTarget: TGlStorageHolder;
begin
  try
    // Получим слоты хранилища
    TmpHoldingSource := APlayer.Storage.Storages[ASlotSource];
    TmpHoldingTarget := APlayer.Storage.Storages[ASlotTarget];

    // Обмен между ячейками с одинаковым содержимым приводить к дополнению таргетной ячейки
    if (TmpHoldingSource.Resource = TmpHoldingTarget.Resource) then
    begin
      TmpCount := APlayer.Storage.IncrementResource(TmpHoldingSource.Resource, ASlotTarget,
        TmpHoldingSource.Count, TPlanetarThread(Engine).SocketWriter.PlayerStorageUpdate, APlayer);
      if (TmpCount > 0) then
      begin
        APlayer.Storage.DecrementResource(ASlotSource, TmpCount,
          TPlanetarThread(Engine).SocketWriter.PlayerStorageUpdate, APlayer);
      end;
    end else
    begin
      // Иначе происходит обмен ячеек
      APlayer.Storage.Exchange(ASlotSource, ASlotTarget,
        TPlanetarThread(Engine).SocketWriter.PlayerStorageUpdate, APlayer);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarStorageController.MoveStorageToStorage(APlanetSource: TPlPlanet;
  ASlotSource, ASlotTarget: Integer; APlayer: TGlPlayer);
var
  TmpCount: Integer;
  TmpHoldingSource: TGlStorageHolder;
  TmpHoldingTarget: TGlStorageHolder;
  TmpStorage: TPlStorage;
begin
  try
    TmpHoldingSource := APlanetSource.Storages[ASlotSource].Holder;
    // Создадим таргетный слот, если это обмен слотами
    if (not APlanetSource.Storages.ContainsKey(ASlotTarget)) then
      SlotReserve(APlanetSource, TmpStorage, ASlotTarget)
    else
      TmpStorage := APlanetSource.Storages[ASlotTarget];

    TmpHoldingTarget := TmpStorage.Holder;

    // Обмен между ячейками с одинаковым содержимым приводить к дополнению таргетной ячейки
    if (TmpHoldingSource.Resource = TmpHoldingTarget.Resource) then
    begin
      TmpCount := IncrementResource(TmpHoldingSource.Resource, APlanetSource,
        TmpHoldingSource.Count, True, ASlotTarget);
      if (TmpCount > 0) then
        DecrementResource(TmpHoldingSource.Resource, APlanetSource, TmpCount, ASlotSource);
    end else
    begin
      // Иначе происходит обмен ячеек
      ExchangeResource(APlanetSource, ASlotSource, ASlotTarget);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
