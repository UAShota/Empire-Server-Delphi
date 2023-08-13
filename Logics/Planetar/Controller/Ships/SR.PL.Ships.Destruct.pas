{**********************************************}
{                                              }
{ ���� : ����������� �����                     }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Destruct;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ������������� ����������� �����
  TPLShipsControlDestruct = class(TPLShipsControlCustom)
  public
    // ������� ����������
    procedure Execute(AShip: TPlShip);
    // ���������� ������� ������
    procedure Player(AShip: TPlShip; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlDestruct.Execute(AShip: TPlShip);
begin
  try
    TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(AShip, True, True, True);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlDestruct.Player(AShip: TPlShip; APlayer: TGlPlayer);
begin
  try
    // ������ ������ ���������� �� � �������
    if (AShip.Planet.Timer[ppltmBattle]) then
    begin
      TLogAccess.Write(ClassName, 'Battle');
      Exit();
    end;
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
