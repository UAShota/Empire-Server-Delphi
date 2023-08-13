unit SR.Transport;

interface

uses
  SR.Transport.Custom,
  SR.Transport.Indy;

type
  TTransport = class(TTransportSocket)
  public
    constructor Create(AOnConnect: TTransportSocket.TOnConnect;
      AOnCommand, AOnDisconnect: TTransportSocket.TOnCommand); reintroduce;
  end;

implementation

constructor TTransport.Create(AOnConnect: TTransportSocket.TOnConnect;
  AOnCommand, AOnDisconnect: TTransportSocket.TOnCommand);
var
  TmpPort: Integer;
begin
  {$IFDEF DEBUG}
  TmpPort := 25599;
  {$ELSE}
  TmpPort := 25600;
  {$ENDIF}
  inherited Create(TmpPort, AOnConnect, AOnCommand, AOnDisconnect);
end;

end.
