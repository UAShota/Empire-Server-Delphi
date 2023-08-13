unit SR.Globals.Protocol;

interface

uses
  System.Classes,

  SR.Globals.Player;

type
  TProtocolCustom = class
  protected var
    FEngine: TObject;
    FReadCallback: TGlProtocolReadCallback;
    FWriteCallback: TGlProtocolWriteCallback;
  protected
    // ��������� ������� ������ ��� ��������
    function GetStream(ACommand: Integer): TMemoryStream; inline;
    // ������ ������ � �����
    procedure WriteStream(AStream: TMemoryStream; const AValue: String); overload; inline;
    // ������ Integer � �����
    procedure WriteStream(AStream: TMemoryStream; const AValue: Integer); overload; inline;
    // ������ Boolean � �����
    procedure WriteStream(AStream: TMemoryStream; const AValue: Boolean); overload; inline;
  public
    constructor Create(AEngine: TObject; AReadCallback: TGlProtocolReadCallback); overload;
    // ������������� ������������ ��������
    constructor Create(AEngine: TObject; AWriteCallback: TGlProtocolWriteCallback); overload;
    procedure RecieveData(ACommand: Integer; AInfo: TGlPlayerInfo);
  end;

implementation

constructor TProtocolCustom.Create(AEngine: TObject; AReadCallback: TGlProtocolReadCallback);
begin
  FEngine := AEngine;
  FReadCallback := AReadCallback;
end;

constructor TProtocolCustom.Create(AEngine: TObject; AWriteCallback: TGlProtocolWriteCallback);
begin
  FEngine := AEngine;
  FWriteCallback := AWriteCallback;
end;

function TProtocolCustom.GetStream(ACommand: Integer): TMemoryStream;
begin
  Result := TMemoryStream.Create();
  // ������ ������
  Result.WriteBuffer(ACommand, SizeOf(Integer));
  // �������
  Result.WriteBuffer(ACommand, SizeOf(Integer));
end;

procedure TProtocolCustom.WriteStream(AStream: TMemoryStream;
  const AValue: String);
var
  TmpLength: Integer;
begin
  TmpLength := Length(AValue) * SizeOf(Char);
  AStream.WriteBuffer(TmpLength, SizeOf(TmpLength));
  if (TmpLength > 0) then
    AStream.WriteBuffer(AValue[1], TmpLength);
end;

procedure TProtocolCustom.WriteStream(AStream: TMemoryStream;
  const AValue: Integer);
begin
  AStream.WriteBuffer(AValue, SizeOf(Integer));
end;

procedure TProtocolCustom.RecieveData(ACommand: Integer; AInfo: TGlPlayerInfo);
begin

end;

procedure TProtocolCustom.WriteStream(AStream: TMemoryStream;
  const AValue: Boolean);
begin
  AStream.WriteBuffer(AValue, SizeOf(Boolean));
end;

end.
