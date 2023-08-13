unit SR.Planetar.Hangar;

interface

uses
  SR.Globals.Player,
  SR.Planetar.Classes;

type
  // Слот ангара
  PPlHangarSlot = ^TPlHangarSlot;
  TPlHangarSlot = record
    // Тип корабля
    ShipType: TPlShipType;
    // Количество кораблей
    Count: Integer;
  end;

  // Планетарный ангар
  TPlHangar = class
  public const
    // Максимальный размер ангара
    I_MAX_HANGAR_SIZE = 6;
  private type
    THangarSlots = array[0..I_MAX_HANGAR_SIZE] of TPlHangarSlot;
  public
    // Сам ангар
    Slots: THangarSlots;
    // Размер ангара
    Size: Integer;
  public
    function Add(AIndex, ACount: Integer; AShipType: TPlShipType; APlayer: TGlPlayer = nil): Boolean;
    function Change(AIndex, ACount: Integer; APlayer: TGlPlayer = nil): Boolean;
    procedure Swap(ASlotFrom, ASlotTo: Integer; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Profile,
  SR.Planetar.Thread;

function TPlHangar.Add(AIndex, ACount: Integer; AShipType: TPlShipType; APlayer: TGlPlayer): Boolean;
var
  TmpSlot: PPlHangarSlot;
begin
  TmpSlot := @Slots[AIndex];
  TmpSlot.ShipType := AShipType;
  TmpSlot.Count := TmpSlot.Count + ACount;
  Result := True;

  if (Assigned(APlayer)) then
  begin
    TPlanetarThread(TPlanetarProfile(APlayer.PlanetarProfile).Subscribed).SocketWriter.PlayerHangarUpdate(
      AIndex, TmpSlot.Count, TmpSlot.ShipType, APlayer);
  end;
end;

function TPlHangar.Change(AIndex, ACount: Integer; APlayer: TGlPlayer = nil): Boolean;
var
  TmpSlot: PPlHangarSlot;
begin
  TmpSlot := @Slots[AIndex];
  TmpSlot.Count := TmpSlot.Count + ACount;
  Result := True;

  if (Assigned(APlayer)) then
  begin
    TPlanetarThread(TPlanetarProfile(APlayer.PlanetarProfile).Subscribed).SocketWriter.PlayerHangarUpdate(
      AIndex, TmpSlot.Count, TmpSlot.ShipType, APlayer);
  end;
end;

procedure TPlHangar.Swap(ASlotFrom, ASlotTo: Integer; APlayer: TGlPlayer);
var
  TmpSlot: TPlHangarSlot;
begin
  TmpSlot := Slots[ASlotFrom];
  Slots[ASlotFrom] := Slots[ASlotTo];
  Slots[ASlotTo] := TmpSlot;

  TPlanetarThread(TPlanetarProfile(APlayer.PlanetarProfile).Subscribed).SocketWriter.PlayerHangarUpdate(
    ASlotFrom, Slots[ASlotFrom].Count, Slots[ASlotFrom].ShipType, APlayer);

  TPlanetarThread(TPlanetarProfile(APlayer.PlanetarProfile).Subscribed).SocketWriter.PlayerHangarUpdate(
    ASlotTo, Slots[ASlotTo].Count, Slots[ASlotTo].ShipType, APlayer);
end;

end.
