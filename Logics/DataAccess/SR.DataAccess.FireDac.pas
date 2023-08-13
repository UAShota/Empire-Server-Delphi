{**********************************************}
{                                              }
{ Модуь доступа к БД через FireDac             }
{ Copyright (c) 2016 UAShota                    }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.DataAccess.FireDac;

interface

uses
  System.SysUtils,
  System.Classes,
  System.SyncObjs,

  FireDAC.Comp.Client,
  FireDAC.Stan.Def,
  FireDAC.Stan.Async,
  FireDAC.Stan.Param,
  FireDAC.Stan.Option,
  FireDAC.Phys.MySQLDef,
  FireDAC.Phys.MySQL,
  FireDAC.DApt,
  Data.DB,

  SR.Globals.Log,
  SR.DataAccess.Custom;

type
  // Датасет, выполняющий запросы
  TDataAccessDataset = class(TDataAccessCustomDataset)
  private var
    // Локальный доступ к хранимкам
    FDataset: TFDStoredProc;
    // Признак обработанной первой записи
    FContinue: Boolean;
    // Блокировка одновременных запросов
    FLock: TCriticalSection;
  public
    // Создание датасета
    constructor Create(AConnection: TFDConnection; ALock: TCriticalSection);
    // Удаление датасета
    destructor Destroy(); override;
    // Вызов хранимой процедуры
    function Call(const AStoredName: string; const AParams: array of const): TDataAccessCustomDataset; override;
    // Чтение очередной записи
    function ReadRow(): Boolean; override;
    // Возврат значения как Integer
    function ReadInteger(const AFieldName: string): Integer; override;
    // Возврат значения как String
    function ReadString(const AFieldName: string): string; override;
    // Возврат значения как DateTime
    function ReadDateTime(const AFieldName: string): TDateTime; override;
  end;

  TDataAccessConnection = class(TDataAccessCustom)
  private var
    // Локальное соединение
    FConnection: TFDConnection;
    // Блокировка одновременных запросов
    FLock: TCriticalSection;
  public
    // Создание коннектора
    constructor Create();
    // Удаление коннектора
    destructor Destroy(); override;
    // Соединение
    procedure Connect(); override;
    // Отсоединение
    procedure Disconnect(); override;
    // Вызов хранимой процедуры с параметрами
    function Call(const AStoredName: string; const AParams: array of const): TDataAccessCustomDataset; override;
  end;

implementation

constructor TDataAccessConnection.Create();
begin
  try
    inherited;
    FConnection := TFDConnection.Create(nil);
    FConnection.DriverName := 'MySQL';
    FConnection.Params.UserName := S_USERNAME;
    FConnection.Params.Password := S_PWD;
    FConnection.Params.Database := S_DATABASE;
    FLock := TCriticalSection.Create();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

destructor TDataAccessConnection.Destroy();
begin
  try
    FreeAndNil(FConnection);
    inherited;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TDataAccessConnection.Connect();
begin
  try
    FConnection.Connected := True;
  except
    on E: Exception do
      TLogAccess.Write(E, True);
  end;
end;

procedure TDataAccessConnection.Disconnect();
begin
  try
    FConnection.Connected := False;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TDataAccessConnection.Call(const AStoredName: string;
  const AParams: array of const): TDataAccessCustomDataset;
begin
  Result := nil;
  try
    Result := TDataAccessDataset.Create(FConnection, FLock);
    Result.Call(AStoredName, AParams);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

constructor TDataAccessDataset.Create(AConnection: TFDConnection; ALock: TCriticalSection);
begin
  try
    inherited Create();
    FLock := ALock;
    FLock.Acquire();
    FDataset := TFDStoredProc.Create(nil);
    FDataset.Connection := AConnection;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

destructor TDataAccessDataset.Destroy();
begin
  try
    FreeAndNil(FDataset);
    FLock.Release();
    inherited;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TDataAccessDataset.Call(const AStoredName: string;
  const AParams: array of const): TDataAccessCustomDataset;
var
  TmpI: Integer;
begin
  Result := Self;
  try
    FDataset.StoredProcName := AStoredName;
    FDataset.Prepare();
    for TmpI := 0 to Pred(FDataset.Params.Count) do
    begin
      case FDataset.Params[TmpI].DataType of
        ftInteger:
          FDataset.Params[TmpI].AsInteger := AParams[TmpI].VInteger;
        ftString:
          FDataset.Params[TmpI].AsString := String(AParams[TmpI].VUnicodeString);
      end;
    end;
    FDataset.Open();
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TDataAccessDataset.ReadRow(): Boolean;
begin
  Result := False;
  try
    if (FContinue) then
      FDataset.Next()
    else
      FContinue := True;
    Result := (not FDataset.Eof);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TDataAccessDataset.ReadDateTime(const AFieldName: string): TDateTime;
begin
  Result := 0;
  try
    Result := FDataset.FieldByName(AFieldName).AsDateTime;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TDataAccessDataset.ReadInteger(const AFieldName: string): Integer;
begin
  Result := 0;
  try
    Result := FDataset.FieldByName(AFieldName).AsInteger;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

function TDataAccessDataset.ReadString(const AFieldName: string): string;
begin
  Result := EmptyStr;
  try
    Result := FDataset.FieldByName(AFieldName).AsString;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
