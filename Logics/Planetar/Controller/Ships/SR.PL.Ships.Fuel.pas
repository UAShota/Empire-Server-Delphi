{**********************************************}
{                                              }
{ Флот : заправка топливом                     }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Fuel;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки заправки топливом
  TPLShipsControlFuel = class(TPLShipsControlCustom)
  private
    // Таймер события добавления единицы топлива
    function OnTimer(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean;
    // Возвращение времени генерации единицы топлива
    function GetChargeTime(): Integer;
    // Признак полного бака
    function GetIsFull(AShip: TPlShip): Boolean;
  public
    // Базовое выполнение
    function Execute(AShip: TPlShip; ACount: Integer): Integer;
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlFuel.OnTimer(AShip: TPlShip; var ACounter: Integer;
  var AValue: Integer): Boolean;
begin
  Result := False;
  try
    // Таймер не закончен
    if (ACounter > 0) then
    begin
      Dec(ACounter);
      Exit();
    end else
      Result := True;
    // Пополняем
    Execute(AShip, 1);
    // Если не полный - продлеваем таймер
    if (not GetIsFull(AShip)) then
    begin
      ACounter := GetChargeTime();
      AValue := ACounter;
    end;
    // Отправим сообщение о смене таймера
    Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlFuel.GetChargeTime(): Integer;
begin
  Result := 0;
  try
    Result := 30;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlFuel.GetIsFull(AShip: TPlShip): Boolean;
begin
  Result := True;
  try
    Result := (AShip.Fuel >= I_MAX_FUEL_COUNT);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlFuel.Execute(AShip: TPlShip; ACount: Integer): Integer;
begin
  Result := 0;
  try
    if (ACount = 0) then
    begin
      TLogAccess.Write(ClassName, 'NoCount');
      Exit();
    end;
    // Удаление заряда
    if (ACount < 0) then
    begin
      // Кораблик и так пустой
      if (AShip.Fuel = 0) then
      begin
        TLogAccess.Write(ClassName, 'NoFuel');
        Exit();
      end;
      // Сколько можно слить
      Result := Max(-AShip.Fuel, ACount);
      // Включим таймер пополнения
      TPlanetarThread(Engine).WorkerShips.TimerAdd(AShip, pshtmOpRefill, GetChargeTime(), OnTimer);
    end else
    // Добавление заряда
    begin
      // Кораблик заправлен под завязку
      if (GetIsFull(AShip)) then
      begin
        TLogAccess.Write(ClassName, 'IsFull');
        Exit();
      end;
      // Сколько можно заправить
      Result := I_MAX_FUEL_COUNT - AShip.Fuel;
      // Сколько нужно заправить
      Result := Min(Result, ACount);
    end;
    // Меняем
    Inc(AShip.Fuel, Result);
    // Отправим сообщение
    TPlanetarThread(Engine).SocketWriter.ShipRefill(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
