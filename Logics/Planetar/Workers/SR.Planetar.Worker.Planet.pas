{**********************************************}
{                                              }
{ Модуль управления действия с планетоидом     }
{       Copyright (c) 2016 UAShota              }
{                                              }
{   Rev A  2016.12.06                          }
{                                              }
{**********************************************}
unit SR.Planetar.Worker.Planet;

interface

uses
  System.SysUtils,
  System.Generics.Collections,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.Planetar.Custom;

type
  // Класс тиковой обработки для планет
  TPlanetarWorkerPlanets = class(TPlanetarCustom)
  private type
    // Класс элемента таймера
    TTimerItem = class
    public
      // Таймер
      Timer: TPlPlanetTimer;
      // Планетоид
      Planet: TPlPlanet;
      // Количество тиков до завершения
      Count: Integer;
      // Каллбак срабатывания таймера
      OnTimer: TPlPlanetTimerCallback;
    end;
    // Класс списка таймеров
    TTimers = TList<TTimerItem>;
  private var
    // Список таймеров
    FTimers: TTimers;
  private
    // Обработка планет
    procedure DoCheckPlanets();
    // Обработка конкретного юнита
    procedure DoWorkTimerPlanet(AIndex: Integer);
  public
    constructor Create(AEngine: TObject); override;
    destructor Destroy(); override;
    // Обработка в тик
    procedure Work(); override;
    // Добавление таймера для корабля
    function TimerAdd(APlanet: TPlPlanet; ATimer: TPlPlanetTimer; ACount: Integer;
      AOnTimer: TPlPlanetTimerCallback; ASend: Integer = 0): TTimerItem;
    // Удаление указанного таймера для корабля
    procedure TimerRemove(APlanet: TPlPlanet; ATimer: TPlPlanetTimer); overload;
  end;

implementation

uses
  SR.Planetar.Thread;

constructor TPlanetarWorkerPlanets.Create(AEngine: TObject);
begin
  try
    inherited;
    FTimers := TTimers.Create();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

destructor TPlanetarWorkerPlanets.Destroy();
begin
  try
    FreeAndNil(FTimers);
    inherited;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerPlanets.Work();
begin
  try
    DoCheckPlanets();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerPlanets.DoCheckPlanets();
var
  TmpI: Integer;
begin
  try
    for TmpI := Pred(FTimers.Count) downto 0 do
      DoWorkTimerPlanet(TmpI);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerPlanets.DoWorkTimerPlanet(AIndex: Integer);
var
  TmpItem: TTimerItem;
  TmpValue: Integer;
begin
  try
    TmpItem := FTimers.Items[AIndex];
    // Удалим ранее убитый таймер
    if (not Assigned(TmpItem.Planet)) then
    begin
      FTimers.Delete(AIndex);
      Exit();
    end;
    // Если вышло - уберем из списка
    if (TmpItem.Count = 0) then
    begin
      FTimers.Delete(AIndex);
      TmpItem.Planet.Timer[TmpItem.Timer] := False;
    end;
    // По умолчанию таймер окончен
    TmpValue := 0;
    // Если счетчик сменился, то отправим сообщение о новом значении таймера
    if (TmpItem.OnTimer(TmpItem.Planet, TmpItem.Count, TmpValue)) then
      TPlanetarThread(Engine).SocketWriter.PlanetUpdateTimer(TmpItem.Planet, TmpItem.Timer, TmpValue);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end
end;

function TPlanetarWorkerPlanets.TimerAdd(APlanet: TPlPlanet; ATimer: TPlPlanetTimer; ACount: Integer;
  AOnTimer: TPlPlanetTimerCallback; ASend: Integer): TTimerItem;
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
    if (not APlanet.Timer[ATimer]) then
    begin
      APlanet.Timer[ATimer] := True;
      Result.Timer := ATimer;
      Result.Planet := APlanet;
      Result.OnTimer := AOnTimer;
      FTimers.Add(Result);
    end else
    // Если есть - поищем запись
    begin
      for TmpI := Pred(FTimers.Count) downto 0 do
      begin
        Result := FTimers[TmpI];
        if (Result.Timer = ATimer)
          and (Result.Planet = APlanet) then
        begin
          FTimers[TmpI] := Result;
          Break;
        end;
      end;
    end;
    // Отправим сообщение о новом значении таймера
    TPlanetarThread(Engine).SocketWriter.PlanetUpdateTimer(APlanet, ATimer, ASend);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarWorkerPlanets.TimerRemove(APlanet: TPlPlanet; ATimer: TPlPlanetTimer);
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
        and (TmpItem.Planet = APlanet) then
      begin
        APlanet.Timer[ATimer] := False;
        TmpItem.Planet := nil;
        Break;
      end;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
