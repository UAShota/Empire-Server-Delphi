{**********************************************}
{                                              }
{ Модуль управления подсистемой игроков        }
{ Copyright (c) 2016 UAShota                    }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Engine.Server;

interface

uses
  System.SysUtils,

  SR.DataAccess,
  SR.Transport,
  SR.Globals.Dictionaries,
  SR.Globals.Log,
  SR.Globals.Types,
  SR.Globals.Player;

type
  // Класс управления подсистемой игроков
  TEngineServer = class
  private const
    // Комманда сообщения чата
    CMD_CHAT_MESSAGE = $0001;
    // Комманда запроса авторизации
    CMD_LOGIN_AUTH = $0002;
    // Комманда некорректной авторизации
    CMD_LOGIN_FAILED = $0003;
    // Комманда успешной авторизации
    CMD_LOGIN_ACCEPT = $0004;
    // Комманда оповещения о повторном подключении
    CMD_LOGIN_RELOG = $0005;
    // Ошибка - неверно указан логин или пароль
    I_ERROR_INVALID_CREDENTIALS = 1;
  private class var
    // Список игроков
    FPlayers: TGlPlayerDict;
    // Последний запрошенный UID
    FLastUID: Integer;
    // Последний запрошенный профиль
    FLastPlayer: TGlPlayer;
    // Протокол связи
    FTransport: TTransport;
  private
    // Каллбак подключения клиента
    class function DoOnConnect(): TGlPlayerInfo;
    // Каллбак получения команды
    class procedure DoOnCommand(AInfo: TGlPlayerInfo);
    // Каллбак отсоединения клиента
    class procedure DoOnDisconnect(AInfo: TGlPlayerInfo);
    // Загрузка профиля игрока
    class function DoLoadPlayer(AUID: Integer): TGlPlayer;
    // Авторизация игрока
    class procedure DoCmdLogin(AInfo: TGlPlayerInfo);
    // Авторизация игрока успешна
    class procedure DoCmdLoginAccept(APlayer: TGlPlayer; AInfo: TGlPlayerInfo);
    // Авторизация игрока провалена
    class procedure DoCmdLoginFailed(AInfo: TGlPlayerInfo);
  public
    // Запуск модуля
    class procedure Start();
    // Остановка модуля
    class procedure Stop();
    // Поиск игрока по идентификатору
    class function FindPlayer(AUID: Integer): TGlPlayer;
    // Отправка сообщения в чат игрока
    class procedure ChatMessage(const AText: String; APlayer: TGlPlayer = nil);
  end;

implementation

uses
  SR.Engine.Planetar,
  SR.Engine.Galaxy;

class procedure TEngineServer.Start();
begin
  try
    // Список игроков
    FPlayers := TGlPlayerDict.Create();
    // Загрузим доступ к БД
    TDataAccess.Start();
    // Загрузим общие словари
    TGlDictionaries.Start();
    // Загрузим планетарки
    TEnginePlanetar.Start();
    // Загрузим сетевой протокол
    FTransport := TTransport.Create(DoOnConnect, DoOnCommand, DoOnDisconnect);
    // Залогируем старт
    TLogAccess.Write(ClassName, 'Started');
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEngineServer.Stop();
begin
  try
    // Остановим сокетный сервер
    FreeAndNil(FTransport);
    // Остановим планетарки
    TEnginePlanetar.Stop();
    // Остановим доступ к БД
    TDataAccess.Stop();
    // Остановка словаря
    TGlDictionaries.Stop();
    // Залогируем остановку
    TLogAccess.Write(ClassName, 'Stoped');
    // Список игроков
    FreeAndNil(FPlayers);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class function TEngineServer.DoOnConnect(): TGlPlayerInfo;
begin
  Result := TGlPlayerInfo.Create();
end;

class procedure TEngineServer.DoOnCommand(AInfo: TGlPlayerInfo);
begin
  case AInfo.Reader.Buffer.ReadCommand() of
    CMD_LOGIN_AUTH:
      DoCmdLogin(AInfo);
    $1F01:
      TEnginePlanetar.Subscribe(AInfo);
    $1011:
      TEnginePlanetar.Connect(AInfo);
    else
    begin
      AInfo.Reader.Buffer.Rollback();
      AInfo.Reader.Commit();
      Exit();
    end;
  end;
end;

class procedure TEngineServer.DoOnDisconnect(AInfo: TGlPlayerInfo);
begin
  AInfo.Player.Disconnect();
end;

