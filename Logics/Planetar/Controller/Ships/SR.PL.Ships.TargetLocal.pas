{**********************************************}
{                                              }
{ ���� : ����� ��������� ���� ��� �����        }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.TargetLocal;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ������ ��������� ���� ��� �����
  TPLShipsControlTargetLocal = class(TPLShipsControlCustom)
  private
      // ����������, ����� �������� �� ���� ����� �����������
    function GetShipPriority(ALeft, ARight: TPlShip): Boolean;
    // �������� ���������� ����� ����� �����������
    function GetShipRange(ALeft, ARight: TPlShip): Integer;
    // ����������, ����� �������� �� ���� ����� � ����������
    function GetShipNear(ACenter, ALeft, ARight: TPlShip): Boolean;
    // ����� ���������� ��� �����
    function GetTargetShip(AShip: TPlShip; AIgnoreFriend, ALeft, AOneStep: Boolean;
      AOwner: TGlPlayer): TPlShip;
    // ������ � ���
    procedure TargetingToHead(AShip: TPlShip; ARightShip, ALeftShip: TPlShip; var ATarget: TPlShip);
    // ������ � ��� � ��� ����
    procedure TargetingToCorners(AShip: TPlShip; ARightShip, ALeftShip: TPlShip);
    // ������ � ��� � ���������� ����� ����
    procedure TargetingToInner(AShip, ARightShip, ALeftShip, ARightShipInner, ALeftShipInner: TPlShip);
    // ������ � ��� ������� ����
    procedure TargetingToDouble(AShip, ARightShip, ALeftShip, ARightShipInner, ALeftShipInner: TPlShip);
    // ������������ ������������ �������
    procedure WeaponOvershot(AShip: TPlShip);
    // ������������ �������� � ��������
    procedure WeaponOverFriends(AShip: TPlShip; var AWeapon: TPlShip);
    // ������������ �������� ��������
    procedure WeaponDoubleLaser(AShip: TPlShip);
    // ������������ �������� ������
    procedure WeaponDoubleBullet(AShip: TPlShip);
    // ������������ �����
    procedure WeaponBullet(AShip: TPlShip);
  public
    // ������� ����������
    procedure Execute(AShip: TPlShip);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlTargetLocal.GetShipPriority(ALeft, ARight: TPlShip): Boolean;
begin
  Result := False;
  try
    // ����� ����� ���� ��� ������� ��� ���� ��� �����
    Result := Assigned(ALeft) and
      (not Assigned(ARight)
        or (ALeft.ShipType = ARight.ShipType)
        or (ALeft.TechValue(plttPriority) <= ARight.TechValue(plttPriority)));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlTargetLocal.GetShipRange(ALeft, ARight: TPlShip): Integer;
var
  TmpRevert: Integer;
begin
  Result := 0;
  try
    Result := Abs(ALeft.Landing - ARight.Landing);
    // ���������� �����
    TmpRevert := TPlLanding.Offset(-Result);
    // ������
    if (TmpRevert < Result) then
      Result := TmpRevert;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlTargetLocal.GetShipNear(ACenter, ALeft, ARight: TPlShip): Boolean;
begin
  Result := False;
  try
    // ����� ����� ���� ��� ������� ��� ���� �� ������� �����
    Result := Assigned(ALeft) and
      (not Assigned(ARight) or (GetShipRange(ACenter, ALeft) <= GetShipRange(ACenter, ARight)));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.TargetingToHead(AShip, ARightShip, ALeftShip: TPlShip;
  var ATarget: TPlShip);
var
  TmpTargetCenter: TPlShip;
begin
  try
    if GetShipNear(AShip, ALeftShip, ARightShip) then
      TmpTargetCenter := ALeftShip
    else
      TmpTargetCenter := ARightShip;
    // �������� ���������
    if (ATarget <> TmpTargetCenter) then
      ATarget := TmpTargetCenter;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.TargetingToCorners(AShip, ARightShip, ALeftShip: TPlShip);
begin
  try
    // ������������ ������� �� ������ ���� ��� ����
    if (not Assigned(ALeftShip)) then
      ALeftShip := ARightShip;
    if (not Assigned(ARightShip)) then
      ARightShip := ALeftShip;
    // �������� ���������
    if (AShip.Targets[pswRight] <> ARightShip) then
      AShip.Targets[pswRight] := ARightShip;
    if (AShip.Targets[pswLeft] <> ALeftShip) then
      AShip.Targets[pswLeft] := ALeftShip;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.TargetingToDouble(AShip, ARightShip, ALeftShip,
  ARightShipInner, ALeftShipInner: TPlShip);
