{**********************************************}
{                                              }
{ ���� : ����� �������                         }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Custom;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes;

type
  // ����� ��������� ����� ������� �����
  TPLShipsControlCustom = class
  protected const
    I_MAX_SHIP_COUNT = 6;
    I_MAX_SHIP_ACTIVE = I_MAX_SHIP_COUNT - 1;
    I_MAX_SHIP_REFILL = I_MAX_SHIP_ACTIVE - 1;
    I_MAX_FUEL_COUNT = 5;
    I_FUEL_FOR_HANGAR = 2;
  protected var
    // ������ ����������� �������
    Engine: TObject;
  protected
    // �������� ������� �������
    function CreateShip(APlanet: TPlPlanet; AShipType: TPlShipType; ASlot, ACount: Integer;
      APlayer: TGlPlayer): TPlShip;
    // �����������, �������� �� �������� �����������
    function CheckShipBlocker(AShip: TPlShip; ASlot: TPlLanding; AEnemy: Boolean;
      AWantMode: TPlShipMode): TPlShip;
    // ����� ��������� �������, ������� ����� �������� ������������
    function CheckShipSide(ADestination: TPlPlanet; ASlot: TPlLanding;
      AWantMode: TPlShipMode): TPlShip;
    // �������� ����������� ������� ������� �� ������
    function CheckArrival(ADestination: TPlPlanet; AShipLowOrbit: Boolean;
      ASlotFrom, ASlotTo: TPlLanding; AShipPlanet: TPlPlanet; AShipOwner: TGlPlayer;
      ACheckOnePlanet: Boolean): Boolean;
    // �������� �� ����������� ������� � ���
    function CheckMoveTo(AShip: TPlShip; ADestination: TPlPlanet; ASlotTo: Integer;
      ACheckOnePlanet: Boolean): Boolean;
    // �������� ����������� ������� ������� �� ����
    function CheckBackZone(AIgnoreBackZone: Boolean; ADestination: TPlPlanet; ASlot: TPlLanding;
      AOwner: TGlPlayer): Boolean;
    // �������� ��������� ����
    function GetFreeSlot(AIgnore: Boolean; ADestination: TPlPlanet; AShipLowOrbit: Boolean;
      AOwner: TGlPlayer): TPlLanding;
    // ��������� ����� �����
    function DealDamage(AShip: TPlShip; ADamage: Integer; ADestruct: Boolean = True): Integer;
    // ���������� �� ��� �������� ������� �����
    procedure WorkShipHP(APlanet: TPlPlanet);
  public
    // �������� ����������� ��� ���������� ���������
    constructor Create(AEngine: TObject);
  end;

implementation

uses
  SR.Planetar.Thread,
  SR.Planetar.Profile,
  SR.Planetar.Dictionary;

constructor TPLShipsControlCustom.Create(AEngine: TObject);
begin
  inherited Create();

  Engine := AEngine;
end;

function TPLShipsControlCustom.CreateShip(APlanet: TPlPlanet; AShipType: TPlShipType;
  ASlot, ACount: Integer; APlayer: TGlPlayer): TPlShip;
var
  TmpProfile: TPlanetarProfile;
begin
  TmpProfile := TPlanetarProfile(APlayer.PlanetarProfile);
  Result := nil;
  try
    Result := TPlShip.Create();
    Result.ID := TPlanetarThread(Engine).ControlShips.ListShips.Count;
    Result.ShipType := AShipType;
    Result.ChangeTech(@TmpProfile.TechShipProfile[AShipType], @TmpProfile.TechShipValues[AShipType]);
    Result.Planet := APlanet;
    Result.Owner := APlayer;
    Result.Planet := APlanet;
    Result.Count := ACount;
    Result.HP := Result.TechValue(plttHp);
    Result.Fuel := I_MAX_FUEL_COUNT;
    Result.Landing := ASlot;
    // ������� � ������ ����������
    TPlanetarThread(Engine).ControlShips.ListShips.Add(Result);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.GetFreeSlot(AIgnore: Boolean; ADestination: TPlPlanet;
  AShipLowOrbit: Boolean; AOwner: TGlPlayer): TPlLanding;
var
  TmpSlot: TPlLanding;
begin
  Result := 0;
  try
    TmpSlot := 1;
    repeat
      // ������� ����� ���������� ����
      if (AShipLowOrbit) then
        TmpSlot.Dec()
      else
        TmpSlot.Inc();
      // �������� ����� ���� ��� ������ � �� �����
      if (ADestination.Landings.IsEmpty(TmpSlot))
        and (CheckBackZone(AIgnore, ADestination, TmpSlot, AOwner))
      then
        Exit(TmpSlot);
    until (TmpSlot = 1);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.CheckMoveTo(AShip: TPlShip; ADestination: TPlPlanet;
  ASlotTo: Integer; ACheckOnePlanet: Boolean): Boolean;
begin
  Result := False;
  try
    Result := CheckArrival(ADestination, AShip.TechActive(plttLowOrbit), AShip.Landing, ASlotTo, AShip.Planet, AShip.Owner, ACheckOnePlanet)
      and CheckBackZone(AShip.TechActive(plttIntoBackzone), ADestination, ASlotTo, AShip.Owner);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.CheckShipBlocker(AShip: TPlShip; ASlot: TPlLanding; AEnemy: Boolean;
  AWantMode: TPlShipMode): TPlShip;
