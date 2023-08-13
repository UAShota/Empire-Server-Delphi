unit SR.Transport.Custom;

interface

uses
  System.SysUtils,
  System.Classes,

  SR.Globals.Player,
  SR.Transport.Buffer;

type
  TTransportCustom = class
  protected type
    TOnCommand = procedure (APlayer: TGlPlayerInfo) of object;
    TOnConnect = function (): TGlPlayerInfo of object;
  protected var
    FOnCommand: TOnCommand;
    FOnConnect: TOnConnect;
    FOnDisconnect: TOnCommand;
  protected
    function DoGetIP(AClient: TObject): string; virtual; abstract;
    procedure DoReadCommand(AClient: TObject; ABuffer: TTransportBuffer); virtual; abstract;
    procedure DoWriteCommand(AClient: TObject; ABuffer: TTransportBuffer); virtual; abstract;
    procedure DoKillConnection(AClient: TObject); virtual; abstract;
    function DoConnect(AClient: TObject): TGlPlayerInfo;
    procedure DoDisconnect(AInfo: TObject);
    procedure DoRead(AInfo: TObject);
    procedure DoWrite(AInfo: TObject);
  public
    constructor Create(APort: Integer; AOnConnect: TOnConnect; AOnCommand, AOnDisconnect: TOnCommand); virtual;
    procedure Kill(AInfo: TGlPlayerInfo);
  end;

implementation

constructor TTransportCustom.Create(APort: Integer; AOnConnect: TOnConnect;
  AOnCommand, AOnDisconnect: TOnCommand);
begin
  FOnCommand := AOnCommand;
  FOnConnect := AOnConnect;
  FOnDisconnect := AOnDisconnect;
end;

function TTransportCustom.DoConnect(AClient: TObject): TGlPlayerInfo;
begin
  Result := FOnConnect();
  Result.IP := DoGetIP(AClient);
  Result.Connection := AClient;
end;

procedure TTransportCustom.DoRead(AInfo: TObject);
var
  TmpInfo: TGlPlayerInfo;
begin
  TmpInfo := TGlPlayerInfo(AInfo);
  // Используем неубиваемый буфер
  TmpInfo.Reader.Buffer.Rollback();
  // Считаем тело пакета
  DoReadCommand(TmpInfo.Connection, TmpInfo.Reader.Buffer);
  // Отправим вызов обработчику
  if (TmpInfo.Reader.Buffer.Position > 0) then
  begin
    // Обнулим текущую позицию
    TmpInfo.Reader.Buffer.Rollback();
    FOnCommand(TmpInfo);
  end;
end;

procedure TTransportCustom.DoWrite(AInfo: TObject);
var
  TmpInfo: TGlPlayerInfo;
begin
  TmpInfo := TGlPlayerInfo(AInfo);
  // Проверим что есть что писать
  if (TmpInfo.Writer.Queue.QueueSize > 0) then
    DoWriteCommand(TmpInfo.Connection, TmpInfo.Writer.Queue.PopItem);
end;

procedure TTransportCustom.DoDisconnect(AInfo: TObject);
begin
  FOnDisconnect(TGlPlayerInfo(AInfo));
end;

procedure TTransportCustom.Kill(AInfo: TGlPlayerInfo);
begin
  DoKillConnection(AInfo.Connection);
end;

end.
