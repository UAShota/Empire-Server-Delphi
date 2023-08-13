{**********************************************}
{                                              }
{ ������ ���������� ����������� �������        }
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
  // ����� ���������� ����������� �������
  TEngineServer = class
  private const
    // �������� ��������� ����
    CMD_CHAT_MESSAGE = $0001;
    // �������� ������� �����������
    CMD_LOGIN_AUTH = $0002;
    // �������� ������������ �����������
    CMD_LOGIN_FAILED = $0003;
    // �������� �������� �����������
    CMD_LOGIN_ACCEPT = $0004;
    // �������� ���������� � ��������� �����������
    CMD_LOGIN_RELOG = $0005;
    // ������ - ������� ������ ����� ��� ������
    I_ERROR_INVALID_CREDENTIALS = 1;
  private class var
    // ������ �������
    FPlayers: TGlPlayerDict;
    // ��������� ����������� UID
    FLastUID: Integer;
    // ��������� ����������� �������
    FLastPlayer: TGlPlayer;
    // �������� �����
    FTransport: TTransport;
  private
    // ������� ����������� �������
    class function DoOnConnect(): TGlPlayerInfo;
    // ������� ��������� �������
    class procedure DoOnCommand(AInfo: TGlPlayerInfo);
    // ������� ������������ �������
    class procedure DoOnDisconnect(AInfo: TGlPlayerInfo);
    // �������� ������� ������
    class function DoLoadPlayer(AUID: Integer): TGlPlayer;
    // ����������� ������
    class procedure DoCmdLogin(AInfo: TGlPlayerInfo);
    // ����������� ������ �������
    class procedure DoCmdLoginAccept(APlayer: TGlPlayer; AInfo: TGlPlayerInfo);
    // ����������� ������ ���������
    class procedure DoCmdLoginFailed(AInfo: TGlPlayerInfo);
  public
    // ������ ������
    class procedure Start();
    // ��������� ������
    class procedure Stop();
    // ����� ������ �� ��������������
    class function FindPlayer(AUID: Integer): TGlPlayer;
    // �������� ��������� � ��� ������
    class procedure ChatMessage(const AText: String; APlayer: TGlPlayer = nil);
  end;

implementation

uses
  SR.Engine.Planetar,
  SR.Engine.Galaxy;

class procedure TEngineServer.Start();
begin
  try
    // ������ �������
    FPlayers := TGlPlayerDict.Create();
    // �������� ������ � ��
    TDataAccess.Start();
    // �������� ����� �������
    TGlDictionaries.Start();
    // �������� ����������
    TEnginePlanetar.Start();
    // �������� ������� ��������
    FTransport := TTransport.Create(DoOnConnect, DoOnCommand, DoOnDisconnect);
    // ���������� �����
    TLogAccess.Write(ClassName, 'Started');
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEngineServer.Stop();
begin
  try
    // ��������� �������� ������
    FreeAndNil(FTransport);
    // ��������� ����������
    TEnginePlanetar.Stop();
    // ��������� ������ � ��
    TDataAccess.Stop();
    // ��������� �������
    TGlDictionaries.Stop();
    // ���������� ���������
    TLogAccess.Write(ClassName, 'Stoped');
    // ������ �������
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
      // �������� ������� ������
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
      // ������� ��� � �������
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
    // ������� �������� ����� ���������� �������
    TmpLogin := AInfo.Reader.Buffer.ReadString();
    TmpPassword := AInfo.Reader.Buffer.ReadString();
    // �������� ������������ �����������
    with TDataAccess.Call('SHLoadPlayer', [TmpLogin, TmpPassword]) do
    try
      TmpUID := ReadInteger('UID');
    finally
      Free();
    end;
    // ���� ������������� � ���� ����, ������ �������� �������
    if (TmpUID > 0) then
      TmpPlayer := FindPlayer(TmpUID)
    else
      TmpPlayer := nil;
    // �������� ��������� ���������
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
    // �������� ����������� ������
    if (Assigned(APlayer.Info)) then
    begin
      APlayer.Info.Writer.Buffer.Command(CMD_LOGIN_RELOG).Commit();
      APlayer.Info.Writer.Commit();
      APlayer.Disconnect();
    end;
    // �������� ��������� � �������� ����������� ��� ���� ������
    with AInfo.Writer.Buffer.Command(CMD_LOGIN_ACCEPT) do
    begin
      WriteString(APlayer.Password);
      WriteInteger(APlayer.UID);
      WriteInteger(Integer(APlayer.Race));
      Commit();
    end;
    AInfo.Writer.Commit();
    // ��������� ��������� ���� �������� ��������������
    APlayer.Connect(AInfo);
    // ����������
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
    // ����������
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
    // �������� ��������� ���� ����������
    for TmpPlayer in FPlayers do
    begin
      // ���������� ���������� �������
      if (not Assigned(TmpPlayer.Value.Info)) then
        Continue;
      // ���������� ���������
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
    // ��� ��������� ������� ����-�� ���������, ������ ������ � ����
    if (FLastUID = AUID) then
      Exit(FLastPlayer);
    // ����� ������ � ������ ��� �������� � ����
    if (not FPlayers.TryGetValue(AUID, Result)) then
      Result := DoLoadPlayer(AUID);
    // � �������� � ���
    FLastUID := AUID;
    FLastPlayer := Result;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
