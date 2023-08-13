{**********************************************}
{                                              }
{ ���� : ��������� ������� �����               }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Fly;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ������� �����
  TPLShipsControlFly = class(TPLShipsControlCustom)
  private const
    // ����� ����������� ����� ���������
    CI_TIME_MOVING_GLOBAL = 4;
    // ����� ����������� �� ����� �������
    CI_TIME_MOVING_LOCAL = 2;
    // ����� ������ ��������
    CI_TIME_MOVING_PARKING = 2;
  private
    // ������ ������� ���������
    function OnTimer(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean;
  public
    // ������� ����������
    procedure Execute(AShip: TPlShip; AState: TPlShipState);
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlFly.OnTimer(AShip: TPlShip; var ACounter: Integer;
  var AValue: Integer): Boolean;
begin
  Result := False;
  try
    // ������ �� ��������
    if (ACounter > 0) then
    begin
      Dec(ACounter);
      Exit();
    end else
      Result := True;
    // �������� ���� ������������ �� ������� � ����
    if (AShip.Planet.Timer[ppltmBattle])
      and (AShip.State <> pshstParking) then
    begin
      Execute(AShip, pshstParking);
      Exit();
    end;
    // �������� ������ �� ��
    if (AShip.State = pshstMovingGlobal)
      and (AShip.Planet.PlanetType = pltHole)
      and (not Assigned(AShip.Group)) then
    begin
      TPlanetarThread(Engine).ControlShips.Portal.Execute(AShip, False);
      Exit();
    end;
    // �������� ������� � �������� �����������
    TPlanetarThread(Engine).ControlShips.StandUp.Execute(AShip, True,
      (AShip.Mode <> pshmdOffline) and (AShip.Mode <> pshmdConstruction));
    // ���������� ���� �����
    if (AShip.IsAutoAttach) then
      TPlanetarThread(Engine).ControlShips.Attach.Execute(AShip, AShip.Planet, False);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlFly.Execute(AShip: TPlShip; AState: TPlShipState);
begin
  try
    // ��������� ����� ��� �������
    case AState of
      pshstParking:
      begin
        TPlanetarThread(Engine).WorkerShips.TimerAdd(AShip, pshtmOpParking,
          CI_TIME_MOVING_PARKING, OnTimer);
      end;
      pshstMovingLocal:
      begin
        TPlanetarThread(Engine).WorkerShips.TimerAdd(AShip, pshtmOpFlight,
          CI_TIME_MOVING_LOCAL, OnTimer);
      end;
      pshstMovingGlobal:
      begin
        TPlanetarThread(Engine).WorkerShips.TimerAdd(AShip, pshtmOpFlight,
          CI_TIME_MOVING_GLOBAL, OnTimer);
        TPlanetarThread(Engine).ControlShips.Fuel.Execute(AShip, -1);
      end;
      else
        TLogAccess.Write(ClassName, 'State');
    end;
    // ������ ������� ���������
    AShip.State := AState;
    TPlanetarThread(Engine).SocketWriter.ShipUpdateState(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