class function TEngineServer.DoLoadPlayer(AUID: Integer): TGlPlayer;
begin
  Result := nil;
  try
    with TDataAccess.Call('SHLoadProfile', [AUID]) do
    try
      // Загрузим профиль игрока
      Result := TGlPlayer.Create();
      Result.UID := AUID;
      Result.Name := ReadString('LOGIN');
      Result.Race := TGlRaceType(ReadInteger('ID_RACE'));
      Result.Gold := ReadInteger('MONEY_GOLD');
      Result.Credits := ReadInteger('MONEY_CREDITS');
      Result.Fuel := ReadInteger('MONEY_FUEL');
      Result.Storage.Size := ReadInteger('STORAGE_SIZE');
      Result.Password := ReadString('PWD_HASH');
      Result.Load();
      // Добавим его в словарь
      FPlayers.Add(AUID, Result);
    finally
      Free();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEngineServer.DoCmdLogin(AInfo: TGlPlayerInfo);
var
  TmpLogin: String;
  TmpPassword: String;
  TmpUID: Integer;
  TmpPlayer: TGlPlayer;
begin
  try
    // Получим сведения после соединения клиента
    TmpLogin := AInfo.Reader.Buffer.ReadString();
    TmpPassword := AInfo.Reader.Buffer.ReadString();
    // Запросим корректность авторизации
    with TDataAccess.Call('SHLoadPlayer', [TmpLogin, TmpPassword]) do
    try
      TmpUID := ReadInteger('UID');
    finally
      Free();
    end;
    // Если идентфиикатор в базе есть, поищем активный профиль
    if (TmpUID > 0) then
      TmpPlayer := FindPlayer(TmpUID)
    else
      TmpPlayer := nil;
    // Отправим параметры персонажа
    if Assigned(TmpPlayer) then
      DoCmdLoginAccept(TmpPlayer, AInfo)
    else
      DoCmdLoginFailed(AInfo);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEngineServer.DoCmdLoginAccept(APlayer: TGlPlayer; AInfo: TGlPlayerInfo);
begin
  try
    // Отключим предыдущего игрока
    if (Assigned(APlayer.Info)) then
    begin
      APlayer.Info.Writer.Buffer.Command(CMD_LOGIN_RELOG).Commit();
      APlayer.Info.Writer.Commit();
      APlayer.Disconnect();
    end;
    // Отправим сообщение о успешной авторизации для кэша пароля
    with AInfo.Writer.Buffer.Command(CMD_LOGIN_ACCEPT) do
    begin
      WriteString(APlayer.Password);
      WriteInteger(APlayer.UID);
      WriteInteger(Integer(APlayer.Race));
      Commit();
    end;
    AInfo.Writer.Commit();
    // Стартанем созвездие либо разрешим присоединиться
    APlayer.Connect(AInfo);
    // Залогируем
    TLogAccess.Write(ClassName, ' accepted from ' + AInfo.IP);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEngineServer.DoCmdLoginFailed(AInfo: TGlPlayerInfo);
begin
  try
    with AInfo.Writer.Buffer.Command(CMD_LOGIN_FAILED) do
    begin
      WriteInteger(I_ERROR_INVALID_CREDENTIALS);
      Commit();
    end;
    AInfo.Writer.Commit();
    // Залогируем
    TLogAccess.Write(ClassName, 'failed from ' + AInfo.IP);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEngineServer.ChatMessage(const AText: String; APlayer: TGlPlayer);
var
  TmpPlayer: TGlPlayerDictPair;
begin
  try
    // Отправим сообщение всем участникам
    for TmpPlayer in FPlayers do
    begin
      // Пропускаем неактивные профили
      if (not Assigned(TmpPlayer.Value.Info)) then
        Continue;
      // Пересылаем сообщение
      with TmpPlayer.Value.Info.Writer.Buffer.Command(CMD_CHAT_MESSAGE) do
      begin
        WriteString(AText);
        Commit();
      end;
      TmpPlayer.Value.Info.Writer.Commit();
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class function TEngineServer.FindPlayer(AUID: Integer): TGlPlayer;
begin
  Result := nil;
  try
    // При повторном запросе того-же персонажа, вернем данные с кеша
    if (FLastUID = AUID) then
      Exit(FLastPlayer);
    // Иначе поищем в списке или загрузим с базы
    if (not FPlayers.TryGetValue(AUID, Result)) then
      Result := DoLoadPlayer(AUID);
    // И сохраним в кеш
    FLastUID := AUID;
    FLastPlayer := Result;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
