// пока хрень заглушка
unit SR.Planetar.Worker.Controller;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  Data.DB,

  SR.Planetar.Custom;

{type
  TWorkerController = class(TWorkerCustom)
  private const
    CS_SQL_SHIP_ADD       = 'select PlanetarShipAdd(:inPlanetID, :inSlotID, :inOwnerID, :inTypeID, :inRaceID, :inResID, :inResCount, :inEquipID, :inEquipCount, :inShipCount, :inHP, :inAttached, :inActive, :inTimeStamp, :inStateID, :inSystemId, :inPlanetTargetID) as result';
    CS_SQL_SHIP_CLEAR     = 'select PlanetarShipClear(:inSystemId) as result';
    CS_SQL_BUILDING_CLEAR = 'select PlanetarBuildingClear(:inSystemId) as result';
    CS_SQL_BUILDING_ADD   = 'select PlanetarBuildingAdd(:inSystemId, :inPlanetId, :inPosition, :inTypeId, :inLevel) as result';
    CS_SQL_STORAGE_CLEAR  = 'select PlanetarStorageClear(:inSystemId) as result';
    CS_SQL_STORAGE_ADD    = 'select PlanetarStorageAdd(:inSystemId, :inPlanetId, :inResourceId, :inCount, :inFlags, :inPosition) as result';
  private
    class procedure ShipClear();
    class procedure ShipAdd(AShip: TMapShip);
    class procedure PlanetBuildingClear();
    class procedure PlanetBuildingAdd(APlanetID: Integer; ABuilding: TBuilding);
    class procedure StorageClear();
    class procedure StorageAdd(APlanetID: Integer; AStorage: TStorage);
  public
    procedure Work(); override;
  end;
       }
implementation

{ TWorkerController }

{class procedure TWorkerController.PlanetBuildingAdd(
  APlanetID: Integer; ABuilding: TBuilding);
begin
  with TController.Instance.FDataAccess.Execute do
  begin
    SQL.Text := CS_SQL_BUILDING_ADD;
    Prepared := True;
      Params[0].AsInteger := 1;
      Params[1].AsInteger := APlanetID;
      Params[2].AsInteger := ABuilding.Position;
      Params[3].AsInteger := Integer(ABuilding.BuildingType);
      Params[4].AsInteger := ABuilding.Level;
    ExecSQL();
    Free();
  end;
end;

class procedure TWorkerController.PlanetBuildingClear();
begin
  with TController.Instance.FDataAccess.Execute do
  begin
    SQL.Text := CS_SQL_BUILDING_CLEAR;
    Prepared := True;
      Params[0].AsInteger := 1;
    ExecSQL();
    Free();
  end;
end;

class procedure TWorkerController.ShipAdd(AShip: TMapShip);
begin
  with TController.Instance.FDataAccess.Execute do
  begin
    SQL.Text := CS_SQL_SHIP_ADD;
    Prepared := True;
//      Params[0].AsInteger   := AShip.Planet.ID;
      Params[1].AsInteger   := AShip.Slot;
      Params[2].AsInteger   := AShip.Owner;
      Params[3].AsInteger   := Integer(AShip.ShipType);
      Params[4].AsInteger   := Integer(AShip.Race);
      Params[5].AsInteger   := AShip.ResID;
      Params[6].AsInteger   := AShip.ResCount;
      Params[7].AsInteger   := AShip.EquipID;
      Params[8].AsInteger   := AShip.EquipCount;
      Params[9].AsInteger   := AShip.Count;
      Params[10].AsInteger  := AShip.HP;
//      Params[11].AsInteger  := AShip.AttachedPlanet.ID;
      Params[12].AsInteger  := Ord(AShip.Active);
      Params[13].AsDateTime := AShip.TimeStamp;
      Params[14].AsInteger  := Integer(AShip.State);
      Params[15].AsInteger  := 1;
      if (Assigned(AShip.TargetPlanet)) then
  //      Params[16].AsInteger := AShip.TargetPlanet.ID
      else
        Params[16].Value := varNull;
    ExecSQL();
    Free();
  end;
end;

class procedure TWorkerController.ShipClear();
begin
  with TController.Instance.FDataAccess.Execute do
  begin
    SQL.Text := CS_SQL_SHIP_CLEAR;
    Prepared := True;
      Params[0].AsInteger := 1;
    ExecSQL();
    Free();
  end;
end;

class procedure TWorkerController.StorageAdd(APlanetID: Integer;
  AStorage: TStorage);
begin
  with TController.Instance.FDataAccess.Execute do
  begin
    SQL.Text := CS_SQL_STORAGE_ADD;
    Prepared := True;
      Params[0].AsInteger := 1;
      Params[1].AsInteger := APlanetID;
      Params[2].AsInteger := AStorage.Holder.ItemID;
      Params[3].AsInteger := AStorage.Holder.ItemCount;
      Params[4].AsInteger := AStorage.Flags;
      Params[5].AsInteger := AStorage.Position;
    ExecSQL();
    Free();
  end;
end;

class procedure TWorkerController.StorageClear;
begin
  with TController.Instance.FDataAccess.Execute do
  begin
    SQL.Text := CS_SQL_STORAGE_CLEAR;
    Prepared := True;
      Params[0].AsInteger := 1;
    ExecSQL();
    Free();
  end;
end;

class procedure TWorkerController.Work();
var
  TmpShip: TMapShip;
  TmpPLanet: TPlanet;
  TmpI: Integer;
  TmpStorage: TPair<Integer, TStorage>;
begin
exit;
  ShipClear();
  for TmpShip in Controller.MapShips do
    ShipAdd(TmpShip);

  PlanetBuildingClear();
  for TmpPLanet in Controller.Plnts do
    for TmpI in TmpPLanet.Buildings.Keys do
      PlanetBuildingAdd(TmpPLanet.Index, TmpPLanet.Buildings[TmpI]);

  StorageClear();
  for TmpPLanet in Controller.Plnts do
    for TmpStorage in TmpPLanet.Storages do
      StorageAdd(TmpPLanet.Index, TmpStorage.Value);
end;}

end.
