{**********************************************}
{                                              }
{ ������ ���������� �������� � �����������     }
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
  // ����� ������� ��������� ��� ������
  TPlanetarWorkerPlanets = class(TPlanetarCustom)
  private type
    // ����� �������� �������
    TTimerItem = class
    public
      // ������
      Timer: TPlPlanetTimer;
      // ���������
      Planet: TPlPlanet;
      // ���������� ����� �� ����������
      Count: Integer;
      // ������� ������������ �������
      OnTimer: TPlPlanetTimerCallback;
    end;
    // ����� ������ ��������
    TTimers = TList<TTimerItem>;
  private var
    // ������ ��������
    FTimers: TTimers;
  private
    // ��������� ������
    procedure DoCheckPlanets();
    // ��������� ����������� �����
    procedure DoWorkTimerPlanet(AIndex: Integer);
  public
    constructor Create(AEngine: TObject); override;
    destructor Destroy(); override;
    // ��������� � ���
    procedure Work(); override;
    // ���������� ������� ��� �������
    function TimerAdd(APlanet: TPlPlanet; ATimer: TPlPlanetTimer; ACount: Integer;
      AOnTimer: TPlPlanetTimerCallback; ASend: Integer = 0): TTimerItem;
    // �������� ���������� ������� ��� �������
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
    // ������ ����� ������ ������
    if (not Assigned(TmpItem.Planet)) then
    begin
      FTimers.Delete(AIndex);
      Exit();
    end;
    // ���� ����� - ������ �� ������
    if (TmpItem.Count = 0) then
    begin
      FTimers.Delete(AIndex);
      TmpItem.Planet.Timer[TmpItem.Timer] := False;
    end;
    // �� ��������� ������ �������
    TmpValue := 0;
    // ���� ������� ��������, �� �������� ��������� � ����� �������� �������
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
    // ������ ����� ��������� ���� ��������, � ��������� ������
    if (ASend = 0) then
      ASend := ACount;
    // ���� ������� ���, �� ����� �������
    if (not APlanet.Timer[ATimer]) then
    begin
      APlanet.Timer[ATimer] := True;
      Result.Timer := ATimer;
      Result.Planet := APlanet;
      Result.OnTimer := AOnTimer;
      FTimers.Add(Result);
    end else
    // ���� ���� - ������ ������
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
    // �������� ��������� � ����� �������� �������
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
      // ������ �� ������ �������� �������������� �������
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
