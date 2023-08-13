unit SR.Transport.Indy;

interface

uses
  System.SysUtils,
  System.Classes,
  IdTCPServer,
  IdContext,
  IdGlobal,
  IdException,

  SR.Globals.Log,
  SR.Transport.Custom,
  SR.Transport.Buffer;

type
  TTransportSocket = class(TTransportCustom)
  private var
    FTcpServer: TIdTCPServer;
  private
    procedure OnConnect(AContext: TIdContext);
    procedure OnExecute(AContext: TIdContext);
    procedure OnDisconnect(AContext: TIdContext);
  protected
    function DoGetIP(AClient: TObject): string; override;
    procedure DoReadCommand(AClient: TObject; ABuffer: TTransportBuffer); override;
    procedure DoWriteCommand(AClient: TObject; ABuffer: TTransportBuffer); override;
    procedure DoKillConnection(AClient: TObject); override;
  public
    constructor Create(APort: Integer; AOnConnect: TTransportSocket.TOnConnect;
      AOnCommand, AOnDisconnect: TTransportSocket.TOnCommand); override;
    destructor Destroy(); override;
  end;

implementation

constructor TTransportSocket.Create(APort: Integer; AOnConnect: TTransportSocket.TOnConnect;
  AOnCommand, AOnDisconnect: TTransportSocket.TOnCommand);
begin
  inherited Create(APort, AOnConnect, AOnCommand, AOnDisconnect);

  FTcpServer := TIdTCPServer.Create(nil);
  FTcpServer.UseNagle := False;
  FTcpServer.OnConnect := OnConnect;
  FTcpServer.OnDisconnect := OnDisconnect;
  FTcpServer.OnExecute := OnExecute;
  FTcpServer.DefaultPort := APort;
  FTcpServer.Active := True;
end;

destructor TTransportSocket.Destroy();
begin
  FreeAndNil(FTcpServer);

  inherited Destroy();
end;

procedure TTransportSocket.OnConnect(AContext: TIdContext);
begin
  AContext.Data := DoConnect(AContext);
end;

procedure TTransportSocket.OnExecute(AContext: TIdContext);
begin
  if AContext.Connection.IOHandler.Readable(1)
    or (AContext.Connection.IOHandler.InputBuffer.Size > 0)
  then
    DoRead(AContext.Data)
  else
    DoWrite(AContext.Data);
end;

procedure TTransportSocket.OnDisconnect(AContext: TIdContext);
begin
  DoDisconnect(AContext.Data);
end;

function TTransportSocket.DoGetIP(AClient: TObject): string;
begin
  Result := TIdContext(AClient).Binding.PeerIP;
end;

procedure TTransportSocket.DoReadCommand(AClient: TObject; ABuffer: TTransportBuffer);
var
  TmpSize: Integer;
begin
  try
    TmpSize := TIdContext(AClient).Connection.IOHandler.ReadInt32(False);
    TIdContext(AClient).Connection.IOHandler.ReadStream(ABuffer, TmpSize);
  except
    on E: Exception do
    begin
      ABuffer.Clear();
      if (E.ClassType <> EIdConnClosedGracefully) then
        TLogAccess.Write(E);
    end;
  end;
end;

procedure TTransportSocket.DoWriteCommand(AClient: TObject; ABuffer: TTransportBuffer);
begin
  try
    {$MESSAGE 'sleep 120'}
    TIdContext(AClient).Connection.IOHandler.Write(ABuffer);
    FreeAndNil(ABuffer);
  except
    on E: Exception do
    begin
      if (E.ClassType <> EIdConnClosedGracefully) then
        TLogAccess.Write(E);
    end;
  end;
end;

procedure TTransportSocket.DoKillConnection(AClient: TObject);
begin
  TIdContext(AClient).Connection.Disconnect();
end;

end.
