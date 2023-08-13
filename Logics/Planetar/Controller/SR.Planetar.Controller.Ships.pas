{**********************************************}
{                                              }
{ Модуль управления планетарным флотом         }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev A  2017.03.05
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Planetar.Controller.Ships;

interface

uses
  System.Generics.Collections,
  System.Math,
  System.SysUtils,

  SR.DataAccess,
  SR.Engine.Server,
  SR.Globals.Player,
  SR.Globals.Types,
  SR.Planetar.Custom,
  SR.Planetar.Classes,
  SR.Planetar.Dictionary,

  SR.PL.Ships.Custom,
  SR.PL.Ships.AddToPlanet,
  SR.PL.Ships.Annihilation,
  SR.PL.Ships.Attach,
  SR.PL.Ships.Battle,
  SR.PL.Ships.Capture,
  SR.PL.Ships.ChangeActivity,
  SR.PL.Ships.Fly,
  SR.PL.Ships.Construct,
  SR.PL.Ships.Destruct,
  SR.PL.Ships.Escape,
  SR.PL.Ships.Group,
  SR.PL.Ships.Hypodispersion,
  SR.PL.Ships.JumpToPlanet,
  SR.PL.Ships.Merge,
  SR.PL.Ships.MoveFromHangar,
  SR.PL.Ships.MoveToHangar,
  SR.PL.Ships.MoveToPlanet,
  SR.PL.Ships.Fuel,
  SR.PL.Ships.Portal,
  SR.PL.Ships.RemoveFromPlanet,
  SR.PL.Ships.Repair,
  SR.PL.Ships.Retarget,
  SR.PL.Ships.Separate,
  SR.PL.Ships.StandDown,
  SR.PL.Ships.StandUp,
  SR.PL.Ships.Skill.Construct,
  SR.PL.Ships.TargetLocal,
  SR.PL.Ships.TargetMarker;

type
  TPlanetarShipsController = class(TPlanetarCustom)
  public var
    AddToPlanet: TPLShipsControlAddToPlanet;
    Attach: TPLShipsControlAttach;
    Annihilation: TPLShipsControlAnnihilation;
    Battle: TPLShipsControlBattle;
    Capture: TPLShipsControlCapture;
    Fly: TPLShipsControlFly;
    ChangeActivity: TPLShipsControlChangeActivity;
    Construct: TPLShipsControlConstruct;
    Destruct: TPLShipsControlDestruct;
    Escape: TPLShipsControlEscape;
    Fuel: TPLShipsControlFuel;
    Group: TPLShipsControlGroup;
    Hypodispersion: TPLShipsControlHypodispersion;
    JumpToPlanet: TPLShipsControlJumpToPlanet;
    Merge: TPLShipsControlMerge;
    MoveFromHangar: TPLShipsControlMoveFromHangar;
    MoveToHangar: TPLShipsControlMoveToHangar;
    MoveToPlanet: TPLShipsControlMoveToPlanet;
    Portal: TPLShipsControlPortal;
    RemoveFromPlanet: TPLShipsControlRemoveFromPlanet;
    Repair: TPLShipsControlRepair;
    StandUp: TPLShipsControlStandUp;
    StandDown: TPLShipsControlStandDown;
    Separate: TPLShipsControlSeparate;
    SkillConstruct: TPLShipsControlSkillConstruct;
    Retarget: TPLShipsControlRetarget;
    TargetLocal: TPLShipsControlTargetLocal;
    TargetMarker: TPLShipsControlTargetMarker;
  public
    ListShips: TPlShipList;
  private
    // Загрузка корабликов
    procedure DoLoadShips();
    procedure DoLoadBattles(APlanet: TPlPlanet);
    procedure DoLoadPlayerControl(APlanet: TPlPlanet);
  public
    constructor Create(AEngine: TObject); override;
    destructor Destroy(); override;
    procedure Start(); override;
  end;

implementation

uses
  SR.Planetar.Profile,
  SR.Planetar.Thread;

constructor TPlanetarShipsController.Create(AEngine: TObject);
begin
  inherited;

  ListShips := TPlShipList.Create();

  AddToPlanet := TPLShipsControlAddToPlanet.Create(AEngine);
  Annihilation := TPLShipsControlAnnihilation.Create(AEngine);
  Attach := TPLShipsControlAttach.Create(AEngine);
  Battle := TPLShipsControlBattle.Create(AEngine);
  Capture := TPLShipsControlCapture.Create(AEngine);
  Fly := TPLShipsControlFly.Create(AEngine);
  ChangeActivity := TPLShipsControlChangeActivity.Create(AEngine);
  Construct := TPLShipsControlConstruct.Create(AEngine);
  Destruct := TPLShipsControlDestruct.Create(AEngine);
  Escape := TPLShipsControlEscape.Create(AEngine);
  Fuel := TPLShipsControlFuel.Create(AEngine);
  Group := TPLShipsControlGroup.Create(AEngine);
  Hypodispersion := TPLShipsControlHypodispersion.Create(AEngine);
  JumpToPlanet := TPLShipsControlJumpToPlanet.Create(AEngine);
  Merge := TPLShipsControlMerge.Create(AEngine);
  MoveToPlanet := TPLShipsControlMoveToPlanet.Create(AEngine);
  MoveFromHangar := TPLShipsControlMoveFromHangar.Create(AEngine);
  MoveToHangar := TPLShipsControlMoveToHangar.Create(AEngine);
  Portal := TPLShipsControlPortal.Create(AEngine);
  RemoveFromPlanet := TPLShipsControlRemoveFromPlanet.Create(AEngine);
  Repair := TPLShipsControlRepair.Create(AEngine);
  Retarget := TPLShipsControlRetarget.Create(AEngine);
  Separate := TPLShipsControlSeparate.Create(AEngine);
  SkillConstruct := TPLShipsControlSkillConstruct.Create(AEngine);
  StandDown := TPLShipsControlStandDown.Create(AEngine);
  StandUp := TPLShipsControlStandUp.Create(AEngine);
  TargetLocal := TPLShipsControlTargetLocal.Create(AEngine);
  TargetMarker := TPLShipsControlTargetMarker.Create(AEngine);
