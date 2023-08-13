{**********************************************}
{                                              }
{ Классы планетарных объектов                  }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev B  2017.03.30                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Planetar.Classes;

interface

uses
  System.SysUtils,
  System.Generics.Collections,

  SR.Globals.Log,
  SR.Globals.Types,
  SR.Globals.Player;

type
  // Спасибо дельфи за это говно
  TPlShip = class;
  TPlShipGroup = class;
  TPlPlanet = class;
  TPlPortal = class;

  { TODO -omdv : Resource включить в работу }
  TResListData = array[TGlResourceType] of Integer;

  // Тип для списка целых значений
  TIntegerList = TList<Integer>;

  // Список планет
  TPlPlanetList = TList<TPlPlanet>;

  // Словарь планет, на которые подписан игрок
  TPlClientsDict = TDictionary<TGlPlayer, TPlPlanetList>;
  // Пара для перебора словаря планет
  TPlClientsDictPair = TPair<TGlPlayer, TPlPlanetList>;

  {$REGION 'TPlStorage'}

  // Тип описывающий склады планеты
  TPlStorage = class
    // Объект хранилища
    Holder: TGlStorageHolder;
    // Позиция в списке ячеек
    Position: Integer;
    // Признак использования слота
    Active: Boolean;
    // Множитель
    Multiplier: Integer;
  end;

  // Список хранилищ
  TPlStorages = TDictionary<Integer, TPlStorage>;
  TPlStoragesPair = TPair<Integer, TPlStorage>;

  {$ENDREGION}

  {$REGION 'TPlPortal'}

  // Объект планетарного портала
  TPlPortal = class
  public
    // Создатель
    Owner: TGlPlayer;
    // Планета входа
    Enter: TPlPlanet;
    // Планета выхода
    Exit: TPlPlanet;
    // Лимит перемещений
    Limit: Integer;
    // Возможность перебить
    Breakable: Boolean;
    // Быстрый переброс (чт)
    FastTransfer: Boolean;
  end;

  {$ENDREGION}

  {$REGION 'TPlLanding'}

  // Тип планетарного слота
  TPlLanding = type Integer;
  // Хелпер для типа планетарного слота
  TPlLandingHelper = record helper for TPlLanding
  public
    // Сохранить переход на следующий слот
    function Inc(): TPlLanding;
    // Сохранить переход на предыдущий слот
    function Dec(): TPlLanding;
    // Указатель на следующий слот
    function Next(): TPlLanding;
    // Указатель на предыдущий слот
    function Prev(): TPlLanding;
    // Признак нижней орбиты слота
    function IsLowOrbit(): Boolean;
  public
    // Слот для указанного значения
    class function Offset(AValue: Integer): TPlLanding; static;
    // Валидность номера слота
    class function Valid(AValue: Integer): Boolean; static;
  end;

  {$ENDREGION}

  {$REGION 'TPlLandings'}

  // Класс описывающий посадочные места планетоида
  TPlLandings = record
  public const
    // Количество боевых слотов
    I_FIGHT_COUNT = 15;
    // Количество доступных слотов
    I_TOTAL_COUNT = I_FIGHT_COUNT + 5;
  private var
    // Массив посадочных мест
    FLandings: array[1..I_TOTAL_COUNT] of TObject;
  public
    // Добавление корабля в слот
    procedure Add(AShip: TPlShip);
    // Удаление корабля с слота
    procedure Remove(AShip: TPlShip);
    // Проверка на пустоту слота
    function IsEmpty(APosition: Integer): Boolean;
    // Проверка на наличие корабля
    function IsShip(APosition: Integer; var AShip: TPlShip): Boolean;
  end;

  {$ENDREGION}

  {$REGION 'TPlTransferPath'}

  TPlTransferPath = class
    Group: Integer;
    Leader: TPlPlanet;
    Planets: TPlPlanetList;
  end;
  TPlTransportPathList = TList<TPlTransferPath>;

  {$ENDREGION}

  {$REGION 'TPlBuilding'}

  // Типы строений
  TPlBuildingType = (
    pbtEmpty,
    pbtElectro,
    pbtWarehouse,
    pbtModules,
    pbtXenon,
    pbtTitan,
    pbtKremniy,
    pbtCrystal,
    pbtCombinatFarm,
    pbtCombinatElectro,
    pbtCombinatCrystal,
    pbtCombinatXenon,
    pbtMakeCredits,
    pbtMakekvark,
    pbtMakeppl,
    pbtMakemodules,
    pbtMakefuel,
    pbtMaketech,
    pbtMakemines,
    pbtMakedrules,
    pbtMakearmor,
    pbtMakedamage
  );

  // Режимы производства
  TPlBuildingMode = (
    // Первичное
    pbModePrimary,
    // Вторичное
    pbModeSecondary
  );

  // Технологии строений
  TPlBuildingTechType = (
    // Стоимость покупки
    pttbBuyCost,
    // Стоимость апгрейда
    pttbUpgradeCost,
    // Признак открытого строения
    pttbActive,
    // Расход и выработка энергии
    pttbEnergy,
    // Увеличение потолка лояльности планетоида
    pttbCapture,
    // Количество 1 ресурса для 1 режима
    pttbResInCount11,
    // Количество 2 ресурса для 1 режима
    pttbResInCount21,
    // Количество 1 ресурса для 2 режима
    pttbResInCount12,
    // Количество 2 ресурс для 2 режима
    pttbResInCount22,
    // Количество выходного ресурса 1 режима
    pttbResOutCount1,
    // Количество выходного ресурса 2 режима
    pttbResOutCount2,
    // Тип 1 ресурса для 1 режима
    pttbResInId11,
    // Тип 2 ресурса для 1 режима
    pttbResInId21,
    // Тип 1 ресурса для 2 режима
    pttbResInId12,
    // Тип 2 ресурса для 2 режима
    pttbResInId22,
    // Тип выходного ресурса для 1 режима
    pttbResOutId1,
    // Тип выходного ресурса для 1 режима
    pttbResOutId2
  );

  // Элемент технологии строения
  TPlBuildingTechItem = record
    // Доступность
    Supported: Boolean;
    // Количество технологий
    Count: Integer;
    // Уровни
    Levels: array[0..5] of Integer;
  end;

  // Купленные технологии
  PPlBuildingTechKeys = ^TPlBuildingTechKeys;
  TPlBuildingTechKeys = array[TPlBuildingTechType] of Integer;

  // Значения технологии для юнита
  PPlBuildingTechValues = ^TPlBuildingTechValues;
  TPlBuildingTechValues = array[TPlBuildingType] of TPlBuildingTechKeys;

  // Ссылка на технологии для строения
  PPlBuildingTechUnit = ^TPlBuildingTechUnit;
  TPlBuildingTechUnit = array[TPlBuildingTechType] of TPlBuildingTechItem;

  // Ссылка на технологии для профиля
  PPlBuildingTechProfile = ^TPlBuildingTechProfile;
  TPlBuildingTechProfile = array[TPlBuildingType] of TPlBuildingTechUnit;

  // Словарь всех технологий
  TPlBuildingTechRace = array[TGlRaceType] of TPlBuildingTechProfile;

  // Тип описывающий планетарное строение
  TPlBuilding = class
  private var
    // Ссылка на технологии строения
    FTechUnit: PPlBuildingTechUnit;
    // Ссылка на прокачанные возможности владельца
    FTechKeys: PPlBuildingTechKeys;
  public
    // Тип здания
    BuildingType: TPlBuildingType;
    // Активный режим работы
    Mode: TPlBuildingMode;
    // Планета
    Planet: TPlPlanet;
    // Уровень здания
    Level: Integer;
    // Позиция площадки расположения
    Position: Integer;
    // Признак строительства
    Active: Boolean;
    // Структура строения, 1000 максимум
    HP: Integer;
  public
      // Смена набора технологий
    procedure ChangeTech(ATechUnit: PPLBuildingTechUnit; ATechKeys: PPlBuildingTechKeys);
  end;
  { TODO -omdv : Buildings включить в работу }
  // Список планетарных строений для постройки
  TPlBuildingList = TList<TPlBuilding>;

  {$ENDREGION}

  {$REGION 'TPlShip'}

  // Состояния корабля
  TPlShipState = (
    // Стоит
    pshstIddle,
    // В движении между слотами
    pshstMovingLocal,
    // В движении между планетами
    pshstMovingGlobal,
    // Паркуется
    pshstParking,
    // Готовится прыгнуть в портал
    pshstPortalJump,
    // Запустилась аннигиляция
    pshstAnnihilation
  );

  // Режим корабля
  TPlShipMode = (
    // Активен
    pshmdActive,
    // Блокирован с краев
    pshmdBlocked,
    // Лимит для активации
    pshmdFull,
    // В походном режиме
    pshmdOffline,
    // Идет строительство
    pshmdConstruction
  );

  // Таймеры корабля
  TPlShipTimer = (
    // Постройка
    pshtmOpConstruction,
    // Прыжок в портал
    pshtmOpPortalJump,
    // Дозаправка
    pshtmOpRefill,
    // Полет
    pshtmOpFlight,
    // Парковка
    pshtmOpParking,
    // Аннигиляция
    pshtmOpAnnihilation,
    // Самопочинка
    pshtmOpFix,
    // Ремонт союзника
    pshtmOpRepair,
    // Скилл разбора юнита
    pshtmCdConstructor
  );

  // Каллбак на таймер
  TPlShipTimerCallback = function(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean of object;

  // Тип корабля
  TPlShipType = (
    // Пустой
    pshtpEmpty,
    // Транспорт
    pshtpTransport,
    // Крыса
    pshtpCruiser,
    // Дредноут
    pshtpDrednout,
    // Корвет
    pshtpCorvete,
    // Девастатор
    pshtpDevastator,
    // Штурмовик
    pshtpInvader,
    // Военка
    pshtpMillitary,
    // Верфь
    pshtpShipyard,
    // Научная база
    pshtpScient,
    // Сервисная платформа
    pshtpService,
    // Флагман
    pshtpFlagship
  );

  // Как уничтожился кораблик
  TPlShipDestroyed = (
    // Никак, живой
    pshchNone,
    // Взорвался
    pshchDestruct,
    // Тихо исчез
    pshchSilent
  );

  // Тип орудийной системы
  TPlShipWeaponType = (
    // Центральное
    pswCenter,
    // Левое
    pswLeft,
    // Правое
    pswRight,
    // Ракета
    pswRocket
  );
  TPlShipTargets = array[TPlShipWeaponType] of TPlShip;

  // Типы технологий корабликов
  TPlShipTechType = (
    // Пустая теха
    plttEmpty,
    // Оружие пули
    plttWeaponBullet,
    // Возможность постройки
    plttActive,
    // Аннигиляция
    plttAnnihilation,
    // Броня
    plttArmor,
    // Запрет разбора конструктором
    plttSolidBody,
    // Цена
    plttCost,
    // Количество в стеке
    plttCount,
    // Множитель урона
    plttDamage,
    // Самопочинка
    plttRepair,
    // Скрытое перемещение
    plttHidden,
    // Структура
    plttHp,
    { TODO -omdv : Свободная технология }
    plttMirror,
    // Безлимитный портал
    plttStablePortal,
    // Выработка ресурса
    plttProduction,
    // Починка других юнитов
    plttFix,
    // Переносное хранилище
    plttStorage,
    // Вес юнита
    plttWeight,
    // Скилл разбора
    plttSkillConstructor,
    // Элитка разбор дополнительных противников
    plttSkillConstructorEnemy,
    // Элитка разбор в дополнительных союзников
    plttSkillConstructorFriend,
    // Стационарность
    plttStationary,
    // Приоритет атаки
    plttPriority,
    // Мспользование нижней орбиты
    plttLowOrbit,
    // Слет с планетоида
    plttFaster,
    // Защита от атак артилерии с другой планеты
    plttRangeDefence,
    // Оружие прострела через юнит
    plttWeaponOvershot,
    // Возможность влета в тыл
    plttIntoBackzone,
    // Возможность блокировать с краев
    plttCornerBlock,
    // Оружие двойная пуля
    plttWeaponDoubleBullet,
    // Цель для прострела
    plttOvershotTarget,
    // Оружие лазер
    plttWeaponLaser,
    // Оружие ракета
    plttWeaponRocket,
    // Захват лояльности
    plttCapturer,
    // Блокиратор прострела
    plttOvershotBlocker,
    // Оружие двойной лазер
    plttWeaponDoubleLaser,
    // Блокиратор бытрых юнитовы
    plttSpeedBlocker,
    // Стабилизатор ЧТ
    plttWormholeGuard,
    // Строитель юнитов
    plttConstruction
  );

  // Элемент технологии словаря
  TPLShipTechItem = record
    // Поддерживаемость технологии
    Supported: Boolean;
    // Количество технологий
    Count: Integer;
    // Уровни
    Levels: array[0..5] of Integer;
    // Время отката
    Cooldowns: array[0..5] of Integer;
  end;

  // Купленные технологии
  PPlShipTechKeys = ^TPlShipTechKeys;
  TPlShipTechKeys = array[TPlShipTechType] of Integer;

  // Значения технологии для юнита
  PPLShipTechValues = ^TPLShipTechValues;
  TPLShipTechValues = array[TPlShipType] of TPlShipTechKeys;

  // Ссылка на технологии для юнита
  PPLShipTechUnit = ^TPLShipTechUnit;
  TPLShipTechUnit = array[TPlShipTechType] of TPLShipTechItem;

  // Ссылка на технологии для профиля
  PPLShipTechProfile = ^TPLShipTechProfile;
  TPLShipTechProfile = array[TPlShipType] of TPLShipTechUnit;

  // Словарь всех технологий
  TPLShipTechRace = array[TGlRaceType] of TPLShipTechProfile;

  // Упакованное количество кораблей
  TPlShipsCount = record
    case Integer of
    0: (
      Exist: Shortint;
      Active: Shortint;
    );
    1: (
      Value: Integer;
    );
  end;

  // Словарь кораблей, завязанных под пользователя
  TPlShipsCountDict = TDictionary<TGlPlayer, TPlShipsCount>;

  // Пара перебора словаря кораблей
  TPlShipsCountPair = TPair<TGlPlayer, TPlShipsCount>;

  // Список кораблей
  TPlShipList = TList<TPlShip>;

  // Тип, описывающий боевой кораблик
  TPlShip = class
  private var
    // Ссылка на технологии типа
    FTechUnit: PPLShipTechUnit;
    // Ссылка на технологии пользователя
    FTechKeys: PPlShipTechKeys;
  private
    // Признак нацеленного корабля
    function GetIsTargeted(): Boolean;
    // Установка прицела или сброс
    procedure SetIsTargeted(const AValue: Boolean);
  public var
    // Идентификатор кораблика
    ID: Integer;
    // Владелец кораблика
    Owner: TGlPlayer;
    // Планета, на которой находится кораблик
    Planet: TPlPlanet;
    // Тип кораблика
    ShipType: TPlShipType;
    // Режим
    Mode: TPlShipMode;
    // Состояние
    State: TPlShipState;
    // Количество
    Count: Integer;
    // Здоровье
    HP: Integer;
    // Слот на планете
    Landing: TPlLanding;
    // Орудийные системы
    Targets: TPlShipTargets;
    // Группа, в которой состоит кораблик
    Group: TPlShipGroup;
    // Текущая планета кораблике в списке планет группы
    GroupHope: Integer;
    // Количество топлива
    Fuel: Integer;
    // Набор таймеров
    Timer: array[TPlShipTimer] of Boolean;
    // Количество убитых стеков
    Destructed: Integer;
    // Планета, к которой привязан кораблик
    Attached: TPlPlanet;
    // Признак изменения состояния кораблика
    IsDestroyed: TPlShipDestroyed;
    // Признак, что кораблик захватывает планету
    IsCapture: Boolean;
    // Признак автоприцела
    IsAutoTarget: Boolean;
    // Признак автоаттача при прилете на планету
    IsAutoAttach: Boolean;
  public
    // Автовыход из группы
    destructor Destroy(); override;
    // Смена набора технологий
    procedure ChangeTech(ATechUnit: PPLShipTechUnit; ATechKeys: PPlShipTechKeys);
    // Смена группы кораблика
    procedure ChangeGroup(AGroup: TPlShipGroup = nil);
    // Возможность автоматического нацеливания арты
    function CanRangeAutoTarget(): Boolean;
    // Возможность взаимодействовать с кораблем
    function CanOperable(AIgnoreConstruct: Boolean = False): Boolean;
    // Значение технологии
    function TechValue(ATechType: TPlShipTechType): Integer;
    // Доступность технологии
    function TechActive(ATechType: TPlShipTechType): Boolean;
    // Время отката технологии
    function TechCooldown(ATechType: TPlShipTechType): Integer;
    // Признак что кораблик активен
    function IsStateActive(): Boolean;
    // Признак прикрепленной арты
    function IsAttachedRange(ARangeShip: Boolean): Boolean;
  public
    // Признак нацеленного кораблика
    property IsTargeted: Boolean
             read GetIsTargeted
             write SetIsTargeted;
  end;

  {$ENDREGION}

  {$REGION 'TPlShipGroup'}

  // Описание группы кораблей
  TPlShipGroup = class
  public var
    // Слоты, в которые составляются выбранные кораблики
    Slots: array[1..TPlLandings.I_FIGHT_COUNT] of TPlShip;
    // Позиция последнего добавленного корабля
    Position: TPlLanding;
    // Список кораблей в группе
    Ships: TPlShipList;
    // Список планет в пути перелета группы
    Planets: TPlPlanetList;
  public
    // Построение кораблей в защищенную коробку
    procedure DoSortByPriority();
    // Построение кораблей в сжатую группу
    { TODO -omdv : Групповое перемещение упростить сортировку }
    procedure DoSortBySlot();
  public
    // Загрузка данных группы с пакета
    constructor Create(APlanetList: TPlPlanetList; AShipList: TPlShipList);
    // Обнуление группы
    destructor Destroy(); override;
    // Удаление корабля из группы (убийство, перенос в ангар, смена пути)
    procedure Remove(AShip: TPlShip);
  end;
  // Список групп для обработки
  TPlShipGroupList = TList<TPlShipGroup>;

  // Подгруппы кораблей в группе, разбросанные по разным планетам
  PPlShipRowsLine = ^TPlShipRowsLine;
  TPlShipRowsLine = record
    // Текущая планета
    Source: TPlPlanet;
    // Следующая планета
    Destination: TPlPlanet;
    // Разрешен ли вылет подгруппе
    FlyState: TPlShipState;
    // Корабли подгруппы
    Ships: array[0..5] of TPlShip;
    // Количество кораблей в подгруппе
    Count: Integer;
  end;

  // Список подгрупп для перелета в группе
  TPLShipRows = class
  public var
    Lines: array[0..5] of TPlShipRowsLine;
    Count: Integer;
  end;

  {$ENDREGION}

  {$REGION 'TPlPlanet'}

  // Состояние планетоида
  TPlPlanetState = (
    // Активный планетоид
    plsActive,
    // Планетоид активируется
    plsActivation,
    // Планетоид неактивен
    plsInactive
  );

  // Типы планет
  TPlanetType = (
     // Маленькая
     pltSmall,
     // Обитаемая
     pltBig,
     // Звезда
     pltSun,
     // Гидросостав
     pltHydro,
     // Карлик
     pltRock,
     // Черная дыра
     pltHole,
     // Пульсар
     pltPulsar
  );

  // Таймеры корабля
  TPlPlanetTimer = (
    // Боевой тик
    ppltmBattle,
    // Тик пульсара
    ppltmPulsar,
    // Захват лояльности
    ppltmCapture,
    // Тик ЧТ
    ppltmWormhole
  );

  // Каллбак на таймер
  TPlPlanetTimerCallback = function(APlanet: TPlPlanet; var ACounter: Integer; var AValue: Integer): Boolean of object;

  // Тип описывающий планету
  TPlPlanet = class
    // Уникальный идентификатор в базе
    UID: Integer;
    // Ключ в списке
    ID: Integer;
    // Владелец планеты
    Owner: TGlPlayer;
    // Имя планеты
    Name: String;
    // Тип планеты
    PlanetType: TPlanetType;
    // Уровень энергии на планете
    Energy: Integer;
    // Уровень планеты
    Level: Integer;
    // Координаты на сетке по X
    CoordX: Integer;
    // Координаты на сетке по Y
    CoordY: Integer;
    // Дата обнаружения планеты
    DateDiscover: Integer;
    // Строения планеты
    Buildings: TPlBuildingList;
    // Хранилища планеты c объектами
    Storages: TPlStorages;
    // Список пустых доступных слотов
    StoragesFree: TIntegerList;
    // Список пустых слотов для транспорта
    StoragesInactive: TIntegerList;
    // Количество хранилищ
    StoragesCount: Integer;
    // Идентификатор захватчика
    CapturePlayer: TGlPlayer;
    // Уровень лояльности захватчика
    CaptureValue: Single;
    // Ресурс, вырабатываемый планетой
    ResFactory: TGlResourceType;
    // Количество ресурсов для выработки
    ResAvailIn: TResListData;
    // Количество свободного места для складирования
    ResAvailOut: TResListData;
    // Количество используемых ресурсов за такт времени
    ResUseIn: TResListData;
    // Количество выработки ресурсов за такт времени
    ResUseOut: TResListData;
    // Ресурсы, необходимые по цепочке
    ResTravel: TResListData;
    // Входящие торговые пути на планету
    ResPathIn: TPlPlanetList;
    // Исходящий торговый пути с планеты
    ResPathOut: TPlPlanet;
    // Признак включенного производства
    HaveProduction: Boolean;
    // Посадочные места планеты
    Landings: TPlLandings;
    // Список кораблей планеты
    Ships: TPlShipList;
    // Список количества кораблей каждого участника
    ShipCount: TPlShipsCountDict;
    // Список количества постройщиков каждого участника
    Constructors: TPlShipsCountDict;
    // Список внешних кораблей, нацеленных на планету
    RangeAttackers: TPlShipList;
    // Количество активных сервисок
    Services: Integer;
    // Набор таймеров
    Timer: array[TPlPlanetTimer] of Boolean;
    // Количество отрядов каждого игрока, определяющие полную видимость планетоида
    PlayerLightSoft: TPlShipsCountDict;
    // Количество отрядов каждого игрока, определяющие частичную видимость планетоида
    PlayerLightHard: TPlShipsCountDict;
    // Количество отрядов каждого игрока, которые определяют область закраски
    PlayerCoverage: TPlShipsCountDict;
    // Состояние активности планеты
    State: TPlPlanetState;
    // Время смены состояния планетоида
    StateTime: Integer;
    // Топливный запас
    Fuel: Integer;
    // Список соседних планет
    Links: TPlPlanetList;
    // Ссылка на портал для планеты
    Portal: TPlPortal;
    // Признак что планета захватывается
    InCapture: Boolean;
    // Включен гравитационный потенциал
    IsLowGravity: Boolean;
    // Признак что планета должна переприцелить корабли
    IsRetarget: Boolean;
    // Признак черной дыры
    IsBigHole: Boolean;
    // Признак округи черной дыры
    IsBigEdge: Boolean;
  public
    // Проверка расстояния между двумя объектами
    function IsValidDistance(ATarget: TPlPlanet): Boolean;
    // Признак обитаемой планеты
    function IsManned(): Boolean;
    // Определение видимости для игрока
    function VisibleByPlayer(APlayer: TGlPlayer; AHardLight: Boolean = False; AStrict: Boolean = False): Boolean;
    // Определение покрытия для игрока
    function CoverageByPlayer(APlayer: TGlPlayer; AFullData: Boolean; out AFriendCount, AEnemyCount: Integer): Integer;
    // Определения состояния для роли игрока
    function StateByVisible(AVisible: Boolean): TPlPlanetState;
  end;

  {$ENDREGION}

implementation

{$REGION 'TPlShip' }

destructor TPlShip.Destroy();
begin
  try
    // При уничтожении кораблика он сам выходит из группы
    ChangeGroup();
    inherited Destroy();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlShip.GetIsTargeted(): Boolean;
var
  TmpWeapon: TPlShipWeaponType;
begin
  Result := False;
  try
    for TmpWeapon := Low(TPlShipWeaponType) to High(TPlShipWeaponType) do
    begin
      if (Assigned(Targets[TmpWeapon])) then
        Exit(True);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlShip.SetIsTargeted(const AValue: Boolean);
var
  TmpWeapon: TPlShipWeaponType;
begin
  try
    if (not AValue) then
    begin
      for TmpWeapon := Low(TPlShipWeaponType) to High(TPlShipWeaponType) do
        Targets[TmpWeapon] := nil;
      IsAutoTarget := False;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlShip.TechActive(ATechType: TPlShipTechType): Boolean;
begin
  Result := False;
  try
    Result := (TechValue(ATechType) > 0);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlShip.TechCooldown(ATechType: TPlShipTechType): Integer;
begin
  Result := 0;
  try
    Result := FTechUnit[ATechType].Cooldowns[FTechKeys[ATechType]];
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlShip.TechValue(ATechType: TPlShipTechType): Integer;
begin
  Result := 0;
  try
    Result := FTechUnit[ATechType].Levels[FTechKeys[ATechType]];
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlShip.CanRangeAutoTarget(): Boolean;
begin
  Result := False;
  try
    Result := (TechActive(plttWeaponRocket))
      and (not Assigned(Attached))
      and (not Planet.Timer[ppltmBattle])
      and (IsStateActive);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlShip.CanOperable(AIgnoreConstruct: Boolean): Boolean;
begin
  Result := False;
  try
    Result := ((State = pshstIddle) or (State = pshstParking))
      and (AIgnoreConstruct or (Mode <> pshmdConstruction));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlShip.ChangeGroup(AGroup: TPlShipGroup);
begin
  try
    if (Assigned(Group)) then
      Group.Remove(Self);
    Group := AGroup;
    GroupHope := 0;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlShip.ChangeTech(ATechUnit: PPLShipTechUnit; ATechKeys: PPlShipTechKeys);
begin
  try
    FTechUnit := ATechUnit;
    FTechKeys := ATechKeys;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlShip.IsAttachedRange(ARangeShip: Boolean): Boolean;
begin
  Result := False;
  try
    Result := Assigned(Attached)
      and (Attached <> Planet)
      and (not ARangeShip or (TechActive(plttWeaponRocket)));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlShip.IsStateActive(): Boolean;
begin
  Result := False;
  try
    Result := (State = pshstIddle)
      and (Mode = pshmdActive);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

{$ENDREGION}

{$REGION 'TPlShipGroup' }

constructor TPlShipGroup.Create(APlanetList: TPlPlanetList; AShipList: TPlShipList);
var
  TmpShip: TPlShip;
begin
  try
    Planets := TPlPlanetList.Create(APlanetList);
    Ships := TPlShipList.Create(AShipList);
    for TmpShip in Ships do
      TmpShip.ChangeGroup(Self);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

destructor TPlShipGroup.Destroy();
begin
  try
    FreeAndNil(Ships);
    FreeAndNil(Planets);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlShipGroup.DoSortByPriority();
begin
end;

procedure TPlShipGroup.DoSortBySlot();
var
  TmpCount: Byte;
  TmpMax: Byte;
  TmpLast: Byte;
  TmpBorder: TPlLanding;
  TmpShip: TPlShip;
begin
  try
    TmpBorder := Position;
    TmpLast := Position;
    TmpCount := 0;
    TmpMax := 0;
    // Найдем максимальное количество пустых слотов
    repeat
      if (not Assigned(Slots[Position])) then
        Inc(TmpCount)
      else
      begin
        if (TmpCount > TmpMax) then
        begin
          TmpMax := TmpCount;
          TmpLast := Position;
        end;
        TmpCount := 0;
      end;
    until (Position.Dec() = TmpBorder);
    // На случай если прошли все шаги без проблем
    if (TmpCount > TmpMax) then
      TmpLast := Position;
    // Найдем все кораблики, с позиции последнего пустого слота
    TmpBorder := TmpLast;
    Position := TmpLast;

    Ships.Clear();

    repeat
      TmpShip := Slots[Position];
      if (Assigned(TmpShip)) then
        Ships.Add(TmpShip);
    until (Position.Dec() = TmpBorder);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlShipGroup.Remove(AShip: TPlShip);
begin
  try
    Ships.Remove(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

{$ENDREGION}

{$REGION 'TPlPlanet' }

function TPlPlanet.IsManned(): Boolean;
begin
  Result := False;
  try
    Result := (PlanetType = pltSmall)
      or (PlanetType = pltBig);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlPlanet.IsValidDistance(ATarget: TPlPlanet): Boolean;
begin
  Result := False;
  try
    Result := (Self = ATarget)
      or (Sqrt(Sqr(ATarget.CoordX - CoordX) + Sqr(ATarget.CoordY - CoordY)) <= 150);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlPlanet.VisibleByPlayer(APlayer: TGlPlayer; AHardLight: Boolean = False;
  AStrict: Boolean = False): Boolean;
var
  TmpDict: TPlShipsCountDict;
  TmpPair: TPlShipsCountPair;
begin
  Result := False;
  try
    // БЧТ и ее окраина всегда видима
    if (not AStrict and (IsBigHole or IsBigEdge)) then
      Exit(True);
    // Начнем подсчет количества ролей на планете
    Result := False;
    // Выберем словарь
    if (AHardLight) then
      TmpDict := PlayerLightHard
    else
      TmpDict := PlayerLightSoft;
    // Поищем все вхождения для соседей игрока
    for TmpPair in TmpDict do
    begin
      if (APlayer.IsRoleFriend(TmpPair.Key)) then
        Exit(True);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlPlanet.StateByVisible(AVisible: Boolean): TPlPlanetState;
begin
  Result := plsInactive;
  try
    // Состояние показываем только для ЧТ или видимых игроку планет
    if ((PlanetType = pltHole) and (State <> plsInactive))
      or (AVisible)
    then
      Result := State
    else
      Result := plsInactive;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlPlanet.CoverageByPlayer(APlayer: TGlPlayer; AFullData: Boolean;
  out AFriendCount, AEnemyCount: Integer): Integer;
var
  TmpPlayer: TGlPlayer;
begin
  Result := 0;
  AFriendCount := 0;
  AEnemyCount := 0;
  try
    // Поищем все карты контроля
    for TmpPlayer in PlayerCoverage.Keys do
    begin
      case TmpPlayer.Role(APlayer) of
        roleSelf:
          Inc(Result);
        roleEnemy:
          Inc(AEnemyCount);
        roleFriends:
          Inc(AFriendCount);
      end;
    end;
    // Если у игрока нет артефакта и есть противник - закрасим зону красным
    if (not AFullData) and (AEnemyCount > 0) then
    begin
      AFriendCount := 0;
      Result := 0;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

{$ENDREGION}

{$REGION 'TPlLandings' }

procedure TPlLandings.Add(AShip: TPlShip);
begin
  try
    FLandings[AShip.Landing] := AShip;
    AShip.Planet.Ships.Add(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlLandings.Remove(AShip: TPlShip);
begin
  try
    FLandings[AShip.Landing] := nil;
    AShip.Planet.Ships.Remove(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlLandings.IsEmpty(APosition: Integer): Boolean;
begin
  Result := False;
  try
    Result := (not Assigned(FLandings[APosition]));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlLandings.IsShip(APosition: Integer; var AShip: TPlShip): Boolean;
var
  TmpObject: TObject;
begin
  Result := False;
  try
    TmpObject := FLandings[APosition];
    Result := (TmpObject is TPlShip);
    if (Result) then
      AShip := (TmpObject as TPlShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

{$ENDREGION}

{$REGION 'TPlLandingHelper' }

function TPlLandingHelper.Inc(): TPlLanding;
begin
  Result := Self;
  try
    Self := Offset(Self + 1);
    Result := Self;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlLandingHelper.Dec(): TPlLanding;
begin
  Result := Self;
  try
    Self := Offset(Self - 1);
    Result := Self;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlLandingHelper.Next(): TPlLanding;
begin
  Result := Self;
  try
    Result := Offset(Self - 1);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlLandingHelper.Prev(): TPlLanding;
begin
  Result := Self;
  try
    Result := Offset(Self + 1);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlLandingHelper.IsLowOrbit(): Boolean;
begin
  Result := False;
  try
    Result := (Self > TPlLandings.I_FIGHT_COUNT);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class function TPlLandingHelper.Offset(AValue: Integer): TPlLanding;
begin
  Result := TPlLandings.I_FIGHT_COUNT;
  try
    if (AValue > TPlLandings.I_FIGHT_COUNT) then
      Result := AValue - TPlLandings.I_FIGHT_COUNT
    else
    if (AValue < 1) then
      Result := TPlLandings.I_FIGHT_COUNT + AValue
    else
      Result := AValue;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class function TPlLandingHelper.Valid(AValue: Integer): Boolean;
begin
  Result := False;
  try
    Result := (AValue >= 1) and (AValue <= TPlLandings.I_TOTAL_COUNT);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

{$ENDREGION}

{$REGION 'TPlBuilding' }

procedure TPlBuilding.ChangeTech(ATechUnit: PPLBuildingTechUnit; ATechKeys: PPlBuildingTechKeys);
begin
  try
    FTechUnit := ATechUnit;
    FTechKeys := ATechKeys;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

{$ENDREGION}

end.
