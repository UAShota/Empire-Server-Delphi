{**********************************************}
{                                              }
{           Модуль общих типов                 }
{       Copyright (c) 2016 UAShota              }
{                                              }
{   Rev B  2017.03.30                          }
{**********************************************}
unit SR.Globals.Types;

interface

uses
  System.Generics.Collections;

type
  // Тип объекта в каком-либо слоте
  TGlSlotObjectType = (
    gsotEmpty,
    gsotResource,
    gsotEquipment
  );

  // Типы глобальных ресурсов
  TGlResourceType = (
    resEmpty,
    resVodorod,
    resXenon,
    resModules,
    resFuel,
    resGold,
    resTitan,
    resKremniy,
    resAntikristals,
    resAntimatery,
    resMetall,
    resElectronic,
    resFood,
    resProtoplazma,
    resPlazma
  );

  // Описание глобального ресурса
  TGlResourceInfo = record
    // Максимальное количество в стеке
    Max: Integer;
  end;
  // Список описаний загруженных ресурсов
  TGlResourcesList = array[TGlResourceType] of TGlResourceInfo;

  // Слот хранилища
  TGlStorageHolder = class(TObject)
  public const
    // Максимум слотов для хранилща игрока
    MaxPersonalStorages = 100;
  public var
    Resource: TGlResourceType;
    ResourceType: TGlSlotObjectType;
    Count: Integer;
    Personal: Boolean;
  public
    constructor Create();
    procedure Update(AStorage: TGlStorageHolder);
  end;
  // Список слотов хранилища
  TGlStorageList = array[1..TGlStorageHolder.MaxPersonalStorages] of TGlStorageHolder;

  // Типы игровых рас
  TGlRaceType = (
    raceEmpty,
    raceHuman,
    raceMaloc,
    racePeleng,
    raceGaal,
    raceFeyan,
    raceKlisan
  );

  // Описание расы
  TGlRaceInfo = record

  end;
  // Список описаний загруженных рас
  TGlRaceList = array[TGlRaceType] of TGlRaceInfo;

  // Роли игроков относительно друг-друга
  TGlPlayerRole = (
  	roleSelf,
	  roleEnemy,
    roleFriends,
	  roleNeutral
  );

implementation

{ TGlobalsStorageInfo }

constructor TGlStorageHolder.Create();
begin
  Resource := resEmpty;
end;

procedure TGlStorageHolder.Update(AStorage: TGlStorageHolder);
begin
  Resource := AStorage.Resource;
  ResourceType := AStorage.ResourceType;
  Count := AStorage.Count;
  Personal := AStorage.Personal;
end;

end.
