{**********************************************}
{                                              }
{ Флот : поиск цели на другой планете по       }
{        маркеру наведения союзного юнита      }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.TargetMarker;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки поиска локальной цели на соседней планете
  TPLShipsControlTargetMarker = class(TPLShipsControlCustom)
  public
    // Автоматический поиск цели на соседних планетах
    procedure Auto(AShip: TPlShip);
    // Поиск подсвеченной цели
    procedure Highlight(AShip: TPlShip; APlanet: TPlPlanet; AAutoTarget: Boolean);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlTargetMarker.Auto(AShip: TPlShip);
var
  TmpPlanet: TPlPlanet;
begin
  try
    // Пропускаем уже занятые цели
    if (not AShip.CanRangeAutoTarget) then
      Exit();
    // Игнорируем планеты без боя
    for TmpPlanet in AShip.Planet.Links do
    begin
      if (not TmpPlanet.Timer[ppltmBattle]) then
        Continue;
      Highlight(AShip, TmpPlanet, True);
      // Если цель найдена - то переходим к следующему кораблику
      if (AShip.IsTargeted) then
        Break;
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlTargetMarker.Highlight(AShip: TPlShip; APlanet: TPlPlanet; AAutoTarget: Boolean);
var
  TmpShip: TPlShip;
  TmpTargetRocket: TPlShip;
begin
  try
    TmpTargetRocket := nil;
    // Проверим что нацеливаем активный ранжевый кораблик
    if (AShip.IsStateActive) then
    begin
      // Поиск корабля противника, которого подсветил наш кораблик
      for TmpShip in APlanet.Ships do
      begin
        // Пропускаем не свои корабли, выключенные корабли или девы нацеленные на другую планету
        if (not TmpShip.IsStateActive)
          or (TmpShip.IsAttachedRange(True))
          or (TmpShip.Owner.IsRoleEnemy(AShip.Owner))
        then
          Continue;
        // Нельзя стрелять по корветам на другой планете
        if (Assigned(TmpShip.Targets[pswCenter])
          and (not TmpShip.Targets[pswCenter].TechActive(plttRangeDefence)))
        then
          TmpTargetRocket := TmpShip.Targets[pswCenter]
        else
        // Ищем левую цель
        if (Assigned(TmpShip.Targets[pswLeft]))
          and (not TmpShip.Targets[pswLeft].TechActive(plttRangeDefence))
        then
          TmpTargetRocket := TmpShip.Targets[pswLeft]
        else
        // Ищем правую цель
        if (Assigned(TmpShip.Targets[pswRight]))
          and (not TmpShip.Targets[pswRight].TechActive(plttRangeDefence))
        then
          TmpTargetRocket := TmpShip.Targets[pswRight];
        // Проверим наличие цели
        if (Assigned(TmpTargetRocket)) then
          Break;
      end;
    end;
    // Проверим смены цели
    if (AShip.Targets[pswRocket] <> TmpTargetRocket) then
    begin
      // Приаттачим автонацеленный коаблик
      if (AAutoTarget) then
      begin
        if (Assigned(TmpTargetRocket)) then
          TPlanetarThread(Engine).ControlShips.Attach.Execute(AShip, APlanet, True)
        else
          TPlanetarThread(Engine).ControlShips.Attach.Execute(AShip, nil, True);
      end;
      AShip.Targets[pswRocket] := TmpTargetRocket;
      // Отправим смену цели
      TPlanetarThread(Engine).SocketWriter.ShipRetarget(AShip, pswRocket);
      // Найдем новую цель для свободного кораблика
      if (AAutoTarget) then
        Auto(AShip);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
