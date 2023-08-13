{**********************************************}
{                                              }
{ Модуль обработчика процесса грузоперевозок   }
{       Copyright (c) 2016 UAShota              }
{                                              }
{**********************************************}
unit SR.Planetar.Worker.Transport;

interface

uses
  System.DateUtils,
  System.SysUtils,

  SR.Globals.Types,
  SR.Planetar.Classes,
  SR.Planetar.Socket.Writer,
  SR.Planetar.Controller.Ships,
  SR.Planetar.Controller.Storage,
  SR.Planetar.Custom;

type
  TPlanetarWorkerTransport = class(TPlanetarCustom)
  public
    procedure Work(); override;
  end;
(*
  private var
    FLoaded: Boolean;
  private
    procedure Train(Start: TPlPlanet; Desination: TPlPlanet; var CC: TResListData; First: Boolean);
    function CheckReturnFromForward(AShip: TPlShip): Boolean;
    function CheckReturnFromBack(AShip: TPlShip; ACurrentPlanet: TPlPlanet): Boolean;
    function CheckGotoForward(AShip: TPlShip): Boolean;
    function CheckGotoBack(AShip: TPlShip): Boolean;
  public
    procedure Start(); reintroduce;

  end;   *)

implementation

uses
  SR.Planetar.Thread;