end;

destructor TPlanetarShipsController.Destroy();
begin
  FreeAndNil(AddToPlanet);
  FreeAndNil(Annihilation);
  FreeAndNil(Attach);
  FreeAndNil(Battle);
  FreeAndNil(Capture);
  FreeAndNil(Fly);
  FreeAndNil(Construct);
  FreeAndNil(Destruct);
  FreeAndNil(Escape);
  FreeAndNil(Fuel);
  FreeAndNil(Group);
  FreeAndNil(Hypodispersion);
  FreeAndNil(JumpToPlanet);
  FreeAndNil(Merge);
  FreeAndNil(MoveFromHangar);
  FreeAndNil(MoveToHangar);
  FreeAndNil(MoveToPlanet);
  FreeAndNil(Portal);
  FreeAndNil(RemoveFromPlanet);
  FreeAndNil(Repair);
  FreeAndNil(Retarget);
  FreeAndNil(Separate);
  FreeAndNil(SkillConstruct);
  FreeAndNil(StandUp);
  FreeAndNil(StandDown);
  FreeAndNil(TargetLocal);
  FreeAndNil(TargetMarker);

  FreeAndNil(ListShips);

  inherited;
end;

procedure TPlanetarShipsController.Start();
var
  TmpPlanet: TPlPlanet;
begin
  DoLoadShips();

  for TmpPlanet in TPlanetarThread(Engine).ControlPlanets.ListPlanets do
  begin
    DoLoadBattles(TmpPlanet);
    DoLoadPlayerControl(TmpPlanet);
  end;
end;

procedure TPlanetarShipsController.DoLoadShips();
var
  TmpShip: TPlShip;
  TmpID: Integer;
begin
  with TDataAccess.Call('PLLoadShips', [TPlanetarThread(Engine).Player.UID]) do
  try
    while ReadRow() do
    begin
      TmpShip := TPlShip.Create();
      TmpShip.ID := ListShips.Count;
      TmpShip.Owner := TEngineServer.FindPlayer(ReadInteger('ID_OWNER'));
      TmpShip.Planet := TPlanetarThread(Engine).ControlPlanets.PlanetByRaw(ReadInteger('ID_PLANET'));
      TmpShip.ShipType := TPlShipType(ReadInteger('ID_TYPE') - 1);
      TmpShip.Landing := ReadInteger('ID_SLOT');
      TmpShip.Mode := TPlShipMode(ReadInteger('MODE') - 1);
      TmpShip.Count := ReadInteger('COUNT');
      TmpShip.HP := ReadInteger('HP');
      // Пропишем техи
      TmpShip.ChangeTech(
        @TPlanetarProfile(TmpShip.Owner.PlanetarProfile).TechShipProfile[TmpShip.ShipType],
        @TPlanetarProfile(TmpShip.Owner.PlanetarProfile).TechShipValues[TmpShip.ShipType]);
      // Добавим в список
      ListShips.Add(TmpShip);
      // Добавим на планету
      AddToPlanet.Execute(TmpShip, TmpShip.Planet, True, False, True);
      // Пропишем аттач
      TmpID := ReadInteger('ID_PLANET_ATTACH');
      if (TmpID > 0) then
        Attach.Execute(TmpShip, TPlanetarThread(Engine).ControlPlanets.PlanetByRaw(ReadInteger('ID_PLANET_ATTACH')), False);
    end;
  finally
    Free();
  end;
end;

procedure TPlanetarShipsController.DoLoadBattles(APlanet: TPlPlanet);
begin
  if (APlanet.Ships.Count > 0) then
  begin
    APlanet.IsRetarget := True;
    TPlanetarThread(Engine).ControlPlanets.Battle.Execute(APlanet);
  end;
end;

procedure TPlanetarShipsController.DoLoadPlayerControl(APlanet: TPlPlanet);
begin
  if (APlanet.Owner.UID <> 1) then
    TPlanetarThread(Engine).ControlPlanets.PlayerControlChange(APlanet, APlanet.Owner, True, False);
end;

end.
