{**********************************************}
{                                              }
{ ���� : ����� ��������� ������ / � �������    }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.ChangeActivity;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ����� ��������� / ������� ������
  TPLShipsControlChangeActivity = class(TPLShipsControlCustom)
  public
    // ������� ����������
    procedure Execute(AShip: TPlShip);
    // ���������� ������� ������
    procedure Player(AShip: TPlShip; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlChangeActivity.Execute(AShip: TPlShip);
begin
  try
    // �������� ��� ��������� �������
    if (AShip.Mode = pshmdOffline) then
    begin
      // � ��� ��� ������������ ��������� ������ �����
      if (AShip.Planet.Timer[ppltmBattle]) then
      begin
        AShip.Mode := pshmdActive;
        TPlanetarThread(Engine).ControlShips.Fly.Execute(AShip, pshstParking);
      end else
        TPlanetarThread(Engine).ControlShips.StandUp.Execute(AShip);
    end else
      TPlanetarThread(Engine).ControlShips.StandDown.Execute(AShip, pshmdOffline);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlChangeActivity.Player(AShip: TPlShip; APlayer: TGlPlayer);
begin
  try
    // ������ ������ ���������� �� � �������
    if (not AShip.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'Operable');
      Exit();
    end;
    // ������ ��������� ������ �����������
    if (AShip.Owner.IsRoleEnemy(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // �������� ����� ������
    Execute(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