(*TPlanetarWorkerTransport.Start();
begin
  Work(False);
end;

procedure TPlanetarWorkerTransport.Work(ALoaded: Boolean = True);
var
  TmpR: Integer;
  CC:  TResListData;
  TmpPath: TPlTransportPath;
begin
  for TmpPath in TPlanetarThread(FEngine).ListTransportPaths do
  begin
    FillChar(cc, sizeof(cc), 0);
    for TmpR := 0 to Pred(TmpPath.Points.Count) do
      Train(TmpPath.Points[TmpR], TmpPath.Points[TmpR], cc, not FLoaded);
  end;
  FLoaded := True;
end;

function TPlanetarWorkerTransport.CheckReturnFromForward(AShip: TPlShip): Boolean;
begin
//  Result := (AShip.Planet <> AShip.TargetPlanet);
  Result := True;
end;

function TPlanetarWorkerTransport.CheckReturnFromBack(AShip: TPlShip; ACurrentPlanet: TPlPlanet): Boolean;
begin
//  Result := (AShip.TargetPlanet.ResPathOut = AShip.Planet);
  Result := True;
end;

function TPlanetarWorkerTransport.CheckGotoBack(AShip: TPlShip): Boolean;
(*var
  TmpI: Integer;
  TmpInPlanet: TPLanet;
  TmTPLanet: TPlanet;
  TmpRes: TGlobalResourceType;
  TmpShip: TMapShip;
  TmpSlot: Integer;
begin
  Result := False;

//  TmpShip := AShip;

//  TmTPLanet := AShip.Planet;
//  if (TmTPLanet.ResPathIn.Count <= 0) then
 //   Exit();


(*  for TmpI := AShip.Planet.LastTransportPlanet to Pred(AShip.Planet.ResPathIn.Count) do
  begin
    TmpInPlanet := AShip.Planet.ResPathIn[TmpI];
    if not TPlanetarThread(FEngine).ControlWarships.CanMoveTo(TmpShip.Owner, TmpInPlanet, TmpShip, TmpSlot, True) then
      Continue;

    for TmpRes := AShip.Planet.LastResIn to Pred(TGlobalResourceType.prtEmpty) do
    begin
      // Ресурсы нужны и ресурсов сейчас в N раз больше чем требуется на производство
      if (TmpInPlanet.ResTravel[TmpRes] > 0)
        and (TmpInPlanet.ResAvailIn[TmpRes] > TmpInPlanet.ResUseIn[TmpRes] * ProductMultiplier) then
      begin
        // Загрузим кораблик ресурсом за который он едет
        TmpShip.Resource := TmpRes;
        TmpShip.Count := 0;
        TPlanetarThread(FEngine).SocketWriter.ShipUpdateResources(TmpShip);
        // И отправим
//        TPlanetarEngine(FEngine).ControlWarships.MoveTo(AShip.Owner.UID, TmpInPlanet, AShip, TmpSlot, False);
        Exit(True);
      end;
    end;
  end;*)

(*  if (not Result)
    and (AShip.Planet.LastResIn > 0) then
  begin
    AShip.Planet.LastResIn := 0;
    CheckGotoBack(AShip);
  end;
end;

function TPlanetarWorkerTransport.CheckGotoForward(AShip: TPlShip): Boolean;
(*var
  TmpOutPlanet: TPLanet;
  TmTPLanet: TPlanet;
  TmpRes: TGlobalResourceType;
  TmpShip: TMapShip;
  TmpSlot: Integer;
begin
  Result := False;

//  TmpShip := AShip;

//  TmTPLanet := AShip.Planet;
//  if (TmTPLanet.ResPathOut = nil) then
//    Exit();

(*  TmpOutPlanet := TmTPLanet.ResPathOut;
  if not TPlanetarThread(FEngine).ControlWarships.CanMoveTo(TmpShip.Owner, TmpOutPlanet, TmpShip, TmpSlot, True) then
    Exit();

  for TmpRes := TmTPLanet.LastResOut to Pred(TGlobalResourceType.prtEmpty) do
  begin
    // Ресурсы нужны и ресурсов сейчас в N раз больше чем требуется на производство
    if (TmpOutPlanet.ResTravel[TmpRes] > 0)
      and TPlanetarThread(FEngine).ControlStorages.LoadResToShip(TmpRes, TmpShip) then
    begin
      // Направить на новую планету
//      TPlanetarEngine(FEngine).ControlWarships.MoveTo(AShip.Owner.UID, TmpOutPlanet, AShip, TmpSlot, False);
      Exit(True);
    end;
  end;*)

(*  if (not Result)
    and (TmTPLanet.LastResOut > 0) then
  begin
    TmTPLanet.LastResOut := 0;
    CheckGotoForward(AShip);
  end;
end;

procedure TPlanetarWorkerTransport.Train(Start: TPlPlanet; Desination: TPlPlanet; var CC: TResListData; First: Boolean);
(*var
  TmpI: TGlobalResourceType;
  Plnt: TPlanet;
  TmpShip: TMapShip;
  TmpSlot: Integer;
begin
(*  Plnt := Desination;

  for TmpI := Low(TGlobalResourceType) to Pred(TGlobalResourceType.prtEmpty) do
  begin
    CC[TmpI] := CC[TmpI] + Plnt.ResUseIn[TmpI];
    Plnt.ResTravel[TmpI] := CC[TmpI];
  end;

  if not First then
  begin
    for TmpShip in Plnt.ListTransport do
    begin
      if (not Assigned(TmpShip.AttachedPlanet)) then
        Continue;

      if (TmpShip.FlyState <> pshstIddle) then
        Continue;

      if (TmpShip.ResCount > 0)
        and TPlanetarThread(FEngine).ControlStorages.LoadResToPlanet(TmpShip) then
      begin
//        TmpShip.SetState(pshstPenalty);
        Continue;
      end;

      // Если мы улетели назад, то нужно вернуться с товаром
(*      if (CheckReturnFromBack(TmpShip, Plnt)) then
      begin
        if not TPlanetarThread(FEngine).ControlWarships.CanMoveTo(TmpShip.Owner, TmpShip.Planet, TmpShip, TmpSlot, True) then
          Continue;
        TPlanetarThread(FEngine).ControlStorages.LoadResToShip(TmpShip.Resource, TmpShip);
//        TPlanetarEngine(FEngine).ControlWarships.MoveTo(TmpShip.Owner, TmpShip.Planet, TmpShip, TmpSlot, False);
        Continue;
      end else
      // Если мы улетели вперед, то нужно вернуться без товара
      if (CheckReturnFromForward(TmpShip)) then
      begin
        if not TPlanetarThread(FEngine).ControlWarships.CanMoveTo(TmpShip.Owner, TmpShip.Planet, TmpShip, TmpSlot, True) then
          Continue;
//        TPlanetarEngine(FEngine).ControlWarships.MoveTo(TmpShip.Owner, TmpShip.Planet, TmpShip, TmpSlot, False);
        Continue;
      end;

      // Если стоим на планете
      if (not TmpShip.Backward) then
      begin
        if (not CheckGotoBack(TmpShip)) then
          CheckGotoForward(TmpShip)
        else
          TmpShip.Backward := (not TmpShip.Backward)
      end else
      begin
        if (not CheckGotoForward(TmpShip)) then
          CheckGotoBack(TmpShip)
        else
          TmpShip.Backward := (not TmpShip.Backward);
      end;

    end;
  end;

  (*
  for TmpI := 0 to Pred(Plnt.ResPathIn.Count) do
  begin
    if (Plnt.ResPathIn[TmpI] <> Start) then
      Train(Start, Plnt.ResPathIn[TmpI], CC, First);
  end;
end;  *){ TODO : sdf }

{ TPlanetarWorkerTransport }

procedure TPlanetarWorkerTransport.Work();
begin

end;

end.
