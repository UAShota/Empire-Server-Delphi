{**********************************************}
{                                              }
{ Планетоиды : обработка пульсара              }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{                                              }
{**********************************************}
unit SR.PL.Planets.Pulsar;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Planets.Custom;

type
  // Класс обработки боевого тика
  TPLPlanetsControlPulsar = class(TPLPlanetsControlCustom)
  private
    // Срабатывание таймера операции
    function OnTimer(APlanet: TPlPlanet; var ACounter: Integer; var AValue: Integer): Boolean;
  public
    // Базовое выполнение
    procedure Execute(APlanet: TPlPlanet);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLPlanetsControlPulsar.OnTimer(APlanet: TPlPlanet; var ACounter, AValue: Integer): Boolean;
begin
  Result := False;
  try
    // Таймер не закончен
    Result := (ACounter = 0);
    if (not Result) then    
    begin
      Dec(ACounter);
      Exit(False);
    end;
    // Сменим состояние
    if (APlanet.State = plsActive) then
      APlanet.State := plsInactive
    else
      APlanet.State := plsActive;
    TPlanetarThread(Engine).SocketWriter.PlanetStateUpdate(APlanet);
    // Сделаем новый таймер
    ACounter := TPlanetarThread(Engine).TimePulsarActive;
    AValue := ACounter;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLPlanetsControlPulsar.Execute(APlanet: TPlPlanet);
begin
  TPlanetarThread(Engine).WorkerPlanets.TimerAdd(APlanet, ppltmBattle, APlanet.StateTime, OnTimer);
end;

end.
