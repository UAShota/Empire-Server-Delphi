{**********************************************}
{                                              }
{ Модуль обработчика процесса товароведения    }
{       Copyright (c) 2016 UAShota              }
{                                              }
{**********************************************}
unit SR.Planetar.Worker.Production;

interface

uses
  System.Math,

  SR.Globals.Types,
  SR.GLobals.Dictionaries,
  SR.Planetar.Classes,
  SR.Planetar.Dictionary,
  SR.Planetar.Custom;

type
  TPlanetarWorkerProduction = class(TPlanetarCustom)
  public
    procedure CalculateProduction(APlanet: TPlPlanet);
(*    procedure Start(); reintroduce;*)
    procedure Work(); override;
  end;

implementation

uses
  SR.Planetar.Thread;

(*procedure TPlanetarWorkerProduction.Start();
var
  TmpPlanet: TPlPlanet;
begin
  for TmpPlanet in TPlanetarThread(Engine).ControlPlanets.ListPlanets do
    CalculateProduction(TmpPlanet);
end;  *)

procedure TPlanetarWorkerProduction.Work();
var
  TmpSet: Integer;
  TmpccIn: Integer;
  TmpccOut: Integer;
  TmpRc: TGlResourceType;
  FlgNR: Boolean;
  TmpPlanet: TPlPlanet;
begin
  for TmpPlanet in TPlanetarThread(Engine).ControlPlanets.ListPlanets do
  begin
    if (not TmpPlanet.HaveProduction) then
      Continue;
    FlgNR := False;

    for TmpRc := Succ(resEmpty) to High(TGlResourceType) do
    begin
      // Не хватает используемых ресурсов
      if (TmpPlanet.ResUseIn[TmpRc] > TmpPlanet.ResAvailIn[TmpRc]) then
      begin
        FlgNR := True;
        Break;
      end;
      // Нет места для выработки товара
      if (TmpPlanet.ResUseOut[TmpRc] > 0)
        and (TmpPlanet.ResUseOut[TmpRc] > TmpPlanet.ResAvailOut[TmpRc]) then
      begin
        FlgNR := True;
        Break;
      end;
    end;
    if (FlgNR) then
      Continue;

    for TmpRc := Succ(resEmpty) to High(TGlResourceType) do
    begin
      TmpccIn := TmpPlanet.ResUseIn[TmpRc];
      TmpccOut := TmpPlanet.ResUseOut[TmpRc];

      // Декремент использованных доступных ресурсов
      TmpPlanet.ResAvailIn[TmpRc] := TmpPlanet.ResAvailIn[TmpRc] - TmpPlanet.ResUseIn[TmpRc];
      // Инкремент доступных ресурсов результатом производа
      TmpPlanet.ResAvailIn[TmpRc] := TmpPlanet.ResAvailIn[TmpRc] + TmpPlanet.ResUseOut[TmpRc];
      // Декремент места для результатов производа
      TmpPlanet.ResAvailOut[TmpRc] := TmpPlanet.ResAvailOut[TmpRc] - TmpPlanet.ResUseOut[TmpRc];

      if (TmpccIn = 0)
        and (TmpccOut = 0)
      then
        Continue;

      for TmpSet in TmpPlanet.Storages.Keys do
      begin
        if (not TmpPlanet.Storages[TmpSet].Active)
          or (TmpPlanet.Storages[TmpSet].Holder.Resource <> TmpRc)
        then
          Continue;

        if (TmpccIn > 0) then
        begin
          if (TmpPlanet.Storages[TmpSet].Holder.Count >= TmpccIn) then
          begin
            TmpPlanet.Storages[TmpSet].Holder.Count := TmpPlanet.Storages[TmpSet].Holder.Count - TmpccIn;
            Break;
          end
          else
          begin
            TmpccIn := TmpccIn - TmpPlanet.Storages[TmpSet].Holder.Count;
            TmpPlanet.Storages[TmpSet].Holder.Count := 0;
          end;
        end;

(*        if (TmpccOut > 0)
          and (TmpPlanet.Storages[TmpSet].HaveProduction) then
        begin
          if (TGlDictionaries.Resources[TmpRc].Max - TmpPlanet.Storages[TmpSet].Holder.Count >= TmpccOut) then
          begin
            TmpPlanet.Storages[TmpSet].Holder.Count := TmpPlanet.Storages[TmpSet].Holder.Count + TmpccOut;
            Break;
          end else
          begin
            if (TmpPlanet.Storages[TmpSet].Holder.Count < TGlDictionaries.Resources[TmpRc].Max) then
            begin
              TmpccOut := TmpccOut - (TGlDictionaries.Resources[TmpRc].Max - TmpPlanet.Storages[TmpSet].Holder.Count);
              TmpPlanet.Storages[TmpSet].Holder.Count := TGlDictionaries.Resources[TmpRc].Max;
            end;
          end;
        end;  *)
      end;

    end;
  end;
