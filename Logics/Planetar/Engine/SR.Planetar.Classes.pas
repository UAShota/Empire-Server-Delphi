{**********************************************}
{                                              }
{ ������ ����������� ��������                  }
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
  // ������� ������ �� ��� �����
  TPlShip = class;
  TPlShipGroup = class;
  TPlPlanet = class;
  TPlPortal = class;

  { TODO -omdv : Resource �������� � ������ }
  TResListData = array[TGlResourceType] of Integer;

  // ��� ��� ������ ����� ��������
  TIntegerList = TList<Integer>;

  // ������ ������
  TPlPlanetList = TList<TPlPlanet>;

  // ������� ������, �� ������� �������� �����
  TPlClientsDict = TDictionary<TGlPlayer, TPlPlanetList>;
  // ���� ��� �������� ������� ������
  TPlClientsDictPair = TPair<TGlPlayer, TPlPlanetList>;

  {$REGION 'TPlStorage'}

  // ��� ����������� ������ �������
  TPlStorage = class
    // ������ ���������
    Holder: TGlStorageHolder;
    // ������� � ������ �����
    Position: Integer;
    // ������� ������������� �����
    Active: Boolean;
    // ���������
    Multiplier: Integer;
  end;

  // ������ ��������
  TPlStorages = TDictionary<Integer, TPlStorage>;
  TPlStoragesPair = TPair<Integer, TPlStorage>;

  {$ENDREGION}

  {$REGION 'TPlPortal'}

  // ������ ������������ �������
  TPlPortal = class
  public
    // ���������
    Owner: TGlPlayer;
    // ������� �����
    Enter: TPlPlanet;
    // ������� ������
    Exit: TPlPlanet;
    // ����� �����������
    Limit: Integer;
    // ����������� ��������
    Breakable: Boolean;
    // ������� �������� (��)
    FastTransfer: Boolean;
  end;

  {$ENDREGION}

  {$REGION 'TPlLanding'}

  // ��� ������������ �����
  TPlLanding = type Integer;
  // ������ ��� ���� ������������ �����
  TPlLandingHelper = record helper for TPlLanding
  public
    // ��������� ������� �� ��������� ����
    function Inc(): TPlLanding;
    // ��������� ������� �� ���������� ����
    function Dec(): TPlLanding;
    // ��������� �� ��������� ����
    function Next(): TPlLanding;
    // ��������� �� ���������� ����
    function Prev(): TPlLanding;
    // ������� ������ ������ �����
    function IsLowOrbit(): Boolean;
  public
    // ���� ��� ���������� ��������
    class function Offset(AValue: Integer): TPlLanding; static;
    // ���������� ������ �����
    class function Valid(AValue: Integer): Boolean; static;
  end;

  {$ENDREGION}

  {$REGION 'TPlLandings'}

  // ����� ����������� ���������� ����� ����������
  TPlLandings = record
  public const
    // ���������� ������ ������
    I_FIGHT_COUNT = 15;
    // ���������� ��������� ������
    I_TOTAL_COUNT = I_FIGHT_COUNT + 5;
  private var
    // ������ ���������� ����
    FLandings: array[1..I_TOTAL_COUNT] of TObject;
  public
    // ���������� ������� � ����
    procedure Add(AShip: TPlShip);
    // �������� ������� � �����
    procedure Remove(AShip: TPlShip);
    // �������� �� ������� �����
    function IsEmpty(APosition: Integer): Boolean;
    // �������� �� ������� �������
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

  // ���� ��������
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

  // ������ ������������
  TPlBuildingMode = (
    // ���������
    pbModePrimary,
    // ���������
    pbModeSecondary
  );

  // ���������� ��������
  TPlBuildingTechType = (
    // ��������� �������
    pttbBuyCost,
    // ��������� ��������
    pttbUpgradeCost,
    // ������� ��������� ��������
    pttbActive,
    // ������ � ��������� �������
    pttbEnergy,
    // ���������� ������� ���������� ����������
    pttbCapture,
    // ���������� 1 ������� ��� 1 ������
    pttbResInCount11,
    // ���������� 2 ������� ��� 1 ������
    pttbResInCount21,
    // ���������� 1 ������� ��� 2 ������
    pttbResInCount12,
    // ���������� 2 ������ ��� 2 ������
    pttbResInCount22,
    // ���������� ��������� ������� 1 ������
    pttbResOutCount1,
    // ���������� ��������� ������� 2 ������
    pttbResOutCount2,
    // ��� 1 ������� ��� 1 ������
    pttbResInId11,
    // ��� 2 ������� ��� 1 ������
    pttbResInId21,
    // ��� 1 ������� ��� 2 ������
    pttbResInId12,
    // ��� 2 ������� ��� 2 ������
    pttbResInId22,
    // ��� ��������� ������� ��� 1 ������
    pttbResOutId1,
    // ��� ��������� ������� ��� 1 ������
    pttbResOutId2
  );

  // ������� ���������� ��������
  TPlBuildingTechItem = record
    // �����������
    Supported: Boolean;
    // ���������� ����������
    Count: Integer;
    // ������
    Levels: array[0..5] of Integer;
  end;

  // ��������� ����������
  PPlBuildingTechKeys = ^TPlBuildingTechKeys;
  TPlBuildingTechKeys = array[TPlBuildingTechType] of Integer;

  // �������� ���������� ��� �����
  PPlBuildingTechValues = ^TPlBuildingTechValues;
  TPlBuildingTechValues = array[TPlBuildingType] of TPlBuildingTechKeys;

  // ������ �� ���������� ��� ��������
  PPlBuildingTechUnit = ^TPlBuildingTechUnit;
  TPlBuildingTechUnit = array[TPlBuildingTechType] of TPlBuildingTechItem;

  // ������ �� ���������� ��� �������
  PPlBuildingTechProfile = ^TPlBuildingTechProfile;
  TPlBuildingTechProfile = array[TPlBuildingType] of TPlBuildingTechUnit;

  // ������� ���� ����������
  TPlBuildingTechRace = array[TGlRaceType] of TPlBuildingTechProfile;

  // ��� ����������� ����������� ��������
  TPlBuilding = class
  private var
    // ������ �� ���������� ��������
    FTechUnit: PPlBuildingTechUnit;
    // ������ �� ����������� ����������� ���������
    FTechKeys: PPlBuildingTechKeys;
  public
    // ��� ������
    BuildingType: TPlBuildingType;
    // �������� ����� ������
    Mode: TPlBuildingMode;
    // �������
    Planet: TPlPlanet;
    // ������� ������
    Level: Integer;
    // ������� �������� ������������
    Position: Integer;
    // ������� �������������
    Active: Boolean;
    // ��������� ��������, 1000 ��������
    HP: Integer;
  public
      // ����� ������ ����������
    procedure ChangeTech(ATechUnit: PPLBuildingTechUnit; ATechKeys: PPlBuildingTechKeys);
  end;
  { TODO -omdv : Buildings �������� � ������ }
  // ������ ����������� �������� ��� ���������
  TPlBuildingList = TList<TPlBuilding>;

  {$ENDREGION}

  {$REGION 'TPlShip'}

  // ��������� �������
  TPlShipState = (
    // �����
    pshstIddle,
    // � �������� ����� �������
    pshstMovingLocal,
    // � �������� ����� ���������
    pshstMovingGlobal,
    // ���������
    pshstParking,
    // ��������� �������� � ������
    pshstPortalJump,
    // ����������� �����������
    pshstAnnihilation
  );

  // ����� �������
  TPlShipMode = (
    // �������
    pshmdActive,
    // ���������� � �����
    pshmdBlocked,
    // ����� ��� ���������
    pshmdFull,
    // � �������� ������
    pshmdOffline,
    // ���� �������������
    pshmdConstruction
  );

  // ������� �������
  TPlShipTimer = (
    // ���������
    pshtmOpConstruction,
    // ������ � ������
    pshtmOpPortalJump,
    // ����������
    pshtmOpRefill,
    // �����
    pshtmOpFlight,
    // ��������
    pshtmOpParking,
    // �����������
    pshtmOpAnnihilation,
    // �����������
    pshtmOpFix,
    // ������ ��������
    pshtmOpRepair,
    // ����� ������� �����
    pshtmCdConstructor
  );

  // ������� �� ������
  TPlShipTimerCallback = function(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean of object;

  // ��� �������
  TPlShipType = (
    // ������
    pshtpEmpty,
    // ���������
    pshtpTransport,
    // �����
    pshtpCruiser,
    // ��������
    pshtpDrednout,
    // ������
    pshtpCorvete,
    // ����������
    pshtpDevastator,
    // ���������
    pshtpInvader,
    // ������
    pshtpMillitary,
    // �����
    pshtpShipyard,
    // ������� ����
    pshtpScient,
    // ��������� ���������
    pshtpService,
    // �������
    pshtpFlagship
  );

  // ��� ����������� ��������
  TPlShipDestroyed = (
    // �����, �����
    pshchNone,
    // ���������
    pshchDestruct,
    // ���� �����
    pshchSilent
  );

  // ��� ��������� �������
  TPlShipWeaponType = (
    // �����������
    pswCenter,
    // �����
    pswLeft,
    // ������
    pswRight,
    // ������
    pswRocket
  );
  TPlShipTargets = array[TPlShipWeaponType] of TPlShip;

  // ���� ���������� ����������
  TPlShipTechType = (
    // ������ ����
    plttEmpty,
    // ������ ����
    plttWeaponBullet,
    // ����������� ���������
    plttActive,
    // �����������
    plttAnnihilation,
    // �����
    plttArmor,
    // ������ ������� �������������
    plttSolidBody,
    // ����
    plttCost,
    // ���������� � �����
    plttCount,
    // ��������� �����
    plttDamage,
    // �����������
    plttRepair,
    // ������� �����������
    plttHidden,
    // ���������
    plttHp,
    { TODO -omdv : ��������� ���������� }
    plttMirror,
    // ����������� ������
    plttStablePortal,
    // ��������� �������
    plttProduction,
    // ������� ������ ������
    plttFix,
    // ���������� ���������
    plttStorage,
    // ��� �����
    plttWeight,
    // ����� �������
    plttSkillConstructor,
    // ������ ������ �������������� �����������
    plttSkillConstructorEnemy,
    // ������ ������ � �������������� ���������
    plttSkillConstructorFriend,
    // ��������������
    plttStationary,
    // ��������� �����
    plttPriority,
    // ������������� ������ ������
    plttLowOrbit,
    // ���� � ����������
    plttFaster,
    // ������ �� ���� ��������� � ������ �������
    plttRangeDefence,
    // ������ ��������� ����� ����
    plttWeaponOvershot,
    // ����������� ����� � ���
    plttIntoBackzone,
    // ����������� ����������� � �����
    plttCornerBlock,
    // ������ ������� ����
    plttWeaponDoubleBullet,
    // ���� ��� ���������
    plttOvershotTarget,
    // ������ �����
    plttWeaponLaser,
    // ������ ������
    plttWeaponRocket,
    // ������ ����������
    plttCapturer,
    // ���������� ���������
    plttOvershotBlocker,
    // ������ ������� �����
    plttWeaponDoubleLaser,
    // ���������� ������ �������
    plttSpeedBlocker,
    // ������������ ��
    plttWormholeGuard,
    // ��������� ������
    plttConstruction
  );

  // ������� ���������� �������
  TPLShipTechItem = record
    // ���������������� ����������
    Supported: Boolean;
    // ���������� ����������
    Count: Integer;
    // ������
    Levels: array[0..5] of Integer;
    // ����� ������
    Cooldowns: array[0..5] of Integer;
  end;

  // ��������� ����������
  PPlShipTechKeys = ^TPlShipTechKeys;
  TPlShipTechKeys = array[TPlShipTechType] of Integer;

  // �������� ���������� ��� �����
  PPLShipTechValues = ^TPLShipTechValues;
  TPLShipTechValues = array[TPlShipType] of TPlShipTechKeys;

  // ������ �� ���������� ��� �����
  PPLShipTechUnit = ^TPLShipTechUnit;
  TPLShipTechUnit = array[TPlShipTechType] of TPLShipTechItem;

  // ������ �� ���������� ��� �������
  PPLShipTechProfile = ^TPLShipTechProfile;
  TPLShipTechProfile = array[TPlShipType] of TPLShipTechUnit;

  // ������� ���� ����������
  TPLShipTechRace = array[TGlRaceType] of TPLShipTechProfile;

  // ����������� ���������� ��������
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

  // ������� ��������, ���������� ��� ������������
  TPlShipsCountDict = TDictionary<TGlPlayer, TPlShipsCount>;

  // ���� �������� ������� ��������
  TPlShipsCountPair = TPair<TGlPlayer, TPlShipsCount>;

  // ������ ��������
  TPlShipList = TList<TPlShip>;

  // ���, ����������� ������ ��������
  TPlShip = class
  private var
    // ������ �� ���������� ����
    FTechUnit: PPLShipTechUnit;
    // ������ �� ���������� ������������
    FTechKeys: PPlShipTechKeys;
  private
    // ������� ����������� �������
    function GetIsTargeted(): Boolean;
    // ��������� ������� ��� �����
    procedure SetIsTargeted(const AValue: Boolean);
  public var
    // ������������� ���������
    ID: Integer;
    // �������� ���������
    Owner: TGlPlayer;
    // �������, �� ������� ��������� ��������
    Planet: TPlPlanet;
    // ��� ���������
    ShipType: TPlShipType;
    // �����
    Mode: TPlShipMode;
    // ���������
    State: TPlShipState;
    // ����������
    Count: Integer;
    // ��������
    HP: Integer;
    // ���� �� �������
    Landing: TPlLanding;
    // ��������� �������
    Targets: TPlShipTargets;
    // ������, � ������� ������� ��������
    Group: TPlShipGroup;
    // ������� ������� ��������� � ������ ������ ������
    GroupHope: Integer;
    // ���������� �������
    Fuel: Integer;
    // ����� ��������
    Timer: array[TPlShipTimer] of Boolean;
    // ���������� ������ ������
    Destructed: Integer;
    // �������, � ������� �������� ��������
    Attached: TPlPlanet;
    // ������� ��������� ��������� ���������
    IsDestroyed: TPlShipDestroyed;
    // �������, ��� �������� ����������� �������
    IsCapture: Boolean;
    // ������� �����������
    IsAutoTarget: Boolean;
    // ������� ���������� ��� ������� �� �������
    IsAutoAttach: Boolean;
  public
    // ��������� �� ������
    destructor Destroy(); override;
    // ����� ������ ����������
    procedure ChangeTech(ATechUnit: PPLShipTechUnit; ATechKeys: PPlShipTechKeys);
    // ����� ������ ���������
    procedure ChangeGroup(AGroup: TPlShipGroup = nil);
    // ����������� ��������������� ����������� ����
    function CanRangeAutoTarget(): Boolean;
    // ����������� ����������������� � ��������
    function CanOperable(AIgnoreConstruct: Boolean = False): Boolean;
    // �������� ����������
    function TechValue(ATechType: TPlShipTechType): Integer;
    // ����������� ����������
    function TechActive(ATechType: TPlShipTechType): Boolean;
    // ����� ������ ����������
    function TechCooldown(ATechType: TPlShipTechType): Integer;
    // ������� ��� �������� �������
    function IsStateActive(): Boolean;
    // ������� ������������� ����
    function IsAttachedRange(ARangeShip: Boolean): Boolean;
  public
    // ������� ����������� ���������
    property IsTargeted: Boolean
             read GetIsTargeted
             write SetIsTargeted;
  end;

  {$ENDREGION}

  {$REGION 'TPlShipGroup'}

  // �������� ������ ��������
  TPlShipGroup = class
  public var
    // �����, � ������� ������������ ��������� ���������
    Slots: array[1..TPlLandings.I_FIGHT_COUNT] of TPlShip;
    // ������� ���������� ������������ �������
    Position: TPlLanding;
    // ������ �������� � ������
    Ships: TPlShipList;
    // ������ ������ � ���� �������� ������
    Planets: TPlPlanetList;
  public
    // ���������� �������� � ���������� �������
    procedure DoSortByPriority();
    // ���������� �������� � ������ ������
    { TODO -omdv : ��������� ����������� ��������� ���������� }
    procedure DoSortBySlot();
  public
    // �������� ������ ������ � ������
    constructor Create(APlanetList: TPlPlanetList; AShipList: TPlShipList);
    // ��������� ������
    destructor Destroy(); override;
    // �������� ������� �� ������ (��������, ������� � �����, ����� ����)
    procedure Remove(AShip: TPlShip);
  end;
  // ������ ����� ��� ���������
  TPlShipGroupList = TList<TPlShipGroup>;

  // ��������� �������� � ������, ������������ �� ������ ��������
  PPlShipRowsLine = ^TPlShipRowsLine;
  TPlShipRowsLine = record
    // ������� �������
    Source: TPlPlanet;
    // ��������� �������
    Destination: TPlPlanet;
    // �������� �� ����� ���������
    FlyState: TPlShipState;
    // ������� ���������
    Ships: array[0..5] of TPlShip;
    // ���������� �������� � ���������
    Count: Integer;
  end;

  // ������ �������� ��� �������� � ������
  TPLShipRows = class
  public var
    Lines: array[0..5] of TPlShipRowsLine;
    Count: Integer;
  end;

  {$ENDREGION}

  {$REGION 'TPlPlanet'}

  // ��������� ����������
  TPlPlanetState = (
    // �������� ���������
    plsActive,
    // ��������� ������������
    plsActivation,
    // ��������� ���������
    plsInactive
  );

  // ���� ������
  TPlanetType = (
     // ���������
     pltSmall,
     // ���������
     pltBig,
     // ������
     pltSun,
     // �����������
     pltHydro,
     // ������
     pltRock,
     // ������ ����
     pltHole,
     // �������
     pltPulsar
  );

  // ������� �������
  TPlPlanetTimer = (
    // ������ ���
    ppltmBattle,
    // ��� ��������
    ppltmPulsar,
    // ������ ����������
    ppltmCapture,
    // ��� ��
    ppltmWormhole
  );

  // ������� �� ������
  TPlPlanetTimerCallback = function(APlanet: TPlPlanet; var ACounter: Integer; var AValue: Integer): Boolean of object;

  // ��� ����������� �������
  TPlPlanet = class
    // ���������� ������������� � ����
    UID: Integer;
    // ���� � ������
    ID: Integer;
    // �������� �������
    Owner: TGlPlayer;
    // ��� �������
    Name: String;
    // ��� �������
    PlanetType: TPlanetType;
    // ������� ������� �� �������
    Energy: Integer;
    // ������� �������
    Level: Integer;
    // ���������� �� ����� �� X
    CoordX: Integer;
    // ���������� �� ����� �� Y
    CoordY: Integer;
    // ���� ����������� �������
    DateDiscover: Integer;
    // �������� �������
    Buildings: TPlBuildingList;
    // ��������� ������� c ���������
    Storages: TPlStorages;
    // ������ ������ ��������� ������
    StoragesFree: TIntegerList;
    // ������ ������ ������ ��� ����������
    StoragesInactive: TIntegerList;
    // ���������� ��������
    StoragesCount: Integer;
    // ������������� ����������
    CapturePlayer: TGlPlayer;
    // ������� ���������� ����������
    CaptureValue: Single;
    // ������, �������������� ��������
    ResFactory: TGlResourceType;
    // ���������� �������� ��� ���������
    ResAvailIn: TResListData;
    // ���������� ���������� ����� ��� �������������
    ResAvailOut: TResListData;
    // ���������� ������������ �������� �� ���� �������
    ResUseIn: TResListData;
    // ���������� ��������� �������� �� ���� �������
    ResUseOut: TResListData;
    // �������, ����������� �� �������
    ResTravel: TResListData;
    // �������� �������� ���� �� �������
    ResPathIn: TPlPlanetList;
    // ��������� �������� ���� � �������
    ResPathOut: TPlPlanet;
    // ������� ����������� ������������
    HaveProduction: Boolean;
    // ���������� ����� �������
    Landings: TPlLandings;
    // ������ �������� �������
    Ships: TPlShipList;
    // ������ ���������� �������� ������� ���������
    ShipCount: TPlShipsCountDict;
    // ������ ���������� ������������ ������� ���������
    Constructors: TPlShipsCountDict;
    // ������ ������� ��������, ���������� �� �������
    RangeAttackers: TPlShipList;
    // ���������� �������� ��������
    Services: Integer;
    // ����� ��������
    Timer: array[TPlPlanetTimer] of Boolean;
    // ���������� ������� ������� ������, ������������ ������ ��������� ����������
    PlayerLightSoft: TPlShipsCountDict;
    // ���������� ������� ������� ������, ������������ ��������� ��������� ����������
    PlayerLightHard: TPlShipsCountDict;
    // ���������� ������� ������� ������, ������� ���������� ������� ��������
    PlayerCoverage: TPlShipsCountDict;
    // ��������� ���������� �������
    State: TPlPlanetState;
    // ����� ����� ��������� ����������
    StateTime: Integer;
    // ��������� �����
    Fuel: Integer;
    // ������ �������� ������
    Links: TPlPlanetList;
    // ������ �� ������ ��� �������
    Portal: TPlPortal;
    // ������� ��� ������� �������������
    InCapture: Boolean;
    // ������� �������������� ���������
    IsLowGravity: Boolean;
    // ������� ��� ������� ������ ������������� �������
    IsRetarget: Boolean;
    // ������� ������ ����
    IsBigHole: Boolean;
    // ������� ������ ������ ����
    IsBigEdge: Boolean;
  public
    // �������� ���������� ����� ����� ���������
    function IsValidDistance(ATarget: TPlPlanet): Boolean;
    // ������� ��������� �������
    function IsManned(): Boolean;
    // ����������� ��������� ��� ������
    function VisibleByPlayer(APlayer: TGlPlayer; AHardLight: Boolean = False; AStrict: Boolean = False): Boolean;
    // ����������� �������� ��� ������
    function CoverageByPlayer(APlayer: TGlPlayer; AFullData: Boolean; out AFriendCount, AEnemyCount: Integer): Integer;
    // ����������� ��������� ��� ���� ������
    function StateByVisible(AVisible: Boolean): TPlPlanetState;
  end;

  {$ENDREGION}

implementation

{$REGION 'TPlShip' }

destructor TPlShip.Destroy();
begin
  try
    // ��� ����������� ��������� �� ��� ������� �� ������
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
    // ������ ������������ ���������� ������ ������
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
    // �� ������ ���� ������ ��� ���� ��� �������
    if (TmpCount > TmpMax) then
      TmpLast := Position;
    // ������ ��� ���������, � ������� ���������� ������� �����
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
    // ��� � �� ������� ������ ������
    if (not AStrict and (IsBigHole or IsBigEdge)) then
      Exit(True);
    // ������ ������� ���������� ����� �� �������
    Result := False;
    // ������� �������
    if (AHardLight) then
      TmpDict := PlayerLightHard
    else
      TmpDict := PlayerLightSoft;
    // ������ ��� ��������� ��� ������� ������
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
    // ��������� ���������� ������ ��� �� ��� ������� ������ ������
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
    // ������ ��� ����� ��������
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
    // ���� � ������ ��� ��������� � ���� ��������� - �������� ���� �������
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
