{**********************************************}
{                                              }
{ ������ : ��������� ������� ����              }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Battle;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ������� ����
  TPLShipsControlBattle = class(TPLShipsControlCustom)
  private
    // ������������� ����� � ������ �������
    function GetCorrectDamage(AShip: TPlShip; ADamage: Integer): Integer;
    // ����� ������ ����������� ���������
    procedure DoAttackTarget(APlanet: TPlPlanet; AShip: TPlShip);
    // ���������� ������ �� �������
    procedure DoRetarget(APlanet: TPlPlanet; AExternal: Boolean = False);
  public
    // ������� ����������
    function Execute(APlanet: TPlPlanet): Boolean;
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlBattle.GetCorrectDamage(AShip: TPlShip; ADamage: Integer): Integer;
begin
  Result := ADamage;
  try
    // ����������� �������� ����������� �������
    if (not AShip.TechActive(plttStationary)) then
      Result := Min(2000, AShip.Count * Result);
    {$IFNDEF DEBUG}
   // Result := 2;
    {$ENDIF}
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlBattle.DoRetarget(APlanet: TPlPlanet; AExternal: Boolean);
var
  TmpI: Integer;
  TmpList: TPlShipList;
  TmpShip: TPlShip;
begin
  try
    // ������� ������
    if (AExternal) then
      TmpList := APlanet.RangeAttackers
    else
      TmpList := APlanet.Ships;
    // �������� ������� ��������
    for TmpI := Pred(TmpList.Count) downto 0 do
    begin
      TmpShip := TmpList[TmpI];
      // ������� ���������� ������ � ���������� ��� �� ������ �������
      if (AExternal = TmpShip.IsAttachedRange(True))
        and (not TmpShip.Landing.IsLowOrbit) then
      begin
        if (AExternal) then
          TPlanetarThread(Engine).ControlShips.TargetMarker.Highlight(
            TmpShip, TmpShip.Attached, TmpShip.IsAutoTarget)
        else
          TPlanetarThread(Engine).ControlShips.TargetLocal.Execute(TmpShip);
      end;
    end;
    // �������� �������
    if (not AExternal) then
      DoRetarget(APlanet, True);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlBattle.DoAttackTarget(APlanet: TPlPlanet; AShip: TPlShip);
var
  TmpDmg: Integer;
begin
  try
    // ������� ����
    TmpDmg := AShip.TechValue(plttWeaponDoubleBullet);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswLeft], TmpDmg);
      DealDamage(AShip.Targets[pswRight], TmpDmg);
    end;
    // ������� ������
    TmpDmg := AShip.TechValue(plttWeaponDoubleLaser);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswLeft], TmpDmg);
      DealDamage(AShip.Targets[pswRight], TmpDmg);
    end;
    // ��������� ������
    TmpDmg := AShip.TechValue(plttWeaponBullet);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswCenter], TmpDmg);
    end;
    // ������������� ������
    TmpDmg := AShip.TechValue(plttWeaponOvershot);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswCenter], TmpDmg);
    end;
    // ��������� �����
    TmpDmg := AShip.TechValue(plttWeaponLaser);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswCenter], TmpDmg);
    end;
    // ������
    TmpDmg := AShip.TechValue(plttWeaponRocket);
    if (TmpDmg > 0) then
    begin
      TmpDmg := GetCorrectDamage(AShip, TmpDmg);
      DealDamage(AShip.Targets[pswRocket], TmpDmg);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlBattle.Execute(APlanet: TPlPlanet): Boolean;
var
  TmpShip: TPlShip;
begin
  Result := False;
  try
    // ����� ���� ������ ��� ����� �������� �� �������
    if (APlanet.IsRetarget) then
      DoRetarget(APlanet);
    // ����� ��������� ����������
    for TmpShip in APlanet.Ships do
    begin
      if (TmpShip.IsTargeted)
        and (not TmpShip.IsAttachedRange(True)) then
      begin
        Result := True;
        DoAttackTarget(APlanet, TmpShip);
      end;
    end;
    // ����� ������� ����������
    if (Result) then
    begin
      for TmpShip in APlanet.RangeAttackers do
      begin
        if (TmpShip.IsTargeted) then
          DoAttackTarget(APlanet, TmpShip);
      end;
      // �������� ��������� ��������� � ������ ������ ��� ������� ��� ��� ���� ������� �� ������ �������
      if (APlanet.IsRetarget) then
      begin
        APlanet.IsRetarget := False;
        TPlanetarThread(Engine).ControlShips.Retarget.Execute(APlanet);
      end;
    end;
    // �������� ���������� ����������� ����������
    TPlanetarThread(Engine).ControlShips.Hypodispersion.ByPlanet(APlanet);
    // �������� ��������� � ����� �� ����������� ����������
    WorkShipHP(APlanet);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
