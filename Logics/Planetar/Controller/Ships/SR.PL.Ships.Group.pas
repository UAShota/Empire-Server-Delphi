{**********************************************}
{                                              }
{ Флот : обработка группы юнитов               }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.PL.Ships.Group;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes,
  SR.PL.Ships.Custom;

type
  // Класс обработки группы юнитов
  TPLShipsControlGroup = class(TPLShipsControlCustom)
  public
    // Создание группы флота
    procedure Allocate(APlanetList: TPlPlanetList; AShipList: TPlShipList);
    // Перелет группы флота
    procedure Move(AShipGroup: TPlShipGroup);
    // Выполнение команды игрока
    procedure Player(APlanetList: TPlPlanetList; AShipList: TPlShipList; APlayer: TGlPlayer);
  end;

implementation

uses
  SR.Planetar.Thread;

procedure TPLShipsControlGroup.Allocate(APlanetList: TPlPlanetList; AShipList: TPlShipList);
var
  TmpGroup: TPlShipGroup;
  TmpShip: TPlShip;
  TmpBorder: Integer;
  TmpSlot: TPlLanding;
  TmpLimit: Boolean;
begin
  try
    TmpGroup := TPlShipGroup.Create(APlanetList, AShipList);
    TmpLimit := False;
    // Загрузим с массива
    for TmpShip in AShipList do
    begin
      // Сопоставим с массивом слотов, так как могут быть выбраны корабли с разных планет
      (**)
      TmpBorder := TmpShip.Landing;
      TmpSlot := TmpShip.Landing;
      while (TmpGroup.Slots[TmpSlot] <> nil) do
      begin
        TmpSlot.Inc();
        if (TmpSlot = TmpBorder) then
        begin
          TmpLimit := True;
          Break;
        end;
      end;
      if (not TmpLimit) then
      begin
        TmpGroup.Slots[TmpSlot] := TmpShip;
        TmpGroup.Position := TmpSlot;
      end else
        Break;
    end;
    // Сортируем если корабликов больше 1
    if (AShipList.Count > 1) then
      TmpGroup.DoSortBySlot();
    // Добавим группу для полета
    TPlanetarThread(Engine).WorkerShips.GroupAdd(TmpGroup);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlGroup.Move(AShipGroup: TPlShipGroup);
var
  TmpI: Integer;
  TmpShip: TPlShip;
  TmpPlanet: TPlPlanet;
  TmpPlanetLine: PPlShipRowsLine;
  TmpIndex: Byte;
  TmpStart: Integer;
  TmpCount: Byte;
  TmpBorder: Byte;
  TmpSlot: TPlLanding;
  TmpMax: Byte;
  TmpCenter: Byte;
  TmpLeft: Integer;
  TmpRight: Integer;
  TmpCenterSlot: Integer;
  TmpLeftSlot: Integer;
  TmpRightSlot: Integer;
  TmpPlanetRows: TPLShipRows;
  TmpPlanetRow: TIntegerList;
