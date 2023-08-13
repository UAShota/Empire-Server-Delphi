unit SR.Transport.Buffer;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections;

type
  TTransportBuffer = class(TMemoryStream)
  private var
    FSizeOffset: Integer;
  public var
    Validated: Boolean;
  public
    function ReadCommand(): Integer;
    function ReadString(): string;
    function ReadInteger(): Integer;
    function ReadBoolean(): Boolean;
    procedure WriteString(const AValue: string);
    procedure WriteInteger(AValue: Integer);
    procedure WriteBoolean(AValue: Boolean);
    procedure WriteBuffer(ABuffer: TTransportBuffer); overload;
    procedure WriteBuffer(ABuffer: TTransportBuffer; ARole: Integer); overload;
    // ������ ������� ������ � ��� ���������
    function Command(ACommand: Integer): TTransportBuffer;
    // ������ ������� ������
    procedure Commit();
    // ����� ������
    procedure Rollback();
  end;

  TTransportQueue = class(TObject)
  public var
    Queue: TThreadedQueue<TTransportBuffer>;
    Buffer: TTransportBuffer;
  public
    constructor Create();
    destructor Destroy(); override;
    procedure Commit();
    procedure Rollback();
  end;

implementation

function TTransportBuffer.ReadCommand(): Integer;
begin
  Read(Result, SizeOf(Result));
end;

function TTransportBuffer.ReadInteger(): Integer;
begin
  Read(Result, SizeOf(Result));
end;

function TTransportBuffer.ReadBoolean(): Boolean;
begin
  Read(Result, SizeOf(Result));
end;

function TTransportBuffer.ReadString(): string;
var
  TmpLength: Integer;
begin
  // ������� ����� ������
  Read(TmpLength, SizeOf(TmpLength));
  // ���� ��� �� ������ - ������� ������
  if (TmpLength > 0) then
  begin
    SetLength(Result, TmpLength div SizeOf(Char));
    Read(Result[1], TmpLength);
  end else
    Result := EmptyStr;
end;

procedure TTransportBuffer.WriteInteger(AValue: Integer);
begin
  Write(AValue, SizeOf(AValue));
end;

procedure TTransportBuffer.WriteBoolean(AValue: Boolean);
begin
  Write(AValue, SizeOf(AValue));
end;

procedure TTransportBuffer.WriteBuffer(ABuffer: TTransportBuffer; ARole: Integer);
begin
  ABuffer.WriteInteger(ARole);
  ABuffer.Commit();
  WriteBuffer(ABuffer);
end;

procedure TTransportBuffer.WriteBuffer(ABuffer: TTransportBuffer);
begin
  Write(ABuffer.Memory^, ABuffer.Position);
end;

procedure TTransportBuffer.WriteString(const AValue: string);
var
  TmpLength: Integer;
begin
  // ����� ������
  TmpLength := Length(AValue) * SizeOf(Char);
  Write(TmpLength, SizeOf(TmpLength));
  // ���� ������
  if (TmpLength > 0) then
    Write(AValue[1], TmpLength);
end;

function TTransportBuffer.Command(ACommand: Integer): TTransportBuffer;
begin
  // ����� ������ ������� ������
  FSizeOffset := Position;
  // ������� ��� ������ ������
  Write(ACommand, SizeOf(ACommand));
  // ���� �������
  Write(ACommand, SizeOf(ACommand));
  // � ������ ������
  Result := Self;
end;

procedure TTransportBuffer.Commit();
var
  TmpSize: Integer;
  TmpPos: Integer;
begin
  TmpSize := Position - FSizeOffset - SizeOf(TmpSize);
  TmpPos := Position;
  Position := FSizeOffset;
  Write(TmpSize, SizeOf(TmpSize));
  Position := TmpPos;
  Validated := True;
end;

procedure TTransportBuffer.Rollback();
begin
  Position := 0;
  Validated := False;
end;

{$REGION 'TTransportQueue' }

constructor TTransportQueue.Create();
begin
  inherited Create();

  Queue := TThreadedQueue<TTransportBuffer>.Create();
  Buffer := TTransportBuffer.Create();
end;

destructor TTransportQueue.Destroy();
begin
  FreeAndNil(Queue);
  FreeAndNil(Buffer);

  inherited Destroy();
end;

procedure TTransportQueue.Commit();
begin
  Queue.PushItem(Buffer);
  Buffer := TTransportBuffer.Create();
end;

procedure TTransportQueue.Rollback();
begin
  Buffer.Clear();
end;

{$ENDREGION}

end.
