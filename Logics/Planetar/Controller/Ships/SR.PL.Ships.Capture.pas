{**********************************************}
{                                              }
{ Флот : захват контроля над планетоидом       }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Capture;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки захвата контроля
  TPLShipsControlCapture = class(TPLShipsControlCustom)
  public
    // Базовое выполнение
    procedure Execute(AShip: TPlShip; AStop: Boolean);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlCapture.Execute(AShip: TPlShip; AStop: Boolean);
begin
  try
    if (not AShip.TechActive(plttCapturer)) then
      Exit();
    // Выключение захвата
    if (not AStop) then
    begin
      if (AShip.IsCapture) then
        AShip.IsCapture := False
      else
        Exit();
    end else
    // Включение захвата
    if (Assigned(AShip.Attached)) then
    begin
      // Захватывать можно только свою планету
      if (AShip.Planet <> AShip.Attached) then
      begin
        TLogAccess.Write(ClassName, 'Planet');
        Exit();
      end;
      // Нельзя захватывать неактивным корабликом
      if (not AShip.IsStateActive) then
      begin
        TLogAccess.Write(ClassName, 'Active');
        Exit();
      end;
      // Нельзя захватить нежилую планету
      if (not AShip.Planet.IsManned) then
      begin
        TLogAccess.Write(ClassName, 'Manned');
        Exit();
      end;
      // Нельзя захватывать дружественную планету
      if (AShip.Attached.Owner.IsRoleFriend(AShip.Owner)) then
      begin
        TLogAccess.Write(ClassName, 'Friend');
        Exit();
      end;
      // Выставим признак захвата
      AShip.IsCapture := True;
      // Если это первый штурм - добавим обработку планеты
      if (not AShip.Attached.Timer[ppltmCapture]) then
        TPlanetarThread(Engine).ControlPlanets.Capture.Execute(AShip.Attached);
    end;
    // Отправим сообщение о смене состояния
    TPlanetarThread(Engine).SocketWriter.ShipUpdateState(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