begin
  try
    // ������� ������� ������ �� ��������
    if (GetShipNear(AShip, ALeftShipInner, ARightShip)) then
      ARightShip := ALeftShipInner
    else
    if (GetShipNear(AShip, ARightShipInner, ALeftShip)) then
      ALeftShip := ARightShipInner;
    // ������������ ������� �� ������ ���� ��� ����
    if (not Assigned(ARightShip)) then
      ARightShip := ALeftShip;
    if (not Assigned(ALeftShip)) then
      ALeftShip := ARightShip;
    // �������� ���������
    if (AShip.Targets[pswRight] <> ARightShip) then
      AShip.Targets[pswRight] := ARightShip;
    if (AShip.Targets[pswLeft] <> ALeftShip) then
      AShip.Targets[pswLeft] := ALeftShip;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.TargetingToInner(AShip, ARightShip, ALeftShip,
  ARightShipInner, ALeftShipInner: TPlShip);
var
  TmpTargetCenter: TPlShip;
begin
  (*���������*)
  try
    TmpTargetCenter := nil;
    // ������ ���� ������ �������� �����
    if Assigned(ALeftShipInner)
      and (ALeftShipInner.TechActive(plttOvershotTarget))
    then
      TmpTargetCenter := ALeftShipInner;
    // ����� ������� ��������� ����� ����
    if GetShipPriority(ALeftShip, TmpTargetCenter) then
      TmpTargetCenter := ALeftShip;
    // ������ ������� ��������� ��������� ������ ����
    if Assigned(ARightShipInner)
      and (ARightShipInner.TechActive(plttOvershotTarget))
      and GetShipPriority(ARightShipInner, TmpTargetCenter)
    then
      TmpTargetCenter := ARightShipInner;
    // � �������� ��� ������ ������ �� ������������
    if not Assigned(TmpTargetCenter)
      or (not (TmpTargetCenter.TechActive(plttOvershotTarget)) and not GetShipNear(AShip, TmpTargetCenter, ARightShip))
    then
      TmpTargetCenter := ARightShip;
    // �������� ���������
    if (AShip.Targets[pswCenter] <> TmpTargetCenter) then
      AShip.Targets[pswCenter] := TmpTargetCenter;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlTargetLocal.GetTargetShip(AShip: TPlShip; AIgnoreFriend,
  ALeft, AOneStep: Boolean; AOwner: TGlPlayer): TPlShip;
var
  TmpSlot: TPlLanding;
begin
  Result := nil;
  try
    TmpSlot := AShip.Landing;
    repeat
      // ������� ����
      if (ALeft) then
        TmpSlot.Dec()
      else
        TmpSlot.Inc();
      // ����� �������� �� �����
      if (AShip.Planet.Landings.IsShip(TmpSlot, Result)) then
      begin
        // ���� ��� ��������� - �� ������ ���� �������� ��� ���������
        if (Result.Owner.IsRoleEnemy(AOwner)) then
        begin
          if (Result.IsStateActive)
            or (Result.Planet.ShipCount[AShip.Owner].Active = 0)
          then
            Exit();
        end else
        // ����� �������, ����� �� ������������� ������
        begin
          if (not AIgnoreFriend)
            and (AShip.IsStateActive)
          then
            Exit(nil);
        end;
        // ���� �������� �� ������ - ������ ����������
        Result := nil;
      end;
      // ����� ������ �������� ��������
      if (AOneStep) then
        Break;
    until (TmpSlot = AShip.Landing);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.WeaponDoubleBullet(AShip: TPlShip);
var
  TmpShipLeft: TPlShip;
  TmpShipRight: TPlShip;
begin
  try
    TmpShipRight := GetTargetShip(AShip, False, True, False, AShip.Owner);
    TmpShipLeft := GetTargetShip(AShip, False, False, False, AShip.Owner);
    // ��������� ������ ����, ������ ����� ��������
    TargetingToCorners(AShip, TmpShipRight, TmpShipLeft);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.WeaponBullet(AShip: TPlShip);
var
  TmpShipLeft: TPlShip;
  TmpShipRight: TPlShip;
begin
  try
    TmpShipRight := GetTargetShip(AShip, False, True, False, AShip.Owner);
    TmpShipLeft := GetTargetShip(AShip, False, False, False, AShip.Owner);
    // ��������� ������ ����, ������ ����� ��������
    TargetingToHead(AShip, TmpShipRight, TmpShipLeft, AShip.Targets[pswCenter]);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.WeaponDoubleLaser(AShip: TPlShip);
