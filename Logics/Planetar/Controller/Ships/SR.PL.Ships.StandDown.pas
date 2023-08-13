{**********************************************}
{                                              }
{ Флот : учет удаления юнита с планетоида и    }
{        попытка перевести в пассивный режим   }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.StandDown;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки удаления юнита из учета количества или актива
  TPLShipsControlStandDown = class(TPLShipsControlCustom)
  private
    // Восстановить вражеские юниты из блокировки при слете
    procedure DoStandUpBlocked(AShip: TPlShip);
    // Восстановить свой юнит из переполнения при слете
    procedure DoStandUpShips(AShip: TPlShip);
  public
    // Базовое выполнение
    procedure Execute(AShip: TPlShip; AMode: TPlShipMode; AChangeCount: Boolean = False);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlStandDown.DoStandUpShips(AShip: TPlShip);
var
  TmpShip: TPlShip;
begin
  try
    // Включим кораблик, который был в перелимите
    for TmpShip in AShip.Planet.Ships do
      if (TmpShip.Mode = pshmdFull)
        and (AShip.Owner.IsRoleFriend(TmpShip.Owner)) then
    begin
      TPlanetarThread(Engine).ControlShips.StandUp.Execute(TmpShip);
      Break;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlStandDown.DoStandUpBlocked(AShip: TPlShip);
var
  TmpShip: TPlShip;
begin
  try
    // Включим кораблик справа
    TmpShip := CheckShipBlocker(AShip, AShip.Landing.Prev(), True, pshmdBlocked);
    if (TmpShip <> nil)
      and (TmpShip.Mode = pshmdBlocked)
    then
      TPlanetarThread(Engine).ControlShips.StandUp.Execute(TmpShip);
    // Включим кораблик слева
    TmpShip := CheckShipBlocker(AShip, AShip.Landing.Next(), True, pshmdBlocked);
    if (TmpShip <> nil)
      and (TmpShip.Mode = pshmdBlocked)
    then
      TPlanetarThread(Engine).ControlShips.StandUp.Execute(TmpShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlStandDown.Execute(AShip: TPlShip; AMode: TPlShipMode;
  AChangeCount: Boolean = False);
var
  TmpIndex: TPlShipsCountPair;
  TmpCount: TPlShipsCount;
  TmpFlagFound: Boolean;
begin
  try
    // Нижние стеки не учитываются при удалении корабля
    if (AShip.Landing.IsLowOrbit) then
      Exit();
    // А для боевых стеков проведем логику
    TmpFlagFound := False;
    TmpCount.Value := 0;
    // Переберем все стеки планеты
    for TmpIndex in AShip.Planet.ShipCount do
    begin
      if (not TmpFlagFound) then
        TmpFlagFound := (TmpIndex.Key = AShip.Owner);
      // Найдем союзные стеки для обновления количество стеков на планете
      if (not AShip.Owner.IsRoleFriend(TmpIndex.Key)) then
        Continue;
      // Заберем количество стеков
      TmpCount := TmpIndex.Value;
      // Удалим запись если это последний кораблик игрока
      if (AChangeCount and (TmpCount.Exist = 1)) then
      begin
        AShip.Planet.ShipCount.Remove(TmpIndex.Key);
        Continue;
      end;
      // Если кораблик убит в полете - он еще пассивный и не учитывается как активный
      Dec(TmpCount.Exist, Ord(AChangeCount));
      Dec(TmpCount.Active, Ord(AShip.IsStateActive));
      // Сохраним текущее количество дружеских стеков
      AShip.Planet.ShipCount[TmpIndex.Key] := TmpCount;
    end;
    // Не меняем статус для уничтоженных корабликов
    if (not AChangeCount and (AShip.Mode <> AMode)) then
    begin
      AShip.Mode := AMode;
      // Обновим состояние кораблика
      TPlanetarThread(Engine).SocketWriter.ShipUpdateState(AShip);
    end;
    // Восстановим из перелимита свой стек (6 минус перелимит минус выключенный)
    if (TmpCount.Active = I_MAX_SHIP_REFILL) then
      DoStandUpShips(AShip);
    // Разблокируем крайние вражеские
    DoStandUpBlocked(AShip);
    // Уберем захват, если есть
    TPlanetarThread(Engine).ControlShips.Capture.Execute(AShip, False);
    // Переприцелим кораблики
    TPlanetarThread(Engine).ControlPlanets.Retarget(AShip, AShip.IsTargeted);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.

