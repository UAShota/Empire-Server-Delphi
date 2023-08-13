{**********************************************}
{                                              }
{ Флот : добавление юнита на планету           }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.AddToPlanet;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки добавления юнита на планету
  TPLShipsControlAddToPlanet = class(TPLShipsControlCustom)
  public
    // Базовое выполнение
    procedure Execute(AShip: TPlShip; APlanet: TPlPlanet; ARecalc, AChangeState, ARetarget: Boolean);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlAddToPlanet.Execute(AShip: TPlShip; APlanet: TPlPlanet;
  ARecalc, AChangeState, ARetarget: Boolean);
begin
  try
    // Добавление корабля на целевую планету
    APlanet.Landings.Add(AShip);
    // При загрузке с БД нельзя менять состояние
    TPlanetarThread(Engine).ControlShips.StandUp.Execute(AShip, AChangeState, AChangeState, True, ARetarget);
    // Обновление параметров планеты
    if (ARecalc) then
      TPlanetarThread(Engine).ControlPlanets.UpdateShipList(AShip, AShip.Count);
    // Добавим кораблик к контролю
    TPlanetarThread(Engine).ControlPlanets.PlayerControlChange(APlanet, AShip.Owner, True,
      AShip.Landing.IsLowOrbit);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
