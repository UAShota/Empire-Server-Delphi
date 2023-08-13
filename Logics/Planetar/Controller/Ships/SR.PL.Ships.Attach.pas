{**********************************************}
{                                              }
{ ���� : ������������ � �������                }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev A  2017.12.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Attach;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // ����� ��������� ������������ � �������
  TPLShipsControlAttach = class(TPLShipsControlCustom)
  public
    // ������� ����������
    procedure Execute(AShip: TPlShip; ADestination: TPlPlanet; AIsAutoTarget: Boolean);
    // ���������� ������� ������
    procedure Player(AShip: TPlShip; ADestination: TPlPlanet; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlAttach.Execute(AShip: TPlShip; ADestination: TPlPlanet; AIsAutoTarget: Boolean);
begin
  try
    // ������ �������� �� ������ ����������
    if (AShip.IsAttachedRange(False)) then
      AShip.Attached.RangeAttackers.Remove(AShip)
    else
    // ������� ������
    if (Assigned(AShip.Attached)) then
      TPlanetarThread(Engine).ControlShips.Capture.Execute(AShip, False);
    // �������� ��������� � ����� ������
    AShip.IsAutoTarget := (AIsAutoTarget) and Assigned(ADestination);
    AShip.Attached := ADestination;
    TPlanetarThread(Engine).SocketWriter.ShipChangeAttach(AShip);
    // ���� ����������� �� � ������� �������
    if (not Assigned(ADestination))
      or (ADestination = AShip.Planet) then
    begin
      if (AIsAutoTarget) then
        Exit();
      // ��� �������� ��������� ���������� ������� ����� ������� � ����������
      if (AShip.TechActive(plttWeaponRocket)) then
      begin
        // ���� ��� ���, �� �������� ����������
        if (not AShip.Planet.Timer[ppltmBattle]) then
          TPlanetarThread(Engine).ControlShips.TargetMarker.Auto(AShip)
        else
        if (AShip.IsTargeted) then
          TPlanetarThread(Engine).ControlShips.TargetLocal.Execute(AShip);
      end else
      // ������� ������ ��� ���������
      if (AShip.TechActive(plttCapturer))
        and (Assigned(AShip.Attached))
      then
        TPlanetarThread(Engine).ControlShips.Capture.Execute(AShip, True);
      Exit();
    end;
    // ������� � ������� ������� �������
    AShip.Attached.RangeAttackers.Add(AShip);
    if (AIsAutoTarget) then
      Exit();
    // � ������������ ������� ������������ ����
    if (AShip.TechActive(plttWeaponRocket)) then
      TPlanetarThread(Engine).ControlShips.TargetMarker.Highlight(AShip, AShip.Attached, False)
    else
    // � �������� ��� ����� ������������ ����� ����� �����������
    if (AShip.TechActive(plttCapturer))
      and (AShip.Attached.IsManned)
      and (not TPlanetarThread(Engine).ControlShips.MoveToPlanet.Execute(AShip, AShip.Attached, 0, True, True))
    then
      TLogAccess.Write(ClassName, 'InvaderSlot');
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlAttach.Player(AShip: TPlShip; ADestination: TPlPlanet; APlayer: TGlPlayer);
begin
  try
    // ������ ��������� �������������
    if (not AShip.CanOperable) then
    begin
      TLogAccess.Write(ClassName, 'Operable');
      Exit();
    end;
    // ������ �������� ��������� �� �� �� �������
    if ((AShip.Attached = ADestination) and (not AShip.IsAutoTarget)) then
    begin
      TLogAccess.Write(ClassName, 'Reattach');
      Exit();
    end;
    // ������ ��������� ������
    if (not AShip.Owner.IsRoleFriend(APlayer)) then
    begin
      TLogAccess.Write(ClassName, 'Role');
      Exit();
    end;
    // �������� ���� ���������
    if (Assigned(ADestination)) then
    begin
      if (AShip.TechActive(plttCapturer)) then
      begin
        // ������ ����������� ������������� ����������
        if (ADestination.Owner.IsRoleFriend(AShip.Owner)) then
        begin
          TLogAccess.Write(ClassName, 'Captured');
          Exit();
        end;
        // ������ ���������� � ������� ��������
        if (not ADestination.IsManned) then
        begin
          TLogAccess.Write(ClassName, 'Manned');
          Exit();
        end;
      end;
      // �������� �� ������������ � ������ �������
      if (AShip.Planet <> ADestination) then
      begin
        // ������������ �� ��������� �� ������ �������
        if (AShip.TechActive(plttStationary)) then
        begin
          TLogAccess.Write(ClassName, 'Stationary');
          Exit();
        end;
        // ������ ���������� �� ������� ��� ������� ��������
        if (not AShip.Planet.Links.Contains(ADestination)) then
        begin
          TLogAccess.Write(ClassName, 'Links');
          Exit();
        end;
      end;
      // �������� �� ����� � ��
      if (ADestination.PlanetType = pltHole) then
      begin
        // ������ ���������� � ���������� ��
        if (ADestination.State <> plsActive) then
        begin
          TLogAccess.Write(ClassName, 'HoleInactive');
          Exit();
        end;
        // ������� ����������� ������ �� ��������� ��
        if (not TPlanetarThread(Engine).ControlShips.MoveToPlanet.Execute(AShip, ADestination)) then
          TLogAccess.Write(ClassName, 'HoleCantMove');
        Exit();
      end;
    end;
    // ���������� ��������
    Execute(AShip, ADestination, False);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
