{**********************************************}
{                                              }
{ ���� : ��������� � ������ �����              }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Construct;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Globals.Types,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ��������� �����
  TPLShipsControlConstruct = class(TPLShipsControlCustom)
  private const
    I_MAX_SHIPYARD_ACTIVE = 4;
  private
    // ���������� �� ������������ �� ���
    function GetHPperTick(AShip: TPlShip): Integer;
    // ������ ������� ���������
    function OnTimer(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean;
  public
    // ������� ����������
    function Execute(APlanet: TPlPlanet; AShipType: TPlShipType; ACount: Integer;
      APlayer: TGlPlayer): TPlShip;
    // ���������� ������� ������
    procedure Player(APlanet: TPlPlanet; AShipType: TPlShipType; ACount: Integer;
      APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread,
  SR.Planetar.Profile;

function TPLShipsControlConstruct.GetHPperTick(AShip: TPlShip): Integer;
var
  TmpCount: TPlShipsCount;
begin
  Result := -1;
  try
    // ������ ���������� ������ ����������� ������, 1 ����� ���� ������ �� ���������
    if (not AShip.Planet.Constructors.TryGetValue(AShip.Owner, TmpCount)) then
    begin
      if (AShip.TechActive(plttStationary)) then
        TmpCount.Value := 1
      else
        Exit();
    end;
    // ������� 150�� / ���
    Result := Min(TmpCount.Value, I_MAX_SHIPYARD_ACTIVE) * AShip.TechValue(plttConstruction);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlConstruct.OnTimer(AShip: TPlShip; var ACounter: Integer;
  var AValue: Integer): Boolean;
var
  TmpTotal: Integer;
  TmpCount: Integer;
begin
  Result := False;
  try
    // ��������� ��������� ���������
    if (ACounter = 0) then
    begin
      if (not AShip.CanOperable(True)) then
        Exit();
      AShip.HP := AShip.TechValue(plttHp);
      // �������� ���������
      TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(AShip);
      // �������� ��������� ��������� ���� �������� �� � ��������� ������
      TPlanetarThread(Engine).ControlShips.StandUp.Execute(AShip);
      // ������� ��������� ������� ��� ������������ ��������
      TPlanetarThread(Engine).ControlPlanets.UpdateShipList(AShip, AShip.Count);
      // �������� ����� �������
      Result := True;
    end;
    // ��������� ��
    TmpCount := GetHPperTick(AShip);
    TmpTotal := (AShip.Count * AShip.TechValue(plttHp));
    // ������ ������� �� � �������
    if (AShip.CanOperable(True)) then
      Inc(AShip.HP, TmpCount)
    else
      TmpCount := -TmpCount;
    // ���� ��������� ��� ����� - ��������
    if (AShip.HP >= TmpTotal) then
      ACounter := 0
    // ���� ��� - ��������, ���������� �� ��������
    else if (TmpCount <> ACounter) then
    begin
      ACounter := TmpCount;
      AValue := (TmpTotal - AShip.HP) div ACounter;
      Result := True;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlConstruct.Execute(APlanet: TPlPlanet; AShipType: TPlShipType; ACount: Integer;
  APlayer: TGlPlayer): TPlShip;
var
  TmpLowOrbit: Boolean;
  TmpBackzone: Boolean;
  TmpSlot: Integer;
  TmpCost: Integer;
  TmpCount: Integer;
begin
  Result := nil;
  try
    TmpLowOrbit := TPlanetarProfile(APlayer.PlanetarProfile).TechShipProfile[AShipType, plttLowOrbit].Supported;
    TmpBackzone := TPlanetarProfile(APlayer.PlanetarProfile).TechShipProfile[AShipType, plttIntoBackzone].Supported;
    // ������ ��������� ����
    TmpSlot := GetFreeSlot(TmpBackzone, APlanet, TmpLowOrbit, APlayer);
    if (TmpSlot = 0) then
    begin
      TLogAccess.Write(ClassName, 'Slot');
      Exit();
    end;
    // ������� �������� ��������� �������� � ��������� ����
    if (not CheckArrival(APlanet, TmpLowOrbit, TmpSlot, TmpSlot, APlanet, APlanet.Owner, False)) then
    begin
      TLogAccess.Write(ClassName, 'Arrival');
      Exit();
    end;
    // ���� �� ����������
    TmpCount := Min(ACount, TPlanetarProfile(APlayer.PlanetarProfile).TechShip(AShipType, plttCount));
    TmpCost := TmpCount * TPlanetarProfile(APlayer.PlanetarProfile).TechShip(AShipType, plttCost);
    // ��������� ������� �������� ��� ���������
    if (APlanet.ResAvailIn[resModules] < TmpCost) then
    begin
      TLogAccess.Write(ClassName, 'Modules');
      Exit();
    end;
    // ���� ��� ���� - �������� ��������
    Result := CreateShip(APlanet, AShipType, TmpSlot, TmpCount, APlayer);
    Result.Mode := pshmdConstruction;
    Result.HP := 0;
    // �������� ���������� ����������� ��������
    TPlanetarThread(Engine).ControlStorages.DecrementResource(resModules, APlanet, TmpCost);
    // ������� ��������� �������� �� �������
    TPlanetarThread(Engine).ControlShips.AddToPlanet.Execute(Result, APlanet, False, False, APlanet.Timer[ppltmBattle]);
    // �������� ���������
    TPlanetarThread(Engine).SocketWriter.ShipCreate(Result);
    // ������� ������
    TPlanetarThread(Engine).WorkerShips.TimerAdd(Result, pshtmOpConstruction,
      GetHPperTick(Result), OnTimer, Result.Count * Result.TechValue(plttHP) div GetHPperTick(Result));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlConstruct.Player(APlanet: TPlPlanet; AShipType: TPlShipType;
  ACount: Integer; APlayer: TGlPlayer);
var
  TmpStationary: Boolean;
begin
  try
    // ������ ������� ���������� ���������� ������
    if (ACount <= 0) then
    begin
      TLogAccess.Write(ClassName, 'Count');
      Exit();
    end;
    // ������ ������� ���� ������� � ���
    if (APlanet.Timer[ppltmBattle]) then
    begin
      TLogAccess.Write(ClassName, 'Battle');
      Exit();
    end;
    // ������ ������� ���� ���������� �������
    if (TPlanetarProfile(APlayer.PlanetarProfile).TechShip(AShipType, plttActive) = 0) then
    begin
      TLogAccess.Write(ClassName, 'Tech');
      Exit();
    end;
    // ��������� ��������� �������� �����
    TmpStationary := TPlanetarProfile(APlayer.PlanetarProfile).TechShipProfile[AShipType, plttStationary].Supported;
    // �������� ��������� �������������� �����
    if (not APlanet.IsManned) then
    begin
      // ������ ������� �� ����� �������
      if (not APlanet.Owner.IsRoleFriend(APlayer)) then
      begin
        TLogAccess.Write(ClassName, 'Role');
        Exit();
      end;
      // �� ������� ����� ������� ������ �����������
      if (not TmpStationary) then
      begin
        TLogAccess.Write(ClassName, 'Manned');
        Exit();
      end;
    end;
    // �� ����� �� ������������ ���� ����� ������� ������ ���� ���� �����
    if (not TmpStationary)
      and (not APlanet.Constructors.ContainsKey(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Shipyard');
      Exit();
    end;
    // ����� �������� ��������
    Execute(APlanet, AShipType, ACount, APlayer);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
