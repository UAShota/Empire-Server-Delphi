{**********************************************}
{                                              }
{ Флот : Уничтожение стека                     }
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
  // Класс обработки добровольного уничтожения юнита
  TPLShipsControlDestruct = class(TPLShipsControlCustom)
  public
    // Базовое выполнение
    procedure Execute(AShip: TPlShip);
    // Выполнение команды игрока
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
    // Нельзя менять активность не в простое
    if (AShip.Planet.Timer[ppltmBattle]) then
    begin
      TLogAccess.Write(ClassName, 'Battle');
      Exit();
    end;
    // Нельзя менять активность не в простое
    if (not AShip.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'Operable');
      Exit();
    end;
    // Нельзя управляьт чужими корабликами
    if (AShip.Owner.IsRoleEnemy(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // Выполним смену режима
    Execute(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
