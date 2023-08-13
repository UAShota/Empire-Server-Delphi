{**********************************************}
{                                              }
{ Модуль управления подсистемой галактик       }
{ Copyright (c) 2016 UAShota                    }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Engine.Galaxy;

interface

uses
  System.SysUtils,

  SR.Globals.Player,
  SR.Globals.Log;

type
  // Класс управления подсистемой галактик
  TEngineGalaxy = class
  private const
    // Код команды смены галактики
    CMD_SELECT_GALAXY = $2F00;
  private
    // Загрузка сцены галактики
    class procedure DoSelectGalaxy(AInfo: TGlPlayerInfo);
  public
    // Запуск модуля
    class procedure Start();
    // Остановка модуля
    class procedure Stop();
    // Обработка принятой команды
    class procedure Process(AInfo: TGlPlayerInfo);
  end;

implementation

uses
  SR.Planetar.Profile,
  SR.Planetar.Thread;

class procedure TEngineGalaxy.DoSelectGalaxy(AInfo: TGlPlayerInfo);
begin
  try
    // Удалим подписку с предыдущей системы
    TPlanetarProfile(AInfo.Player.PlanetarProfile).Disconnect();
    // Отправим сообщение что загрузка разрешена
    TPlanetarThread(TPlanetarProfile(AInfo.Player.PlanetarProfile).Subscribed).SocketWriter.GalaxyLoadAccept(AInfo.Player);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEngineGalaxy.Process(AInfo: TGlPlayerInfo);
var
  TmpCommand: Integer;
begin
  { TODO -omdv : Galaxy ыключить в работу }
{  try
    TmpCommand := AInfo.ReadBuffer.ReadCommand();
    // Комманда смены типа сцены либо в текущую планетарку
    case TmpCommand of
      CMD_SELECT_GALAXY:
        DoSelectGalaxy(AInfo);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;}
end;

class procedure TEngineGalaxy.Start();
begin
  try
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEngineGalaxy.Stop();
begin
  try
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
