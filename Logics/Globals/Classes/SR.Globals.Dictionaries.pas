{**********************************************}
{                                              }
{ Модуль общих словарей                        }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev A  2017.03.30                            }
{ Rev B  2017.03.30                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Globals.Dictionaries;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.Globals.Types,
  SR.DataAccess;

type
  // Класс общих словарей
  TGlDictionaries = class
  private class var
    // Список ресурсов
    FResList: TGlResourcesList;
    // Список рас
    FRaceList: TGlRaceList;
  private
    // Загрука рас
    class procedure DoLoadRaces();
    // Загрузка ресурсов
    class procedure DoLoadResources();
  public
    // Запуск синглтона
    class procedure Start();
    // остановка синглтона
    class procedure Stop();
  public
    // Список рас
    class property Races: TGlRaceList
                   read FRaceList;
    // Спислк ресурсов
    class property Resources: TGlResourcesList
                   read FResList;
  end;

implementation

class procedure TGlDictionaries.Start();
begin
  try
    DoLoadRaces();
    DoLoadResources();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TGlDictionaries.Stop();
begin
  try
    FillChar(FResList, SizeOf(FResList), 0);
    FillChar(FRaceList, SizeOf(FRaceList), 0);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TGlDictionaries.DoLoadResources();
var
  TmpRes: TGlResourceInfo;
begin
  try
    with TDataAccess.Call('SHLoadResources') do
    try
      while ReadRow() do
      begin
        TmpRes.Max := ReadInteger('MAXIMUM');
        FResList[TGlResourceType(ReadInteger('UID'))] := TmpRes;
      end;
    finally
      Free();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TGlDictionaries.DoLoadRaces();
var
  TmpRace: TGlRaceInfo;
begin
  try
    with TDataAccess.Call('SHLoadRaces') do
    try
      while ReadRow() do
      begin
        FRaceList[TGlRaceType(ReadInteger('UID'))] := TmpRace;
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