end;

procedure TPlanetarWorkerProduction.CalculateProduction(APlanet: TPlPlanet);
var
  TmpLntrs: Integer;
  TmpSet: Integer;
  TMpQ: TGlResourceType;
  TmpPid: TGlResourceType;
  TmpBuilding: TPlBuilding;
//  n: Integer;
  TmpCount: Integer;
  TmpMax: Integer;
begin
  TmpPid := resEmpty;
  APlanet.HaveProduction := False;
  for TmpQ := Succ(resEmpty) to High(TGlResourceType) do
  begin
    APlanet.ResAvailIn[TmpQ] := 0;
    APlanet.ResAvailOut[TmpQ] := 0;
    APlanet.ResUseIn[TmpQ] := 0;
    APlanet.ResUseOut[TmpQ] := 0;
  end;

  for TmpSet in APlanet.Storages.Keys do
  begin
    if (TmpPid = resEmpty)
(*      and (APlanet.Storages[TmpSet].HaveProduction)*)
      and (APlanet.Storages[TmpSet].Active)
    then
      TmpPid := (APlanet.Storages[TmpSet].Holder.Resource);

    if (APlanet.Storages[TmpSet].Holder.Resource <> resEmpty) then
    begin
      if (APlanet.Storages[TmpSet].Active) then
      begin
        APlanet.ResAvailIn[APlanet.Storages[TmpSet].Holder.Resource] :=
          APlanet.ResAvailIn[APlanet.Storages[TmpSet].Holder.Resource] + APlanet.Storages[TmpSet].Holder.Count;
        // В хранилище ресурсов больше лимита
        TmpCount := APlanet.Storages[TmpSet].Holder.Count;
        TmpMax := TGlDictionaries.Resources[APlanet.Storages[TmpSet].Holder.Resource].Max;
        if (TmpCount >= TmpMax) then
          TmpCount := 0
        else
          TmpCount := TmpMax - TmpCount;
        // Увеличим лимит на производство
        APlanet.ResAvailOut[APlanet.Storages[TmpSet].Holder.Resource] :=
          APlanet.ResAvailOut[APlanet.Storages[TmpSet].Holder.Resource] + TmpCount;
      end;
    end;
  end;

  if (TmpPid = resEmpty) then
    Exit();

  if (TmpPid = resVodorod)
    and (APlanet.PlanetType = pltHydro) then
  begin
    if (APlanet.Services > 0) then
    begin
      APlanet.HaveProduction := True;
      (*APlanet.ResUseOut[TmpPid] := Min(MaxServiceStorageCount, APlanet.CountServices) * 14;*)
    end;
  end else
  begin
(*    for TmpLntrs in APlanet.Buildings.Keys do
    begin
      TmpBuilding := APlanet.Buildings[TmpLntrs];
      if (TmpBuilding.Level = 0) then
        Continue;

      TmpBuilding.HaveProduction := (TPlanetarDictionary.Buildings[TmpBuilding.BuildingType].ResourceOut[TmpBuilding.Mode] = TmpPid);
      if (TmpBuilding.HaveProduction) then
      begin
      (*  APlanet.HaveProduction := True;
        for n := 0 to 1 do
        begin
          APlanet.ResUseIn[TPlanetarDictionary.Buildings[TmpBuilding.BuildingType].ResourceIn[TmpBuilding.Mode, n]] :=
            APlanet.ResUseIn[TPlanetarDictionary.Buildings[TmpBuilding.BuildingType].ResourceIn[TmpBuilding.Mode][n]]
            + TPlanetarDictionary.BuildingTechList[TmpBuilding.BuildingType, ].ResInCount[TmpBuilding.Mode, n] * TmpBuilding.Level;
        end;
        APlanet.ResUseOut[TPlanetarDictionary.Buildings[TmpBuilding.BuildingType].ResourceOut[TmpBuilding.Mode]] :=
          APlanet.ResUseOut[TPlanetarDictionary.Buildings[TmpBuilding.BuildingType].ResourceOut[TmpBuilding.Mode]]
          + TPlanetarDictionary.Buildings[TmpBuilding.BuildingType].ResOutCount[TmpBuilding.Mode] * TmpBuilding.Level;
      end;
    end;    *)
  end;

end;

end.
