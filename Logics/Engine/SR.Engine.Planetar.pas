{**********************************************}
{                                              }
{ Модуль управления подсистемой планетарок     }
{ Copyright (c) 2016 UAShota                    }
{                                              }
{ Rev A  2016.11.18                            }
{ Rev B  2016.01.18                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Engine.Planetar;

interface

uses
  System.SysUtils,

  SR.DataAccess,
  SR.Engine.Server,
  SR.Globals.Player,
  SR.Globals.Log,
  SR.Planetar.Dictionary;

type
  // Класс управления подсистемой планетарок
  TEnginePlanetar = class
  private
    // Загрузка боток
    class procedure DoLoadAutoPlanetars();
  public
    // Запуск модуля
    class procedure Start();
    // Остановка модуля
    class procedure Stop();

    class procedure Subscribe(AInfo: TGlPlayerInfo);

    class procedure Connect(AInfo: TGlPlayerInfo);
  end;

implementation

uses
  SR.Planetar.Profile,
  SR.Planetar.Thread;

class procedure TEnginePlanetar.DoLoadAutoPlanetars();
var
  TmpPlayer: TGlPlayer;
begin
  try
    // Загрузим список ботов
    with TDataAccess.Call('SHLoadBots') do
    try
      while ReadRow() do
      begin
        TmpPlayer := TEngineServer.FindPlayer(ReadInteger('UID'));
        TmpPlayer.IsBot := True;
        TPlanetarProfile(TmpPlayer.PlanetarProfile).Start();
      end;
    finally
      Free();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEnginePlanetar.Start();
begin
  try
    // Загрузим словарь планетарок
    TPlanetarDictionary.Start();
    // Запустим планетарки ботов
    DoLoadAutoPlanetars();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEnginePlanetar.Stop();
begin
  try
    TPlanetarDictionary.Stop();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEnginePlanetar.Connect(AInfo: TGlPlayerInfo);
begin
  TPlanetarProfile(AInfo.Player.PlanetarProfile).Connect();
end;

class procedure TEnginePlanetar.Subscribe(AInfo: TGlPlayerInfo);
var
  TmpPlanetarID: Integer;
begin
  TmpPlanetarID := AInfo.Reader.Buffer.ReadInteger();
  TPlanetarProfile(AInfo.Player.PlanetarProfile).Subscribe(TmpPlanetarID);
end;

end.
