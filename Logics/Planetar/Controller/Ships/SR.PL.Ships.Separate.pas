{**********************************************}
{                                              }
{ Флот : разделение стеков                     }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Separate;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки разделения стеков
  TPLShipsControlSeparate = class(TPLShipsControlCustom)
  public
    // Базовое выполнение
    procedure Execute(AShip: TPlShip; ASlot, ACount: Integer);
    // Выполнение команды игрока
    procedure Player(AShip: TPlShip; ASlot, ACount: Integer; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlSeparate.Execute(AShip: TPlShip; ASlot, ACount: Integer);
var
  TmpShip: TPlShip;
begin
  try
    // Проверка на доступность слота
    if (not CheckMoveTo(AShip, AShip.Planet, ASlot, False)) then
    begin
      TLogAccess.Write(ClassName, 'Check');
      Exit();
    end;
    // Если количество не указано или превышает - разделяем половину
    if (ACount <= 0) or (ACount >= AShip.Count) then
      ACount := AShip.Count div 2;
    // Убавить в текущем стеке
    Dec(AShip.Count, ACount);
    // Создать и расположить новый стек
    TmpShip := CreateShip(AShip.Planet, AShip.ShipType, ASlot, ACount, AShip.Owner);
    // Разделить топливо
    TmpShip.Fuel := AShip.Fuel;
    // Отправить сообщение
    TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(AShip);
    TPlanetarThread(Engine).SocketWriter.ShipCreate(TmpShip);
    // Для планеты с боем кораблик при разделении получает штраф
    if (AShip.Planet.Timer[ppltmBattle]) then
      TPlanetarThread(Engine).ControlShips.Fly.Execute(TmpShip, pshstParking);
    // Добавить в общий стек кораблей
    TPlanetarThread(Engine).ControlShips.AddToPlanet.Execute(
      TmpShip, TmpShip.Planet, False, not AShip.Planet.Timer[ppltmBattle], AShip.Planet.Timer[ppltmBattle]);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlSeparate.Player(AShip: TPlShip; ASlot, ACount: Integer; APlayer: TGlPlayer);
begin
  try
    // Нельзя делить один кораблик
    if (not TPlLanding.Valid(ASlot)) then
    begin
      TLogAccess.Write(ClassName, 'Slot');
      Exit();
    end;
    // Нельзя делить один кораблик
    if (AShip.Count = 1) then
    begin
      TLogAccess.Write(ClassName, 'Count');
      Exit();
    end;
    // Кораблик должен быть доступен
    if (not AShip.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'Operable');
      Exit();
    end;
    // Кораблик не наш
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // Отправим команду
    Execute(AShip, ASlot, ACount);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
