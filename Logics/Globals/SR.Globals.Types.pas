{**********************************************}
{                                              }
{           ������ ����� �����                 }
{       Copyright (c) 2016 UAShota              }
{                                              }
{   Rev B  2017.03.30                          }
{**********************************************}
unit SR.Globals.Types;

interface

uses
  System.Generics.Collections;

type
  // ��� ������� � �����-���� �����
  TGlSlotObjectType = (
    gsotEmpty,
    gsotResource,
    gsotEquipment
  );

  // ���� ���������� ��������
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

  // �������� ����������� �������
  TGlResourceInfo = record
    // ������������ ���������� � �����
    Max: Integer;
  end;
  // ������ �������� ����������� ��������
  TGlResourcesList = array[TGlResourceType] of TGlResourceInfo;

  // ���� ���������
  TGlStorageHolder = class(TObject)
  public const
    // �������� ������ ��� �������� ������
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
  // ������ ������ ���������
  TGlStorageList = array[1..TGlStorageHolder.MaxPersonalStorages] of TGlStorageHolder;

  // ���� ������� ���
  TGlRaceType = (
    raceEmpty,
    raceHuman,
    raceMaloc,
    racePeleng,
    raceGaal,
    raceFeyan,
    raceKlisan
  );

  // �������� ����
  TGlRaceInfo = record

  end;
  // ������ �������� ����������� ���
  TGlRaceList = array[TGlRaceType] of TGlRaceInfo;

  // ���� ������� ������������ ����-�����
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
