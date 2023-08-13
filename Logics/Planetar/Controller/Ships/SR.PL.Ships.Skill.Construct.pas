{**********************************************}
{                                              }
{ ���� : ����� ������� ���������               }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Skill.Construct;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ������������� ������ ������� ���������
  TPLShipsControlSkillConstruct = class(TPLShipsControlCustom)
  private
    // �������������� ������� ������ ��������
    procedure DoRepairFriends(AShip: TPlShip; var AMount: Integer);
    // �������������� ������ ������ ����������
    procedure DoConstructEnemy(AShip: TPlShip; var AMount: Integer);
    // ���������� ������� �����
    procedure DoExecute(AShip, ATarget: TPlShip);
    // ������ ������ �����
    function OnTimer(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean;
  public
    // ���������� ������� ������
    procedure Player(AShip, ATarget: TPlShip; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlSkillConstruct.OnTimer(AShip: TPlShip; var ACounter: Integer;
  var AValue: Integer): Boolean;
begin
  Result := False;
  try
    if (ACounter > 0) then
      Dec(ACounter)
    else
      Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlSkillConstruct.DoConstructEnemy(AShip: TPlShip; var AMount: Integer);
var
  TmpShip: TPlShip;
begin
  try
    // ���� ���� ������ ������� �������� � ������ ��������� ������
    if (AMount > 0)
      and (AShip.TechActive(plttSkillConstructorEnemy)) then
    begin
      for TmpShip in AShip.Planet.Ships do
        if (not TmpShip.TechActive(plttStationary))
          and (not TmpShip.TechActive(plttSolidBody))
          and (TmpShip.Owner.IsRoleEnemy(AShip.Owner)) then
      begin
        Dec(AMount, DealDamage(TmpShip, AMount, False));
        if (AMount = 0) then
          Break;
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlSkillConstruct.DoRepairFriends(AShip: TPlShip; var AMount: Integer);
var
  TmpShip: TPlShip;
begin
  try
    // ���� ���� ������ �� ������� ������������� �����
    if (AMount > 0)
      and (AShip.TechActive(plttSkillConstructorFriend)) then
    begin
      for TmpShip in AShip.Planet.Ships do
        if (TmpShip <> AShip)
          and (TmpShip.Owner.IsRoleFriend(AShip.Owner)) then
      begin
        Dec(AMount, TPlanetarThread(Engine).ControlShips.Repair.Execute(TmpShip, AMount));
        if (AMount = 0) then
          Break;
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlSkillConstruct.DoExecute(AShip, ATarget: TPlShip);
var
  TmpCount: Integer;
  TmpDamage: Integer;
begin
  try
    // ���������� ��������� ��� �����
    TmpCount := AShip.TechValue(plttSkillConstructor);
    TmpDamage := TmpCount;
    Dec(TmpDamage, DealDamage(ATarget, TmpCount, False));
    // �������� ������ ��������������� �������
    DoConstructEnemy(AShip, TmpDamage);
    // ���������� ��������� ��� �������
    Dec(TmpCount, TmpDamage);
    Dec(TmpCount, TPlanetarThread(Engine).ControlShips.Repair.Execute(AShip, TmpCount));
    // �������� ������ �������������� �������
    DoRepairFriends(AShip, TmpCount);
    // ������� �� �� �������
    WorkShipHP(AShip.Planet);
    // �������� ����� ������
    TPlanetarThread(Engine).WorkerShips.TimerAdd(AShip, pshtmCdConstructor,
      AShip.TechCooldown(plttSkillConstructor), OnTimer);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlSkillConstruct.Player(AShip, ATarget: TPlShip; APlayer: TGlPlayer);
begin
  try
    // ������ ��������� ������
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // ������ ��������� ���������
    if (ATarget.TechActive(plttSolidBody)) then
    begin
      TLogAccess.Write(ClassName, 'SolidBody');
      Exit();
    end;
    // ������ ��������� �� ������ �������
    if (AShip.Planet <> ATarget.Planet) then
    begin
      TLogAccess.Write(ClassName, 'Planet');
      Exit();
    end;
    // ������ ��������� ���� ����� �� ��������
    if (not AShip.TechActive(plttSkillConstructor)) then
    begin
      TLogAccess.Write(ClassName, 'Skill');
      Exit();
    end;
    // ������ ��������� ���� ������ � ������
    if (AShip.Timer[pshtmCdConstructor]) then
    begin
      TLogAccess.Write(ClassName, 'Timer');
      Exit();
    end;
    // ��������� ���������
    DoExecute(AShip, ATarget);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
