{**********************************************}
{                                              }
{ Флот : выпинывание всех кораблей с орбиты    }
{        планеты, в ангар или взрыв            }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Escape;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки принудительного слета с планетоида
  TPLShipsControlEscape = class(TPLShipsControlCustom)
  public
    // Базовое выполнение
    procedure Execute(APlanet: TPlPlanet);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlEscape.Execute(APlanet: TPlPlanet);
var
  TmpI: Integer;
  TmpDone: Boolean;
  TmpShip: TPlShip;
  TmpSlot: Integer;
  TmpPlanet: TPlPlanet;
begin
  try
    // Попробуем раскидать все корабли
    for TmpI := Pred(APlanet.Ships.Count) downto 0 do
    begin
      TmpShip := APlanet.Ships[TmpI];
      TmpDone := False;
      // Попробуем принудительно отправить на другую планету только если есть топливо
      if (TmpShip.Fuel <= 0) then
        Continue;
      // Перебираем планеты для отправки
      for TmpPlanet in APlanet.Links do
      begin
        TmpSlot := GetFreeSlot(TmpShip.TechActive(plttIntoBackzone), TmpPlanet, TmpShip.TechActive(plttLowOrbit), TmpShip.Owner);
        if (TmpSlot > 0)
          and CheckArrival(TmpPlanet, TmpShip.TechActive(plttLowOrbit), TmpShip.Landing, TmpSlot, TmpShip.Planet, TmpShip.Owner, False)
          and TPlanetarThread(Engine).ControlShips.MoveToPlanet.Execute(TmpShip, TmpPlanet, TmpSlot, False) then
        begin
          TmpDone := True;
          Break;
        end;
      end;
      // Если и в ангар не выходит отправить - взрываем корабль
      if (not TmpDone)
        and (not TPlanetarThread(Engine).ControlShips.MoveToHangar.Execute(0, TmpShip))
      then
        TPlanetarThread(Engine).ControlShips.Destruct.Execute(TmpShip);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
