{**********************************************}
{                                              }
{ ���� : �������� ��������                     }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Fuel;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� �������� ��������
  TPLShipsControlFuel = class(TPLShipsControlCustom)
  private
    // ������ ������� ���������� ������� �������
    function OnTimer(AShip: TPlShip; var ACounter: Integer; var AValue: Integer): Boolean;
    // ����������� ������� ��������� ������� �������
    function GetChargeTime(): Integer;
    // ������� ������� ����
    function GetIsFull(AShip: TPlShip): Boolean;
  public
    // ������� ����������
    function Execute(AShip: TPlShip; ACount: Integer): Integer;
  end;

implementation

uses
  SR.Planetar.Thread;

function TPLShipsControlFuel.OnTimer(AShip: TPlShip; var ACounter: Integer;
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
    // ���������
    Execute(AShip, 1);
    // ���� �� ������ - ���������� ������
    if (not GetIsFull(AShip)) then
    begin
      ACounter := GetChargeTime();
      AValue := ACounter;
    end;
    // �������� ��������� � ����� �������
    Result := True;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlFuel.GetChargeTime(): Integer;
begin
  Result := 0;
  try
    Result := 30;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlFuel.GetIsFull(AShip: TPlShip): Boolean;
begin
  Result := True;
  try
    Result := (AShip.Fuel >= I_MAX_FUEL_COUNT);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TPLShipsControlFuel.Execute(AShip: TPlShip; ACount: Integer): Integer;
begin
  Result := 0;
  try
    if (ACount = 0) then
    begin
      TLogAccess.Write(ClassName, 'NoCount');
      Exit();
    end;
    // �������� ������
    if (ACount < 0) then
    begin
      // �������� � ��� ������
      if (AShip.Fuel = 0) then
      begin
        TLogAccess.Write(ClassName, 'NoFuel');
        Exit();
      end;
      // ������� ����� �����
      Result := Max(-AShip.Fuel, ACount);
      // ������� ������ ����������
      TPlanetarThread(Engine).WorkerShips.TimerAdd(AShip, pshtmOpRefill, GetChargeTime(), OnTimer);
    end else
    // ���������� ������
    begin
      // �������� ��������� ��� �������
      if (GetIsFull(AShip)) then
      begin
        TLogAccess.Write(ClassName, 'IsFull');
        Exit();
      end;
      // ������� ����� ���������
      Result := I_MAX_FUEL_COUNT - AShip.Fuel;
      // ������� ����� ���������
      Result := Min(Result, ACount);
    end;
    // ������
    Inc(AShip.Fuel, Result);
    // �������� ���������
    TPlanetarThread(Engine).SocketWriter.ShipRefill(AShip);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
