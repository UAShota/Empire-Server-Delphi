{**********************************************}
{                                              }
{ Флот : отправка в ангар                      }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.MoveToHangar;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Hangar,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс отправки в ангар
  TPLShipsControlMoveToHangar = class(TPLShipsControlCustom)
  public
    // Базовое выполнение
    function Execute(AHangarSlot: Integer; AShip: TPlShip): Boolean;
    // Выполнение команды игрока
    procedure Player(AHangarSlot: Integer; AShip: TPlShip; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Profile,
  SR.Planetar.Thread;

function TPLShipsControlMoveToHangar.Execute(AHangarSlot: Integer; AShip: TPlShip): Boolean;
var
  TmpHangar: TPlHangar;
  TmpHangarSlot: TPlHangarSlot;
begin
  Result := False;
  try
    TmpHangar := TPlanetarProfile(AShip.Owner.PlanetarProfile).Hangar;
    // Проверим топливо
    if (AShip.Fuel < I_FUEL_FOR_HANGAR) then
    begin
      TLogAccess.Write(ClassName, 'NoFuel');
      Exit()
    end;
    // Слот не указан или не валидный
    if (AHangarSlot < 0)
      or (AHangarSlot > TmpHangar.Size) then
    begin
      TLogAccess.Write(ClassName, 'Invalid');
      Exit();
    end;
    // Ангар и слот
    TmpHangarSlot := TmpHangar.Slots[AHangarSlot];
    // В ангаре в этом слоту корабль этого-же типа
    if (TmpHangarSlot.ShipType = AShip.ShipType) then
      Result := TmpHangar.Change(AHangarSlot, AShip.Count, AShip.Owner)
    else
    // В ангаре в этом слоту пусто
    if (TmpHangarSlot.ShipType = pshtpEmpty) then
      Result := TmpHangar.Add(AHangarSlot, AShip.Count, AShip.ShipType, AShip.Owner)
    else
    // Слот занят
    begin
      TLogAccess.Write(ClassName, 'Type');
      Exit();
    end;
    // Добавить не получилось
    if (not Result) then
      TLogAccess.Write(ClassName, 'Full')
    else
      TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(AShip, True, False, False);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlMoveToHangar.Player(AHangarSlot: Integer; AShip: TPlShip;
  APlayer: TGlPlayer);
begin
  try
    // Нельзя отправить чужой кораблик
    if (AShip.Owner <> APlayer) then
    begin
      TLogAccess.Write(ClassName, 'Owner');
      Exit();
    end;
    // Нельзя отправлять в ангар стационарный юнит
    if (AShip.TechActive(plttStationary)) then
    begin
      TLogAccess.Write(ClassName, 'Stationary');
      Exit();
    end;
    // Нельзя отправлять в ангар из битвы
    if (AShip.Planet.Timer[ppltmBattle]) then
    begin
      TLogAccess.Write(ClassName, 'Battle');
      Exit();
    end;
    // Нельзя отправлять юнит не в простое
    if (not AShip.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'Battle');
      Exit();
    end;
    // Пробуем высадиться
    Execute(AHangarSlot, AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