var
  TmpShipLeft: TPlShip;
  TmpShipRight: TPlShip;
  TmpShipInnerLeft: TPlShip;
  TmpShipInnerRight: TPlShip;
begin
  try
    TmpShipRight := GetTargetShip(AShip, True, True, False, AShip.Owner);
    TmpShipLeft := GetTargetShip(AShip, True, False, False, AShip.Owner);
    // �������� ��������
    if (Assigned(TmpShipRight)) then
      TmpShipInnerRight := GetTargetShip(TmpShipRight, True, True, False, AShip.Owner)
    else
      TmpShipInnerRight := nil;
    if (Assigned(TmpShipLeft)) then
      TmpShipInnerLeft := GetTargetShip(TmpShipLeft, True, False, False, AShip.Owner)
    else
      TmpShipInnerLeft := nil;
    // ��������� ������ ����
    TargetingToDouble(AShip, TmpShipRight, TmpShipLeft, TmpShipInnerRight, TmpShipInnerLeft);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.WeaponOverFriends(AShip: TPlShip; var AWeapon: TPlShip);
var
  TmpShipLeft: TPlShip;
  TmpShipRight: TPlShip;
begin
  try
    TmpShipRight := GetTargetShip(AShip, True, True, False, AShip.Owner);
    TmpShipLeft := GetTargetShip(AShip, True, False, False, AShip.Owner);
    TargetingToHead(AShip, TmpShipRight, TmpShipLeft, AWeapon);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.WeaponOvershot(AShip: TPlShip);
var
  TmpShipLeft: TPlShip;
  TmpShipRight: TPlShip;
  TmpShipInnerLeft: TPlShip;
  TmpShipInnerRight: TPlShip;
begin
  try
    TmpShipRight := GetTargetShip(AShip, False, True, False, AShip.Owner);
    TmpShipLeft := GetTargetShip(AShip, False, False, False, AShip.Owner);
    // �������� �������� ������
    if Assigned(TmpShipRight)
      and (not TmpShipRight.TechActive(plttOvershotblocker))
      and (GetShipRange(AShip, TmpShipRight) = 1)
    then
      TmpShipInnerRight := GetTargetShip(TmpShipRight, False, True, True, AShip.Owner)
    else
      TmpShipInnerRight := nil;
    // �������� �������� �����
    if Assigned(TmpShipLeft)
      and (not TmpShipLeft.TechActive(plttOvershotblocker))
      and (GetShipRange(AShip, TmpShipLeft) = 1)
    then
      TmpShipInnerLeft := GetTargetShip(TmpShipLeft, False, False, True, AShip.Owner)
    else
      TmpShipInnerLeft := nil;
    // ��������� ������ ����
    TargetingToInner(AShip, TmpShipRight, TmpShipLeft, TmpShipInnerRight, TmpShipInnerLeft);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetLocal.Execute(AShip: TPlShip);
var
  TmpTargets: TPlShipTargets;
  TmpWeapon: TPlShipWeaponType;
begin
  try
    TmpTargets := AShip.Targets;
    // ��� ������ ���� ���� �� ������� �������
    if (AShip.IsStateActive) then
    begin
      // �������� ����� ���������� �� ������� �� ������
      if (AShip.TechActive(plttWeaponOvershot)) then
        WeaponOvershot(AShip);
      // ����� � �������� ����� �����
      if (AShip.TechActive(plttWeaponLaser)) then
        WeaponOverFriends(AShip, AShip.Targets[pswCenter]);
      // ������ �������� � �������� ����� �����
      if (AShip.TechActive(plttWeaponRocket)) then
        WeaponOverFriends(AShip, AShip.Targets[pswRocket]);
      // ������� ��������������� �����
      if (AShip.TechActive(plttWeaponDoubleLaser)) then
        WeaponDoubleLaser(AShip);
      // ������� ������
      if (AShip.TechActive(plttWeaponDoubleBullet)) then
        WeaponDoubleBullet(AShip);
      // ��������� � ������ �������� ����� �������� � ���
      if (AShip.TechActive(plttWeaponBullet)) then
        WeaponBullet(AShip);
    end else
      AShip.IsTargeted := False;
    // �������� ����� ���������
    for TmpWeapon := Low(TPlShipWeaponType) to High(TPlShipWeaponType) do
    begin
      if (TmpTargets[TmpWeapon] <> AShip.Targets[TmpWeapon]) then
        TPlanetarThread(Engine).SocketWriter.ShipRetarget(AShip, TmpWeapon);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
