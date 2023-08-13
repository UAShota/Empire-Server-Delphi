{**********************************************}
{                                              }
{ Флот : объединение стеков                    }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Merge;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки объединения стеков
  TPLShipsControlMerge = class(TPLShipsControlCustom)
  public
    // Базовое выполнение
    procedure Execute(ASource, ADestination: TPlShip; ACount: Integer);
    // Выполнение команды игрока
    procedure Player(ASource, ADestination: TPlShip; ACount: Integer; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlMerge.Execute(ASource, ADestination: TPlShip; ACount: Integer);
var
  TmpMerge: Integer;
begin
  try
    // Если количество не указано или превышает - перекидываем весь стек
    if (ACount <= 0) or (ACount > ASource.Count) then
      ACount := ASource.Count;
    // Перекинем сами кораблики
    TmpMerge := Min(ACount + ADestination.Count, ASource.TechValue(plttCount));
    // Проверим что есть что перекидывать
    if (TmpMerge = ADestination.Count) then
    begin
      TLogAccess.Write(ClassName, 'Count');
      Exit();
    end;
    // Перекинем количество
    Dec(ASource.Count, TmpMerge - ADestination.Count);
    ADestination.Count := TmpMerge;
    // Перекинем хп
    TmpMerge := Min(ASource.HP + ADestination.HP, ASource.TechValue(plttHp));
    Dec(ASource.HP, TmpMerge - ADestination.HP);
    ADestination.HP := TmpMerge;
    // И если в источнике кораблей больше нет - прибьем объект
    if (ASource.Count = 0) then
      TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(ASource, True, False, False)
    else
      TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(ASource);
    // Отправить сообщение
    TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(ADestination);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlMerge.Player(ASource, ADestination: TPlShip; ACount: Integer; APlayer: TGlPlayer);
begin
  try
    // Объеденяемые корабли должны быть одной расы, иметь одного владельца и быть не полной пачкой
    if (ASource.ShipType <> ADestination.ShipType) then
    begin
      TLogAccess.Write(ClassName, 'ShipType');
      Exit();
    end;
    // Нельзя объединять кораблик сам с собой
    if (ASource = ADestination) then
    begin
      TLogAccess.Write(ClassName, 'Destination');
      Exit();
    end;
    // Нельзя объеденять флот разных владельцев
    if (ASource.Owner <> ADestination.Owner) then
    begin
      TLogAccess.Write(ClassName, 'Owner');
      Exit();
    end;
    // Нельзя объеденять на разных планетах
    if (ASource.Planet <> ADestination.Planet) then
    begin
      TLogAccess.Write(ClassName, 'Range');
      Exit();
    end;
    // Исходный кораблик не в простое
    if (not ASource.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'SourceState');
      Exit();
    end;
    // Конечный кораблик не в простое
    if (not ADestination.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'DestinationState');
      Exit();
    end;
    // Иначе запустим объединение
    Execute(ASource, ADestination, ACount);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
