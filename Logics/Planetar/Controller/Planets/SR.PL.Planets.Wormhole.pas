{**********************************************}
{                                              }
{ Планетоиды : обработка черной дыры           }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{                                              }
{**********************************************}
unit SR.PL.Planets.Wormhole;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Planets.Custom;

type
  // Класс обработки боевого тика
  TPLPlanetsControlWormhole = class(TPLPlanetsControlCustom)
  private var
    FBigHolesCount: Integer;
    FSmallHolesCount: Integer;
    FWormholesActive: TPlPlanetList;
    FWormholesInactive: TPlPlanetList;
  private
    // Срабатывание таймера операции
    function OnTimer(APlanet: TPlPlanet; var ACounter: Integer; var AValue: Integer): Boolean;
    // Установка признака окраины ЧТ
    procedure DoSetHoleEdge(APlanet: TPlPlanet; AEdge: Boolean);
    // Смена состояния ЧТ
    procedure DoChangeState(APlanet: TPlPlanet);
    // Активация пары ЧТ
    procedure DoActivate(ABigHole: Boolean; var APortal: TPlPlanet);
  public
    constructor Create(AEngine: TObject); override;
    destructor Destroy(); override;
    // Базовое выполнение
    procedure Execute(APlanet: TPlPlanet);
    // Пересчт активных ЧТ в созвездии
    procedure Reactivate();
  end;

implementation

uses
  SR.Planetar.Thread;

constructor TPLPlanetsControlWormhole.Create(AEngine: TObject);
begin
  inherited Create(AEngine);

  FWormholesActive := TPlPlanetList.Create();
  FWormholesInactive := TPlPlanetList.Create();
end;

destructor TPLPlanetsControlWormhole.Destroy();
begin
  FreeAndNil(FWormholesInactive);
  FreeAndNil(FWormholesActive);

  inherited Destroy();
end;

function TPLPlanetsControlWormhole.OnTimer(APlanet: TPlPlanet; var ACounter, AValue: Integer): Boolean;
begin
  Result := False;
  try
    // Таймер не закончился
    if (ACounter > 0) then
    begin
      Dec(ACounter);
      Exit();
    end;
    // Сменим состояние обеим планетам
    DoChangeState(APlanet.Portal.Enter);
    DoChangeState(APlanet.Portal.Exit);
    // Обновим время для активируемой ЧТ
    if (APlanet.State = plsActivation) then
    begin
      ACounter := APlanet.StateTime;
      AValue := ACounter;
      Exit();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLPlanetsControlWormhole.DoChangeState(APlanet: TPlPlanet);
begin
  // Выключим активную ЧТ или включим активирующуюся
  if (APlanet.State = plsActive) then
  begin
    // Для БЧТ уберем видимость на ней и соседних планетах
    if (APlanet.IsBigHole) then
    begin
      DoSetHoleEdge(APlanet, False);
      APlanet.IsBigHole := False;
      Dec(FBigHolesCount);
    end else
      Dec(FSmallHolesCount);
    FWormholesInactive.Add(APlanet);
    // Выключаем статус
    APlanet.State := plsInactive;
    // Закроем портал
    TPlanetarThread(Engine).ControlPlanets.ClosePortal(APlanet);
    // Раскидаем корабли с орбиты
    TPlanetarThread(Engine).ControlShips.Escape.Execute(APlanet);
  end else
  begin
    APlanet.State := plsActive;
    APlanet.StateTime := TPlanetarThread(Engine).TimeWormholeActive;
  end;
  // Отправим сообщение о смене состояния
  TPlanetarThread(Engine).SocketWriter.PlanetStateUpdate(APlanet);
end;

procedure TPLPlanetsControlWormhole.DoSetHoleEdge(APlanet: TPlPlanet; AEdge: Boolean);
var
  TmpPlanet: TPlPlanet;
begin
  for TmpPlanet in APlanet.Links do
  begin
    if (TmpPlanet.PlanetType <> pltHole) then
      TmpPlanet.IsBigEdge := AEdge;
  end;
end;

procedure TPLPlanetsControlWormhole.DoActivate(ABigHole: Boolean; var APortal: TPlPlanet);
var
  TmpI: Integer;
  TmpPlanet: TPlPlanet;
begin
  TmpI := Random(Pred(FWormholesInactive.Count));
  TmpPlanet := FWormholesInactive[TmpI];
  FWormholesInactive.Delete(TmpI);
  // Настроим БЧТ
  TmpPlanet.IsBigHole := True;
  TmpPlanet.State := plsActivation;
  TmpPlanet.StateTime := TPlanetarThread(Engine).TimeWormholeOpen;
  TPlanetarThread(Engine).WorkerPlanets.TimerAdd(TmpPlanet, ppltmWormhole, TmpPlanet.StateTime, OnTimer);
  // Установим портал
  if (Assigned(APortal)) then
  begin
    TPlanetarThread(Engine).ControlPlanets.OpenPortal(TmpPlanet, APortal, False, True);
    APortal := nil;
  end else
    APortal := TmpPlanet;
  // Добавим ЧТ в обработку
  if (ABigHole) then
  begin
    Inc(FBigHolesCount);
    DoSetHoleEdge(TmpPlanet, True);
  end else
    Inc(FSmallHolesCount);
  // Отправим сообщение о смене состояния
  TPlanetarThread(Engine).SocketWriter.PlanetStateUpdate(TmpPlanet);
end;

procedure TPLPlanetsControlWormhole.Reactivate();
var
  TmpPortalPlanet: TPlPlanet;
begin
  // Проверим что нужно включить какую-либо БЧТ
  TmpPortalPlanet := nil;
  while (FBigHolesCount < 2) do
    DoActivate(True, TmpPortalPlanet);
  // Проверим что нужно включить ЧТ, по паре на каждые 50 планет
  TmpPortalPlanet := nil;
  while (FSmallHolesCount - 2 < Trunc(TPlanetarThread(Engine).MannedCount / 50) * 2) do
    DoActivate(False, TmpPortalPlanet);
end;

procedure TPLPlanetsControlWormhole.Execute(APlanet: TPlPlanet);
begin
  FWormholesActive.Add(APlanet);
  FWormholesInactive.Add(APlanet);
end;

end.
