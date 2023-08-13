{**********************************************}
{                                              }
{ ������ ������� ��������� ��� ����������      }
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
  // ����� ������� ��������� ��� ����������
  TPlanetarWorkerShips = class(TPlanetarCustom)
  private type
    // ����� �������� �������
    TTimerItem = class
    public
      // ������
      Timer: TPlShipTimer;
      // ����
      Ship: TPlShip;
      // ���������� ����� �� ����������
      Count: Integer;
      // ������� ������������ �������
      OnTimer: TPlShipTimerCallback;
    end;
    // ����� ������ ��������
    TTimers = TList<TTimerItem>;
  private var
    // ������ ��������
    FTimers: TTimers;
    // ������ ����� ����������
    FGroups: TPlShipGroupList;
  private
    // ��������� �����
    procedure DoCheckShips();
    // ��������� ������ �����
    procedure DoCheckGroups();
    // ��������� ����������� �����
    procedure DoWorkTimerShip(AIndex: Integer);
    // �������� ������� ������� ������
    procedure DoWorkTimerGroup(AShipGroup: TPlShipGroup);
  public
    constructor Create(AEngine: TObject); override;
    destructor Destroy(); override;
    // ��������� � ���
    procedure Work(); override;
    // ���������� ������� ��� �������
    function TimerAdd(AShip: TPlShip; ATimer: TPlShipTimer; ACount: Integer;
      AOnTimer: TPlShipTimerCallback; ASend: Integer = 0): TTimerItem;
    // �������� ���� �������� ��� �������
    procedure TimerRemove(AShip: TPlShip); overload;
    // �������� ���������� ������� ��� �������
    procedure TimerRemove(AShip: TPlShip; ATimer: TPlShipTimer); overload;
    // ���������� ����� ������
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
    // ������ ����� ������ ������
    if (not Assigned(TmpItem.Ship)) then
    begin
      FTimers.Delete(AIndex);
      Exit();
    end;
    // ���� ����� - ������ �� ������
    if (TmpItem.Count = 0) then
    begin
      FTimers.Delete(AIndex);
      TmpItem.Ship.Timer[TmpItem.Timer] := False;
    end;
    // �� ��������� ������ �������
    TmpValue := 0;
    // ���� ������� �������� � �������� ���, �� �������� ��������� � ����� �������� �������
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
    // ������ ����� ��������� ���� ��������, � ��������� ������
    if (ASend = 0) then
      ASend := ACount;
    // ���� ������� ���, �� ����� �������
    if (not AShip.Timer[ATimer]) then
    begin
      AShip.Timer[ATimer] := True;
      Result.Timer := ATimer;
      Result.Ship := AShip;
      Result.OnTimer := AOnTimer;
      FTimers.Add(Result);
    end else
    // ���� ���� - ������ ������
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
    // �������� ��������� � ����� �������� �������
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
      // ������ �� ������ �������� �������������� �������
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