begin
  Result := nil;
  try
    // ������� ������ ���� �������� �������, ��������� ��� ������
    if (not AShip.TechActive(plttCornerBlock)) then
      Exit(nil);
    // �������� ��������� ������ �� ���������
    Result := CheckShipSide(AShip.Planet, ASlot, AWantMode);
    if (Result = nil) then
      Exit(nil);
    // ������� ������ ���� �� ������ ������, � ���� - �������
    if (AEnemy and AShip.Owner.IsRoleFriend(Result.Owner))
      or (not AEnemy and AShip.Owner.IsRoleEnemy(Result.Owner))
    then
      Exit(nil);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.CheckShipSide(ADestination: TPlPlanet; ASlot: TPlLanding;
  AWantMode: TPlShipMode): TPlShip;
begin
  Result := nil;
  try
    // ������� ������� �������, ��� ����� ���� ��������� �� ����� ��� ����� �� � ������������ ������
    if (not ADestination.Landings.IsShip(ASlot, Result))
      or (Result.State <> pshstIddle)
      or (Result.Mode <> AWantMode)
    then
      Exit(nil);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.CheckArrival(ADestination: TPlPlanet;
  AShipLowOrbit: Boolean; ASlotFrom, ASlotTo: TPlLanding; AShipPlanet: TPlPlanet;
  AShipOwner: TGlPlayer; ACheckOnePlanet: Boolean): Boolean;
var
  TmpSelfPlanet: Boolean;
  TmpCount: TPlShipsCount;
begin
  Result := False;
  try
    // ������ ����������� ��������
    TmpSelfPlanet := (AShipPlanet = ADestination);
    // ���� ������ ������ - ��������� ��������� �� 6 ������ ����
    if (not ASlotTo.IsLowOrbit)
      and (not TmpSelfPlanet or not ASlotFrom.IsLowOrbit or not ACheckOnePlanet)
      and (ADestination.ShipCount.TryGetValue(AShipOwner, TmpCount))
      and (TmpCount.Exist = I_MAX_SHIP_COUNT) then
    begin
      TLogAccess.Write(ClassName, 'Full');
      Exit();
    end;
    Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.CheckBackZone(AIgnoreBackZone: Boolean; ADestination: TPlPlanet;
  ASlot: TPlLanding; AOwner: TGlPlayer): Boolean;
var
  TmpLeft: TPlShip;
  TmpRight: TPlShip;
begin
  Result := False;
  try
    // � ����� ����� � ��� ����� �����
    if (AIgnoreBackZone) then
      Exit(True);
    // ����� ���� ����, ������� �������� �� ���� ����
    TmpLeft := CheckShipSide(ADestination, ASlot.Prev(), pshmdActive);
    if (TmpLeft = nil) or (TmpLeft.Owner.IsRoleFriend(AOwner)) then
      Exit(True);
    // ������ ���� ����, ������� �������� �� ���� ����
    TmpRight := CheckShipSide(ADestination, ASlot.Next(), pshmdActive);
    if (TmpRight = nil) or (TmpRight.Owner.IsRoleFriend(AOwner)) then
      Exit(True);
    // ���� ������� ��������� �� ������� ���� �����, �� ���� ���
    Result := TmpRight.Owner.IsRoleEnemy(TmpLeft.Owner);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlCustom.DealDamage(AShip: TPlShip; ADamage: Integer;
  ADestruct: Boolean): Integer;
var
  TmpDamage: Integer;
  TmpKilled: Integer;
  TmpHP: Integer;
begin
  Result := 0;
  try
    // ������� ������������ �������
    if (not Assigned(AShip)) then
      Exit();
    // ���������� ����� ������ ������� � �������� �������
    if (AShip.Count = 0) then
      Exit();
    // ��������� ���������� ������ � ����� ����
    TmpHP := AShip.TechValue(plttHp);
    TmpKilled := Min(AShip.Count, Trunc(ADamage / TmpHP));
    TmpDamage := TmpKilled * TmpHP;
    // ����� �������� ����, ������ ����������, ������ ������
    Inc(Result, TmpDamage);       (**)
    Dec(ADamage, TmpDamage);
    Dec(AShip.Count, TmpKilled);
    if (ADestruct) then
      Inc(AShip.Destructed, TmpKilled);
    // �������� ������� ����������
    if (AShip.Count > 0) then
    begin
      TmpDamage := Min(AShip.HP, ADamage);
      Dec(AShip.HP, TmpDamage);
      Inc(Result, ADamage);
      // ������ ������� ��� �� � ����
      if (AShip.HP = 0) then
      begin
        AShip.HP := TmpHP - (ADamage - TmpDamage);
        Dec(AShip.Count);
        // ������ ������ ���� �����
        if (ADestruct) then
          Inc(AShip.Destructed);
      end;
    end;
    // ���� ���� ���� - ������� ������ �������
    if (TmpKilled > 0) then
      TPlanetarThread(Engine).ControlPlanets.UpdateShipList(AShip, -TmpKilled);
    // ������� ��������� �������, ���� �� ������ - ��������
    if (ADestruct) then
      AShip.IsDestroyed := pshchDestruct
    else
      AShip.IsDestroyed := pshchSilent;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlCustom.WorkShipHP(APlanet: TPlPlanet);
var
  TmpI: Integer;
  TmpShip: TPlShip;
begin
  try
    for TmpI := Pred(APlanet.Ships.Count) downto 0 do
    begin
      TmpShip := APlanet.Ships[TmpI];
      if (TmpShip.IsDestroyed = pshchNone) then
        Continue;
      // ���� �� ���� - ������� ������
      if (TmpShip.Count > 0) then
      begin
        TmpShip.IsDestroyed := pshchNone;
        TPlanetarThread(Engine).ControlShips.Repair.Check(TmpShip);
        TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(TmpShip);
      end else
      // ������ � �������
      begin
        TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(
          TmpShip, True, TmpShip.IsDestroyed = pshchDestruct, True);
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
