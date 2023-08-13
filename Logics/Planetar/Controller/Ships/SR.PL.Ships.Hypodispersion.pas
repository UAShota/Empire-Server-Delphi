{**********************************************}
{                                              }
{ ���� : ������� ���������� ����������         }
{        ���������� ������                     }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Hypodispersion;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ���������� ���������� ���������� ������
  TPLShipsControlHypodispersion = class(TPLShipsControlCustom)
  private var
    // ������ ����� �������� ��� �����������
    FUniqueShips: array[1..TPlLandings.I_FIGHT_COUNT] of TPlShip;
    FUniqueCount: Integer;
  private
    // ����� ����� ������������� ���� ��� ���������� ������
    function GetAlreadyDone(AShip: TPlShip): Boolean;
  public
    // �������������� ����������� ������
    procedure ByPlanet(APlanet: TPlPlanet);
    // �������������� ��������� ������
    { TODO -omdv : Hypodispersion ������� �� ���������� }
    procedure ByShip(AShip: TPlShip; AActiveOnly: Boolean);
    // ���������� ������� ������
    procedure Player(AShip: TPlShip; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlHypodispersion.GetAlreadyDone(AShip: TPlShip): Boolean;
var
  TmpI: Integer;
begin
  Result := False;
  try
    // ������ ��� ��������� ���� ��������� � ��������� ����� �������
    for TmpI := 1 to FUniqueCount do
    begin
      if (FUniqueShips[TmpI].Owner = AShip.Owner)
        and (FUniqueShips[TmpI].ShipType = AShip.ShipType)
      then
        Exit(True);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlHypodispersion.ByShip(AShip: TPlShip; AActiveOnly: Boolean);
var
  TmpShip: TPlShip;
  TmpShipAttached: TPlShip;
  TmpActiveDefaultCount: Integer;
  TmpActiveAttachedCount: Integer;
  TmpActiveDefaultShips: Integer;
  TmpActiveAttachedShips: Integer;
  TmpPassiveCount: Integer;
  TmpPassiveCountSum: Integer;
  TmpSize: Integer;
  TmpMaxCount: Integer;
  TmpListActive: TPlShipList;
  TmpListPassive: TPlShipList;
begin
  try
    TmpMaxCount := AShip.TechValue(plttCount);
    TmpListActive := TPlShipList.Create();
    TmpListPassive := TPlShipList.Create();
    TmpActiveDefaultCount := 0;
    TmpActiveAttachedCount := 0;
    TmpActiveDefaultShips := 0;
    TmpActiveAttachedShips := 0;
    TmpPassiveCount := 0;

    // ���������� �������� ���� ��� �������, ���� ������ �������������
    for TmpShip in AShip.Planet.Ships do
    begin
      if (TmpShip.Owner <> AShip.Owner)
        or (TmpShip.ShipType <> AShip.ShipType)
        or (TmpShip.Count = 0)
        or (TmpShip.State <> pshstIddle)
      then
        Continue;
      // ���������� ������ ���� ����������� � ��� ���������������
      if (not AActiveOnly) and (Assigned(TmpShip.Attached)) then
      begin
        if (TmpShip.Mode in [pshmdOffline, pshmdBlocked, pshmdFull]) then
        begin
          TmpListPassive.Add(TmpShip);
          Inc(TmpPassiveCount, TmpShip.Count);
        end else
        begin
          TmpListActive.Add(TmpShip);
          Inc(TmpActiveAttachedCount, TmpShip.Count);
          Inc(TmpActiveAttachedShips);
        end;
      end else
      // ��������� ��������� ��� ������
      begin
        if (TmpShip.Mode = pshmdActive) then
        begin
          TmpListActive.Add(TmpShip);
          Inc(TmpActiveDefaultCount, TmpShip.Count);
          Inc(TmpActiveDefaultShips);
        end;
      end;
    end;

    // ������ �������� ���������
    if (TmpListPassive.Count > 0) then
    begin
      TmpPassiveCountSum := 0;
      for TmpShip in TmpListActive do
      begin
        if (TmpShip.Count >= TmpMaxCount) then
          Continue;
        if (TmpPassiveCount = 0) then
          Break;
        TmpSize := Min(TmpPassiveCount, TmpMaxCount - TmpShip.Count);
        Inc(TmpShip.Count, TmpSize);
        Inc(TmpPassiveCountSum, TmpSize);
        Inc(TmpActiveDefaultCount, TmpSize);
        //
        if (Assigned(TmpShip.Attached)) then
          Inc(TmpActiveAttachedCount, TmpSize);
        Dec(TmpPassiveCount, TmpSize);
        TmpShip.IsDestroyed := pshchSilent;
      end;
      // � ������ ������ ���������
      for TmpShip in TmpListPassive do
      begin
        if (TmpPassiveCountSum = 0) then
          Break;
        TmpSize := Min(TmpShip.Count, TmpPassiveCountSum);
        Dec(TmpShip.Count, TmpSize);
        Dec(TmpPassiveCountSum, TmpSize);
        TmpShip.IsDestroyed := pshchSilent;
      end;
    end;

    // ����� ����������� ����� ������������, � ������ ��� ������ ����� �� ������ ������
    if ((not AActiveOnly) and (TmpActiveAttachedShips > 1))
        or ((AActiveOnly) and (TmpListActive.Count > 1))
      and (TmpListActive.Count * TmpMaxCount <> TmpActiveDefaultCount) then
    begin
      TmpShip := nil;
      TmpShipAttached := nil;
      // ������ ������� ����������
      if (not AActiveOnly) then
        TmpSize := TmpActiveAttachedCount div TmpActiveAttachedShips
      else
        TmpSize := TmpActiveDefaultCount div TmpActiveDefaultShips;
      // � ����������� �������� ��������� �������
      for TmpShip in TmpListActive do
      begin
        if ((not AActiveOnly) and Assigned(TmpShip.Attached)) then
        begin
          TmpShip.Count := TmpSize;
          TmpShip.IsDestroyed := pshchSilent;
          Dec(TmpActiveAttachedCount, TmpSize);
          TmpShipAttached := TmpShip;
        end
        else
        if (AActiveOnly) then
        begin
          TmpShip.Count := TmpSize;
          TmpShip.IsDestroyed := pshchSilent;
          Dec(TmpActiveDefaultCount, TmpSize)
        end;
      end;
      // � ������� �������� � ��������� ������������ �����
      if (not AActiveOnly) then
        Inc(TmpShipAttached.Count, TmpActiveAttachedCount)
      else
        Inc(TmpShip.Count, TmpActiveDefaultCount);
    end;

    // � �������� ���������, ���� ������� �� � ��� ��� ��� �������������� ������
    if (not AShip.Planet.Timer[ppltmBattle]) or (AActiveOnly) then
    begin
      for TmpShip in AShip.Planet.Ships do
      begin
        if (TmpShip.IsDestroyed = pshchNone) then
          Continue
        else
          TmpShip.IsDestroyed := pshchNone;
        TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(TmpShip);
      end;
    end;

    FreeAndNil(TmpListActive);
    FreeAndNil(TmpListPassive);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlHypodispersion.ByPlanet(APlanet: TPlPlanet);
var
  TmpShip: TPlShip;
begin
  try
    FUniqueCount := 0;
    // ���������� ��� ����� �������
    for TmpShip in APlanet.Ships do
    begin
      // ������ ��� ������� �������������� ������ ���� ���
      if (TmpShip.Attached = APlanet)
        and (not GetAlreadyDone(TmpShip)) then
      begin
        // ������� �������� � ������ ��������������
        Inc(FUniqueCount);
        FUniqueShips[FUniqueCount] := TmpShip;
        // �������� ����������
        ByShip(TmpShip, False);
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlHypodispersion.Player(AShip: TPlShip; APlayer: TGlPlayer);
begin
  try
    // ������ ��������� ������ �����������
    if (AShip.Planet.Ships.Count = 1) then
    begin
      TLogAccess.Write(ClassName, 'Signle');
      Exit();
    end;
    // ������ ��������� ������ �����������
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // ����� �������� �����������
    ByShip(AShip, True);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
