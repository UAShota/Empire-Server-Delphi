{**********************************************}
{                                              }
{ Модуль управления игроками                   }
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
  // Предопределенные классы
  TGlStorage = class;
  TGlPlayer = class;

  // Каллбак, на который завязано текущее хранилище, для отправки сведений клиенту
  TGlStorageCallback = procedure(AIndex: Integer; AHolding: TGlStorageHolder; APlayer: TGlPlayer) of object;

  // Класс описания подсоединенного клиента
  TGlPlayerInfo = class(TObject)
    // Ссылка на игрока
    Player: TGlPlayer;
    // Ссылка на соединение
    Connection: TObject;
    // Буфер команд чтения
    Reader: TTransportQueue;
    // Буфер команд записи
    Writer: TTransportQueue;
    // IP клиента
    IP: String;
  public
    constructor Create();
    destructor Destroy(); override;
  end;

  // Класс описания игрока
  TGlPlayer = class
  public var
    // Идентификатор
    UID: Integer;
    // Имя
    Name: String;
    // Глобальное хранилище
    Race: TGlRaceType;
    // Количество валюты
    Gold: Integer;
    // Количество доната
    Credits: Integer;
    // Количество топлива
    Fuel: Integer;
    // Хеш пароля
    Password: String;
    // Хранилище
    Storage: TGlStorage;
    // Планетарный профиль
    PlanetarProfile: TObject;
    // Информация о соединении
    Info: TGlPlayerInfo;
    // Признак бота
    IsBot: Boolean;
  private
    // Загрузка хранилища игрока
    procedure DoLoadHoldings();
  public
    constructor Create();
    destructor Destroy(); override;
  public
    // Подключение игрока, загрузка созвездия
    procedure Connect(Ainfo: TGlPlayerInfo);
    // Отключение игрока, без выгрузки созвездия
    procedure Disconnect();

    procedure Load;

    // Роль двух игроков по отношению друг к другу
    function Role(ALeft, ARight: TGlPlayer): TGlPlayerRole; overload;
    // Роль двух игроков по отношению друг к другу
    function Role(AVersus: TGlPlayer; AHideEnemy: Boolean = False): TGlPlayerRole; overload;
    // Быстрое получение роли противника
    function IsRoleEnemy(ALeft, ARight: TGlPlayer): Boolean; overload;
    // Быстрое получение роли противника
    function IsRoleEnemy(AVersus: TGlPlayer): Boolean; overload;
    // Быстрое получение роли союзника
    function IsRoleFriend(ALeft, ARight: TGlPlayer): Boolean; overload;
    // Быстрое получение роли союзника
    function IsRoleFriend(AVersus: TGlPlayer): Boolean; overload;
  end;
  // Словарь доступных игроков
  TGlPlayerDict = TDictionary<Integer, TGlPlayer>;
  TGlPlayerDictPair = TPair<Integer, TGlPlayer>;

  // Класс хранилища
  TGlStorage = class
  private var
    FStorages: TGlStorageList;
    FSize: Integer;
  public
    constructor Create();
    destructor Destroy(); override;
  public
    // Добавление ресурса методом дополнения или в свободный слот
    function IncrementResource(AResource: TGlResourceType; ACount: Integer;
      ACallback: TGlStorageCallback; APlayer: TGlPlayer; AUseFreeSpace: Boolean = False): Integer; overload;
    // Добавление ресурса методом дополнения или в указанный слот
    function IncrementResource(AResource: TGlResourceType; AIndex, ACount: Integer;
      ACallback: TGlStorageCallback; APlayer: TGlPlayer): Integer; overload;
    // Уменьшение ресурса в указанном слоте
    procedure DecrementResource(AIndex, ACount: Integer; ACallback: TGlStorageCallback;
      APlayer: TGlPlayer);
    // Обмен двух слотов
    procedure Exchange(ASourceIndex, ATargetIndex: Integer; ACallback: TGlStorageCallback;
      APlayer: TGlPlayer);
  public
    // Слоты хранилища
    property Storages: TGlStorageList read FStorages;
    // Размер хранилища
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
  // Загрузим свое планетарное или подключимся к уже запущенному
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
    // Сперва заполняем слоты где товар уже есть
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
      // Отправим сообщение об обновлении хранилища
      ACallback(TmpI, TmpHolding, APlayer);
      // Если все ресурсы сложили, больше ничего делать не нужно
      if (ACount = 0) then
        Exit();
    end;
  end;
  // Затем остатки товара раскидаем по свободным слотам
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
  // На всякий случай проверить что в ячейке трюма пусто или есть место
  if ((TmpHolding.Resource <> AResource) and (TmpHolding.ResourceType <> gsotEmpty))
    or (TmpHolding.Count > TmpMax)
  then
    Exit(0);

  Result := Min(TmpMax - TmpHolding.Count, ACount);
  TmpHolding.Resource := AResource;
  TmpHolding.Count := TmpHolding.Count + Result;
  TmpHolding.ResourceType := gsotResource;
  // Отправим сообщение об обновлении хранилища
  ACallback(AIndex, TmpHolding, APlayer);
end;

procedure TGlStorage.DecrementResource(AIndex, ACount: Integer; ACallback: TGlStorageCallback;
  APlayer: TGlPlayer);
var
  TmpHolding: TGlStorageHolder;
begin
  TmpHolding := Storages[AIndex];
  // Проверка на допустимое количество ресурсов
  Dec(TmpHolding.Count, Min(TmpHolding.Count, ACount));
  if (TmpHolding.Count = 0) then
  begin
    TmpHolding.ResourceType := gsotEmpty;
    TmpHolding.Resource := resEmpty;
  end;
  // Отправим сообщение об обновлении хранилища
  ACallback(AIndex, TmpHolding, APlayer);
end;

procedure TGlStorage.Exchange(ASourceIndex, ATargetIndex: Integer;
  ACallback: TGlStorageCallback; APlayer: TGlPlayer);
var
  TmpHolding: TGlStorageHolder;
begin
  TmpHolding := TGlStorageHolder.Create();
  try
    // Сохраним значения целевого слота
    TmpHolding.Update(Storages[ATargetIndex]);
    // Заменим целевой и отправим сообщение
    Storages[ATargetIndex].Update(Storages[ASourceIndex]);
    ACallback(ATargetIndex, Storages[ATargetIndex], APlayer);
    // Заменим исходный и отправим сообщение
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