begin
  try
    // Обнулим стартовые значения проверки группы
    TmpPlanetRows := TPLShipRows.Create();
    TmpPlanetRow := TIntegerList.Create();
    FillChar(TmpPlanetRows.Lines, SizeOf(TmpPlanetRows.Lines) + SizeOf(TmpPlanetRows.Count), #0);
    // Проверка ожидания других корабликов
    for TmpStart := Pred(AShipGroup.Ships.Count) downto 0 do
    begin
      TmpShip := AShipGroup.Ships[TmpStart];
      TmpPlanetLine := nil;
      // Выбросим корабли, для которых следующая планета недоступна по расстоянию
      if (not AShipGroup.Planets[TmpShip.GroupHope].Links.Contains(TmpShip.Planet)) then
      begin
        TmpShip.Group := nil;
        AShipGroup.Ships.Delete(TmpStart);
        Continue;
      end;
      // Найдем строчку кораблей, отправляющихся с одной планеты
      for TmpI := Low(TmpPlanetRows.Lines) to Pred(TmpPlanetRows.Count) do
      begin
        if (TmpPlanetRows.Lines[TmpI].Source = TmpShip.Planet) then
          TmpPlanetLine := @TmpPlanetRows.Lines[TmpI];
      end;
      // Если строчка не найдена, добавим новую
      if (not Assigned(TmpPlanetLine)) then
      begin
        TmpPlanetLine := @TmpPlanetRows.Lines[TmpPlanetRows.Count];
        TmpPlanetLine.Source := TmpShip.Planet;
        TmpPlanetLine.Destination := AShipGroup.Planets[TmpShip.GroupHope];
        Inc(TmpPlanetRows.Count);
      end;
      // Установим разрешение на вылет для линии кораблей
      if (TmpShip.State <> pshstIddle) then
        TmpPlanetLine.FlyState := pshstMovingGlobal
      else
        if (TmpPlanetLine.FlyState <> pshstMovingGlobal) then
          TmpPlanetLine.FlyState := pshstIddle;
      // Добавим сам кораблик в линию
      TmpPlanetLine.Ships[TmpPlanetLine.Count] := TmpShip;
      TmpPlanetLine.Count := TmpPlanetLine.Count + 1;
    end;

    // Начнем обработку всех линий
    for TmpI := 0 to Pred(TmpPlanetRows.Count) do
    begin
      TmpPlanetLine := @TmpPlanetRows.Lines[TmpI];
      TmpPlanet := TmpPlanetLine.Destination;
      // Пропустим забитую планету или линию с ожиданием долета корабликов
      if (TmpPlanetLine.FlyState <> pshstIddle) then
        Continue;
      // Далее будем искать точку, на основе которой начнем высадку корабликов
      TmpCount := 0;
      TmpMax := 0;
      TmpCenter := 0;
      TmpBorder := 0;
      // Найдем первый кораблик на верхней орбите
      for TmpShip in TmpPlanet.Ships do
      begin
        if (not TmpShip.Landing.IsLowOrbit) then
        begin
          TmpBorder := TmpShip.Landing;
          Break;
        end;
      end;
      // Ищем максимальное количество непрерывающихся слотов на верхней орбите
      if (TmpBorder > 0) then
      begin
        TmpSlot := TmpBorder;
        while (TmpSlot.Inc() <> TmpBorder) do
        begin
          if (not TmpPlanet.Landings.IsEmpty(TmpSlot)) then
          begin
            if (TmpCount = 0) then
              Continue;
            TmpPlanetRow.Add((TmpCount shl 8 or TPlLanding.Offset(TmpSlot - TmpCount)) shl 8);
            if (TmpCount > TmpMax) then
            begin
              TmpMax := TmpCount;
              TmpCenter := Pred(TmpPlanetRow.Count);
            end;
            TmpCount := 0;
          end else
            Inc(TmpCount);
        end;
        if (TmpCount > 0) then
          TmpPlanetRow.Add((TmpCount shl 8 or TPlLanding.Offset(TmpSlot - TmpCount)) shl 8);
      end else
      begin
        TmpMax := TPlLandings.I_FIGHT_COUNT;
        TmpPlanetRow.Add(TmpMax shl 8 or 1 shl 8);
      end;

      // Разрешим отталкиваться от центра
      TmpBorder := TmpCenter;
      TmpCenterSlot := TmpPlanetRow[TmpCenter];
      TmpPlanetRow[TmpCenter] := TmpCenterSlot or 1;
      TmpCenterSlot := TmpCenterSlot and $00FF00 shr 8;
      // Найдем крайние точки от центра распределения
      TmpLeft := TmpCenter - 1;
      TmpRight := TmpCenter + 1;

      // Добавим еще слоты, если не хватает на полную пачку
      while (TmpMax < TmpPlanetLine.Count) do
      begin
        // Найдем слоты левее
        if (TmpLeft < 0) then
          TmpLeft := Pred(TmpPlanetRow.Count);
        if (TmpLeft <> TmpBorder) then
          TmpLeftSlot := (TmpPlanetRow[TmpLeft] and $00FF00 shr 8)
        else
          TmpLeftSlot := 0;
        // Найдем слоты правее
        if (TmpRight = TmpPlanetRow.Count) then
          TmpRight := 0;
        if (TmpRight <> TmpBorder) then
          TmpRightSlot := (TmpPlanetRow[TmpRight] and $00FF00 shr 8)
        else
          TmpRightSlot := 0;
        // Если слотов нет - выходим
        if (TmpLeftSlot = 0) and (TmpRightSlot = 0) then
          Break;

        // Сместим точку центра по минимальному элементу
        if ((TmpLeftSlot <> 0) and
          ((TmpRightSlot = 0) or (TPlLanding.Offset(TmpCenterSlot - TmpLeftSlot) < TPlLanding.Offset(TmpRightSlot - (TmpCenterSlot + TmpMax - 1))))) then
        begin
          TmpCount := TmpPlanetRow[TmpLeft] and $FF0000 shr 16;
          if (TmpCount = 1) then
          begin
            TmpShip := TmpPlanetLine.Ships[0];
            TmpSlot := TmpLeftSlot;
            // Проверим чтобы крайний не влетел в тыл
            if not CheckBackZone(TmpShip.TechActive(plttIntoBackzone), TmpPlanetLine.Destination, TmpSlot, TmpShip.Owner) then
            begin
              Dec(TmpLeft);
              Continue;
            end;
          end;
          TmpPlanetRow[TmpLeft] := TmpPlanetRow[TmpLeft] or 1;
          Inc(TmpMax, TmpCount);
          Dec(TmpLeft);
        end else
        begin
          TmpCount := TmpPlanetRow[TmpRight] and $FF0000 shr 16;
          if (TmpCount = 1) then
          begin
            TmpShip := TmpPlanetLine.Ships[TmpMax];
            TmpSlot := TmpRightSlot;
            // Проверим чтобы крайний не влетел в тыл
            if not CheckBackZone(TmpShip.TechActive(plttIntoBackzone), TmpPlanetLine.Destination, TmpSlot, TmpShip.Owner) then
            begin
              Inc(TmpRight);
              Continue;
            end;
          end;
          TmpCenter := TmpRight;
          TmpPlanetRow[TmpRight] := TmpPlanetRow[TmpRight] or 1;
          Inc(TmpMax, TmpPlanetRow[TmpRight] and $FF0000 shr 16);
          Inc(TmpRight);
        end;
      end;

      TmpCount := 1;
      TmpStart := TmpCenter;
      // Отправим кораблики в найденные слоты
      for TmpIndex := 0 to Pred(TmpPlanetLine.Count) do
      begin
        repeat
          if (TmpPlanetRow[TmpStart] and $FF = 0) then
          begin
            if (TmpStart > 0) then
              Dec(TmpStart)
            else
              TmpStart := Pred(TmpPlanetRow.Count);
            Continue;
          end;
          // Текущий слот - базовый + смещение
          TmpSlot := TPlLanding.Offset((TmpPlanetRow[TmpStart] and $FF00 shr 8) + (TmpPlanetRow[TmpStart] and $FF0000 shr 16) - TmpCount);
          TmpShip := TmpPlanetLine.Ships[TmpIndex];
          // Попробуем отправить кораблик
          if TPlanetarThread(Engine).ControlShips.MoveToPlanet.Execute(TmpShip, AShipGroup.Planets[TmpShip.GroupHope], TmpSlot) then
          begin
            Inc(TmpShip.GroupHope);
            if (TmpShip.GroupHope = AShipGroup.Planets.Count) then
            begin
              TmpShip.Group := nil;
              AShipGroup.Ships.Remove(TmpShip);
            end;
          end;
          // Перейдем на следующий свободный слот
          Inc(TmpCount);
          if (Pred(TmpCount) = TmpPlanetRow[TmpStart] and $FF0000 shr 16) then
          begin
            TmpCount := 1;
            if (TmpStart > 0) then
              Dec(TmpStart)
            else
              TmpStart := Pred(TmpPlanetRow.Count);
          end;
          Break;
        until (TmpStart = TmpCenter);
      end;
    end;

    FreeAndNil(TmpPlanetRow);
    FreeAndNil(TmpPlanetRows);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPLShipsControlGroup.Player(APlanetList: TPlPlanetList; AShipList: TPlShipList;
  APlayer: TGlPlayer);
var
  TmpI: Integer;
begin
  try
    // Проверим на наличие вражеских юнитов
    for TmpI := Pred(AShipList.Count) downto 0 do
    begin
      if (not AShipList[TmpI].Owner.IsRoleFriend(APlayer)) then
        AShipList.Delete(TmpI)
    end;
    // Проверим на количество доступного флота
    if (AShipList.Count = 0) then
    begin
      TLogAccess.Write(ClassName, 'ShipCount');
      Exit();
    end;
    // Проверим на количество доступного флота
    if (APlanetList.Count = 0) then
    begin
      TLogAccess.Write(ClassName, 'PlanetCount');
      Exit();
    end;
    // Выполним создание группы
    Allocate(APlanetList, AShipList);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
