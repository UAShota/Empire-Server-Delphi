{**********************************************}
{                                              }
{ ���� : ������� ��������� �����               }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Repair;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Types,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ������� �����
  TPLShipsControlRepair = class(TPLShipsControlCustom)
  private const
    // ������ ��������� ����� � �������
    CI_REPAIR_DISCOUNT = 0.70;
  private
    // ����������� ���������� ������� ��� �������������� �����
    function GetRestoreCost(AShip: TPlShip): Integer;
    // ����������� �������� ����������� �������������� �����
    function GetRestoreAvailable(AShip: TPlShip): Boolean;
    // ����������� �������� ����������� ������� �����
    function GetRepairAvailable(AShip: TPlShip): Boolean;
    // ������ ���� ��������������
    function OnTimer(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean;
  public
    procedure Check(AShip: TPlShip);
    // ������� ����������
    function Execute(AShip: TPlShip; AMount: Integer): Integer;
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlRepair.GetRestoreCost(AShip: TPlShip): Integer;
begin
  Result := MaxInt;
  try
    Result := Round(AShip.TechValue(plttCost) * CI_REPAIR_DISCOUNT);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlRepair.GetRepairAvailable(AShip: TPlShip): Boolean;
begin
  Result := False;
  try
    Result := (AShip.HP < AShip.TechValue(plttHP));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlRepair.GetRestoreAvailable(AShip: TPlShip): Boolean;
begin
  Result := False;
  try
    Result := (AShip.Destructed > 0)
      and (AShip.Planet.ResAvailIn[resModules] >= GetRestoreCost(AShip));
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlRepair.OnTimer(AShip: TPlShip; var ACounter: Integer;
  var AValue: Integer): Boolean;
begin
  Result := False;
  try
    ACounter := AShip.TechValue(plttRepair);
    // ����������� �� � ��� � ��� ���� �������
    if (AShip.TechActive(plttStationary))
      and (not AShip.Planet.Timer[ppltmBattle])
    then
      ACounter := ACounter * 2;
    // ����������� ��������� ���������� ��
    ACounter := Execute(AShip, ACounter);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlRepair.Execute(AShip: TPlShip; AMount: Integer): Integer;
var
  TmpCount: Integer;
begin
  Result := 0;
  try                 (**)
    while (AMount > 0) do
    begin
      // �������� ��
      if (GetRepairAvailable(AShip)) then
      begin
        AShip.IsDestroyed := pshchSilent;
        TmpCount := Min(AMount, AShip.TechValue(plttHP) - AShip.HP);
        Dec(AMount, TmpCount);
        Inc(Result, TmpCount);
        Inc(AShip.HP, TmpCount);
      end else
      // ��� ����������� ����
      if (GetRestoreAvailable(AShip)) then
      begin
        AShip.IsDestroyed := pshchSilent;
        AShip.HP := 0;
        Inc(AShip.Count);
        Dec(AShip.Destructed);
        TPlanetarThread(Engine).ControlStorages.DecrementResource(resModules, AShip.Planet, GetRestoreCost(AShip));
      end else
        Break;
    end;
    // ������� ��������� ���������
    if (AShip.IsDestroyed = pshchSilent) then
      TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlRepair.Check(AShip: TPlShip);
begin
  try
    // �������� ������� ��� ����������� �������
    if (AShip.Timer[pshtmOpRepair]) then
      Exit();
    // �������� ������� ���������� �����������
    if (not AShip.TechActive(plttRepair)) then
      Exit();
    // �������� ����������� ��������������
    if (GetRepairAvailable(AShip))
      or (GetRestoreAvailable(AShip))
    then
      TPlanetarThread(Engine).WorkerShips.TimerAdd(AShip, pshtmOpRepair, 1, OnTimer);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
