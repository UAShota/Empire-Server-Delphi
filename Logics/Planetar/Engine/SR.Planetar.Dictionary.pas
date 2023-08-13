{**********************************************}
{                                              }
{ Модуль управления планетарными словарями     }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev A  2016.12.14                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Planetar.Dictionary;

interface

uses
  System.SysUtils,

  SR.DataAccess,
  SR.Globals.Log,
  SR.Globals.Types,
  SR.Planetar.Classes;

type
  // Класс управления планетарными словарями
  TPlanetarDictionary = class
  private class var
    // Список технологий для корабликов
    FShipTechList: TPLShipTechRace;
    // Список технологий для строений
    FBuildingTechList: TPlBuildingTechRace;
  private
    // Загрузка технологий корабликов
    class procedure DoLoadTechShip();
    // Загрузка технологий строений
    class procedure DoLoadTechBuildings();
  public
    // Управляемая инициализация
    class procedure Start();
    // Управляемая инициализация
    class procedure Stop();
  public
    // Список доступных технологий корабликов
    class property ShipTechList: TPLShipTechRace
                   read FShipTechList;
    // Список доступных технологий строений
    class property BuildingTechList: TPlBuildingTechRace
                   read FBuildingTechList;
  end;

implementation

class procedure TPlanetarDictionary.Start();
begin
  try
    DoLoadTechShip();
    DoLoadTechBuildings();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TPlanetarDictionary.Stop();
begin
  try
    FillChar(FShipTechList, SizeOf(FShipTechList), 0);
    FillChar(FBuildingTechList, SizeOf(FBuildingTechList), 0);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TPlanetarDictionary.DoLoadTechShip();
var
  TmpTechType: TPlShipTechType;
  TmpTechInfo: TPLShipTechItem;
  TmpTechRace: TGlRaceType;
  TmpShipType: TPlShipType;
  TmpRace: TGlRaceType;
begin
  try
    with TDataAccess.Call('PLLoadDictTechShips') do
    try
      while ReadRow() do
      begin
        TmpShipType := TPlShipType(ReadInteger('ID_OBJECT'));
        TmpTechType := TPlShipTechType(ReadInteger('ID_TECH'));
        TmpTechRace := TGlRaceType(ReadInteger('ID_RACE'));
        // Загрузим техи для каждой расы отдельно
        for TmpRace := Low(TGlRaceType) to High(TGlRaceType) do
        begin
          // Пропускаем только если раса не указана или совпадает с текущей
          if (TmpTechRace <> raceEmpty)
            and (TmpRace <> TmpTechRace)
          then
            Continue;
          // Пропишем теху
          TmpTechInfo.Supported := True;
          TmpTechInfo.Count := ReadInteger('LEVEL_COUNT');
          TmpTechInfo.Levels[0] := ReadInteger('LEVEL_0');
          TmpTechInfo.Levels[1] := ReadInteger('LEVEL_1');
          TmpTechInfo.Levels[2] := ReadInteger('LEVEL_2');
          TmpTechInfo.Levels[3] := ReadInteger('LEVEL_3');
          TmpTechInfo.Levels[4] := ReadInteger('LEVEL_4');
          TmpTechInfo.Levels[5] := ReadInteger('LEVEL_5');
          TmpTechInfo.Cooldowns[0] := ReadInteger('CD_0');
          TmpTechInfo.Cooldowns[1] := ReadInteger('CD_1');
          TmpTechInfo.Cooldowns[2] := ReadInteger('CD_2');
          TmpTechInfo.Cooldowns[3] := ReadInteger('CD_3');
          TmpTechInfo.Cooldowns[4] := ReadInteger('CD_4');
          TmpTechInfo.Cooldowns[5] := ReadInteger('CD_5');
          FShipTechList[TmpRace, TmpShipType, TmpTechType] := TmpTechInfo;
        end;
      end;
    finally
      Free();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TPlanetarDictionary.DoLoadTechBuildings();
var
  TmpTechType: TPlBuildingTechType;
  TmpTechInfo: TPlBuildingTechItem;
  TmpTechRace: TGlRaceType;
  TmpBuildingType: TPlBuildingType;
  TmpRace: TGlRaceType;
begin
  try
    with TDataAccess.Call('PLLoadDictTechBuilding') do
    try
      while ReadRow() do
      begin
        TmpBuildingType := TPlBuildingType(ReadInteger('ID_OBJECT'));
        TmpTechType := TPlBuildingTechType(ReadInteger('ID_TECH'));
        TmpTechRace := TGlRaceType(ReadInteger('ID_RACE'));
        // Загрузим техи для каждой расы отдельно
        for TmpRace := Succ(raceEmpty) to High(TGlRaceType) do
        begin
          // Пропускаем только если раса не указана или совпадает с текущей
          if (TmpTechRace <> raceEmpty)
            and (TmpRace <> TmpTechRace)
          then
            Continue;
          // Пропишем теху
          TmpTechInfo.Supported := True;
          TmpTechInfo.Count := ReadInteger('LEVEL_COUNT');
          TmpTechInfo.Levels[0] := ReadInteger('LEVEL_0');
          TmpTechInfo.Levels[1] := ReadInteger('LEVEL_1');
          TmpTechInfo.Levels[2] := ReadInteger('LEVEL_2');
          TmpTechInfo.Levels[3] := ReadInteger('LEVEL_3');
          TmpTechInfo.Levels[4] := ReadInteger('LEVEL_4');
          TmpTechInfo.Levels[5] := ReadInteger('LEVEL_5');
          FBuildingTechList[TmpRace, TmpBuildingType, TmpTechType] := TmpTechInfo;
        end;
      end;
    finally
       Free();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
