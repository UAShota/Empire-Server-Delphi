{**********************************************}
{                                              }
{ ���� : ����������� ������                    }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Merge;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ����������� ������
  TPLShipsControlMerge = class(TPLShipsControlCustom)
  public
    // ������� ����������
    procedure Execute(ASource, ADestination: TPlShip; ACount: Integer);
    // ���������� ������� ������
    procedure Player(ASource, ADestination: TPlShip; ACount: Integer; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlMerge.Execute(ASource, ADestination: TPlShip; ACount: Integer);
var
  TmpMerge: Integer;
begin
  try
    // ���� ���������� �� ������� ��� ��������� - ������������ ���� ����
    if (ACount <= 0) or (ACount > ASource.Count) then
      ACount := ASource.Count;
    // ��������� ���� ���������
    TmpMerge := Min(ACount + ADestination.Count, ASource.TechValue(plttCount));
    // �������� ��� ���� ��� ������������
    if (TmpMerge = ADestination.Count) then
    begin
      TLogAccess.Write(ClassName, 'Count');
      Exit();
    end;
    // ��������� ����������
    Dec(ASource.Count, TmpMerge - ADestination.Count);
    ADestination.Count := TmpMerge;
    // ��������� ��
    TmpMerge := Min(ASource.HP + ADestination.HP, ASource.TechValue(plttHp));
    Dec(ASource.HP, TmpMerge - ADestination.HP);
    ADestination.HP := TmpMerge;
    // � ���� � ��������� �������� ������ ��� - ������� ������
    if (ASource.Count = 0) then
      TPlanetarThread(Engine).ControlShips.RemoveFromPlanet.Execute(ASource, True, False, False)
    else
      TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(ASource);
    // ��������� ���������
    TPlanetarThread(Engine).SocketWriter.ShipUpdateHP(ADestination);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlMerge.Player(ASource, ADestination: TPlShip; ACount: Integer; APlayer: TGlPlayer);
begin
  try
    // ������������ ������� ������ ���� ����� ����, ����� ������ ��������� � ���� �� ������ ������
    if (ASource.ShipType <> ADestination.ShipType) then
    begin
      TLogAccess.Write(ClassName, 'ShipType');
      Exit();
    end;
    // ������ ���������� �������� ��� � �����
    if (ASource = ADestination) then
    begin
      TLogAccess.Write(ClassName, 'Destination');
      Exit();
    end;
    // ������ ���������� ���� ������ ����������
    if (ASource.Owner <> ADestination.Owner) then
    begin
      TLogAccess.Write(ClassName, 'Owner');
      Exit();
    end;
    // ������ ���������� �� ������ ��������
    if (ASource.Planet <> ADestination.Planet) then
    begin
      TLogAccess.Write(ClassName, 'Range');
      Exit();
    end;
    // �������� �������� �� � �������
    if (not ASource.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'SourceState');
      Exit();
    end;
    // �������� �������� �� � �������
    if (not ADestination.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'DestinationState');
      Exit();
    end;
    // ����� �������� �����������
    Execute(ASource, ADestination, ACount);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
