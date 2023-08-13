{**********************************************}
{                                              }
{ Модуль тиковой обработки для корабликов      }
{       Copyright (c) 2016 UAShota              }
{                                              }
{   Rev B  2017.03.30                          }
{   Rev D  2018.03.03                          }
{                                              }
{**********************************************}
unit SR.Planetar.Worker.Ships;

interface

uses
  System.SysUtils,
  System.Generics.Collections,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.Planetar.Custom;

type
  // Класс тиковой обработки для корабликов
  TPlanetarWorkerShips = class(TPlanetarCustom)
  private type
    // Класс элемента таймера
    TTimerItem = class
    public
      // Таймер
      Timer: TPlShipTimer;
      // Юнит
      Ship: TPlShip;
      // Количество тиков до завершения
      Count: Integer;
      // Каллбак срабатывания таймера
      OnTimer: TPlShipTimerCallback;
    end;
    // Класс списка таймеров
    TTimers = TList<TTimerItem>;
  private var
    // Список таймеров
    FTimers: TTimers;
    // Список групп корабликов
    FGroups: TPlShipGroupList;
  private
    // Обработка флота
    procedure DoCheckShips();
    // Обработка группы флота
    procedure DoCheckGroups();
    // Обработка конкретного юнита
    procedure DoWorkTimerShip(AIndex: Integer);
    // Проверка времени прилета группы
    procedure DoWorkTimerGroup(AShipGroup: TPlShipGroup);
  public
    constructor Create(AEngine: TObject); override;
    destructor Destroy(); override;
    // Обработка в тик
    procedure Work(); override;
    // Добавление таймера для корабля
    function TimerAdd(AShip: TPlShip; ATimer: TPlShipTimer; ACount: Integer;
      AOnTimer: TPlShipTimerCallback; ASend: Integer = 0): TTimerItem;
    // Удаление всех таймеров для корабля
    procedure TimerRemove(AShip: TPlShip); overload;
    // Удаление указанного таймера для корабля
    procedure TimerRemove(AShip: TPlShip; ATimer: TPlShipTimer); overload;
    // Добавление новой группы
    procedure GroupAdd(AShipGroup: TPlShipGroup);
  end;

implementation

uses
  SR.Planetar.Thread;

constructor TPlanetarWorkerShips.Create(AEngine: TObject);
begin
  try
    inherited;
    FTimers := TTimers.Create();
    FGroups := TPlShipGroupList.Create();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

destructor TPlanetarWorkerShips.Destroy();
begin
  try
    FreeAndNil(FGroups);
    FreeAndNil(FTimers);
    inherited;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerShips.Work();
begin
  try
    DoCheckShips();
    DoCheckGroups();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerShips.DoCheckShips();
var
  TmpI: Integer;
begin
  try
    for TmpI := Pred(FTimers.Count) downto 0 do
      DoWorkTimerShip(TmpI);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerShips.DoWorkTimerShip(AIndex: Integer);
var
  TmpItem: TTimerItem;
  TmpValue: Integer;
begin
  try
    TmpItem := FTimers.Items[AIndex];
    // Удалим ранее убитый таймер
    if (not Assigned(TmpItem.Ship)) then
    begin
      FTimers.Delete(AIndex);
      Exit();
    end;
    // Если вышло - уберем из списка
    if (TmpItem.Count = 0) then
    begin
      FTimers.Delete(AIndex);
      TmpItem.Ship.Timer[TmpItem.Timer] := False;
    end;
    // По умолчанию таймер окончен
    TmpValue := 0;
    // Если счетчик сменился и кораблик цел, то отправим сообщение о новом значении таймера
    if (TmpItem.OnTimer(TmpItem.Ship, TmpItem.Count, TmpValue))
      and (TmpItem.Ship.IsDestroyed = pshchNone)
    then
      TPlanetarThread(Engine).SocketWriter.ShipUpdateTimer(TmpItem.Ship, TmpItem.Timer, TmpValue);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end
end;

procedure TPlanetarWorkerShips.DoCheckGroups();
var
  TmpI: Integer;
begin
  try
    for TmpI := Pred(FGroups.Count) downto 0 do
      DoWorkTimerGroup(FGroups[TmpI]);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerShips.DoWorkTimerGroup(AShipGroup: TPlShipGroup);
begin
  try
    TPlanetarThread(Engine).ControlShips.Group.Move(AShipGroup);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPlanetarWorkerShips.TimerAdd(AShip: TPlShip; ATimer: TPlShipTimer; ACount: Integer;
  AOnTimer: TPlShipTimerCallback; ASend: Integer = 0): TTimerItem;
var
  TmpI: Integer;
begin
  Result := nil;
  try
    Result := TTimerItem.Create();
    Result.Count := ACount;
    // Иногда нужно сохранить одно значение, а отправить другое
    if (ASend = 0) then
      ASend := ACount;
    // Если таймера нет, то сразу добавим
    if (not AShip.Timer[ATimer]) then
    begin
      AShip.Timer[ATimer] := True;
      Result.Timer := ATimer;
      Result.Ship := AShip;
      Result.OnTimer := AOnTimer;
      FTimers.Add(Result);
    end else
    // Если есть - поищем запись
    begin
      for TmpI := Pred(FTimers.Count) downto 0 do
      begin
        Result := FTimers[TmpI];
        if (Result.Timer = ATimer)
          and (Result.Ship = AShip) then
        begin
          FTimers[TmpI] := Result;
          Break;
        end;
      end;
    end;
    // Отправим сообщение о новом значении таймера
    TPlanetarThread(Engine).SocketWriter.ShipUpdateTimer(AShip, ATimer, ASend);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerShips.TimerRemove(AShip: TPlShip);
var
  TmpTimer: TPlShipTimer;
begin
  try
    for TmpTimer := Low(AShip.Timer) to High(AShip.Timer) do
      if (AShip.Timer[TmpTimer]) then
        TimerRemove(AShip, TmpTimer);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerShips.TimerRemove(AShip: TPlShip; ATimer: TPlShipTimer);
var
  TmpI: Integer;
  TmpItem: TTimerItem;
begin
  try
    for TmpI := Pred(FTimers.Count) downto 0 do
    begin
      TmpItem := FTimers[TmpI];
      // Удалим из списка кораблик сопоставленный таймеру
      if (TmpItem.Timer = ATimer)
        and (TmpItem.Ship = AShip) then
      begin
        AShip.Timer[ATimer] := False;
        TmpItem.Ship := nil;
        Break;
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerShips.GroupAdd(AShipGroup: TPlShipGroup);
begin
  try
    FGroups.Add(AShipGroup);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
