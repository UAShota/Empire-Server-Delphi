{**********************************************}
{                                              }
{ Боевка : обработка боевого тика              }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{                                              }
{**********************************************}
unit SR.PL.Planets.Battle;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Planets.Custom;

type
  // Класс обработки боевого тика
  TPLPlanetsControlBattle = class(TPLPlanetsControlCustom)
  private
    // Срабатывание таймера операции
    function OnTimer(APlanet: TPlPlanet; var ACounter: Integer; var AValue: Integer): Boolean;
  public
    // Базовое выполнение
    procedure Execute(APlanet: TPlPlanet);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLPlanetsControlBattle.OnTimer(APlanet: TPlPlanet; var ACounter, AValue: Integer): Boolean;
begin
  Result := False;
  try
    if (not TPlanetarThread(Engine).ControlShips.Battle.Execute(APlanet)) then
    begin
      ACounter := 0;
      Result := True;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLPlanetsControlBattle.Execute(APlanet: TPlPlanet);
begin
  TPlanetarThread(Engine).WorkerPlanets.TimerAdd(APlanet, ppltmBattle, 1, OnTimer);
end;

end.
