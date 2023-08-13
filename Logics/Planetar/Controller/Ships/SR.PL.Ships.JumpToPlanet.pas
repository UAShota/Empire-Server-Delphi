{**********************************************}
{                                              }
{ Флот : принудительный прыжок на планету      }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.JumpToPlanet;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки принудительного прыжка на планету
  TPLShipsControlJumpToPlanet = class(TPLShipsControlCustom)
  public
    // Базовое выполнение
    function Execute(AShip: TPlShip; ADestination: TPlPlanet): Boolean;
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlJumpToPlanet.Execute(AShip: TPlShip; ADestination: TPlPlanet): Boolean;
var
  TmpSlot: Integer;
  TmpPlanet: TPlPlanet;
begin
  Result := False;
  try
    // Если свободного слота нет - прыжок отменяется
    TmpSlot := GetFreeSlot(AShip.TechActive(plttIntoBackzone), ADestination, False, AShip.Owner);
    if (TmpSlot = 0) then
      Exit();
    // Проверка на возможность прилета
    if (not CheckArrival(ADestination, False, AShip.Landing, TmpSlot, AShip.Planet, AShip.Owner, False)) then
      Exit();
    // Уберем текущий стек
    TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(AShip, False, False, True);
    // Выставим параметры
    (**)
    TmpPlanet := AShip.Planet;
    AShip.IsAutoAttach := False;
    AShip.IsTargeted := False;
    AShip.Planet := ADestination;
    AShip.Landing := TmpSlot;
    // Отправим сообщение о прыжке
    TPlanetarThread(Engine).SocketWriter.ShipJumpTo(AShip, TmpPlanet, TmpSlot);
    // Добавим его на новую планету и возведем в боевой режим
    TPlanetarThread(Engine).ControlShips.AddToPlanet.Execute(AShip, ADestination, True, True, True);
    // Перенесем кораблик
    Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
