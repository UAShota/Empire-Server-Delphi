unit SR.DataAccess.DBX;

interface

uses
  System.SysUtils,
  System.SyncObjs,

  Data.DBXMySQL,
  Data.DB,
  Data.SqlExpr,
  Data.FMTBcd,

  SR.DataAccess.Custom;

{
DriverUnit=Data.DBXMySQL
DriverPackageLoader=TDBXDynalinkDriverLoader,DbxCommonDriver160.bpl
DriverAssemblyLoader=Borland.Data.TDBXDynalinkDriverLoader,Borland.Data.DbxCommonDriver,Version=16.0.0.0,Culture=neutral,PublicKeyToken=91d62ebb5b0d1b1b
MetaDataPackageLoader=TDBXMySqlMetaDataCommandFactory,DbxMySQLDriver160.bpl
MetaDataAssemblyLoader=Borland.Data.TDBXMySqlMetaDataCommandFactory,Borland.Data.DbxMySQLDriver,Version=16.0.0.0,Culture=neutral,PublicKeyToken=91d62ebb5b0d1b1b
GetDriverFunc=getSQLDriverMYSQL
LibraryName=dbxmys.dll
LibraryNameOsx=libsqlmys.dylib
VendorLib=LIBMYSQL.dll
VendorLibWin64=libmysql.dll
VendorLibOsx=libmysqlclient.dylib
HostName=localhost
Database=planetar
User_Name=root
Password=root
MaxBlobSize=-1
LocaleCode=0000
Compressed=False
Encrypted=False
BlobSize=-1
ErrorResourceFile=
}

type
  TDataAccessDataset = class(TDataAccessCustomDataset)
  private var
    FDataset: TSQLQuery;
    FContinue: Boolean;
  public
    constructor Create(AConnection: TSQLConnection);
    destructor Destroy(); override;
    function Call(const AStoredName: string; const AParams: array of const): TDataAccessCustomDataset; override;
    function ReadRow(): Boolean; override;
    function ReadInteger(const AFieldName: string): Integer; override;
    function ReadString(const AFieldName: string): string; override;
    function ReadDateTime(const AFieldName: string): TDateTime; override;
  end;

  TDataAccessConnection = class(TDataAccessCustom)
  private var
    FConnection: TSQLConnection;
  public
    constructor Create();
    destructor Destroy(); override;
    procedure Connect(); override;
    procedure Disconnect(); override;
    function Call(const AStoredName: string; const AParams: array of const): TDataAccessCustomDataset; override;
  end;

implementation

constructor TDataAccessConnection.Create();
begin
  inherited;
  FConnection := TSQLConnection.Create(nil);
  FConnection.DriverName := 'MySQL';
  FConnection.Params.LoadFromFile('..\..\db.txt');
end;

destructor TDataAccessConnection.Destroy();
begin
  FreeAndNil(FConnection);
end;

procedure TDataAccessConnection.Connect();
begin
  FConnection.Connected := True;
end;

procedure TDataAccessConnection.Disconnect();
begin
  FConnection.Connected := False;
end;

function TDataAccessConnection.Call(const AStoredName: string;
  const AParams: array of const): TDataAccessCustomDataset;
begin
  Result := TDataAccessDataset.Create(FConnection);
  Result.Call(AStoredName, AParams);
end;

constructor TDataAccessDataset.Create(AConnection: TSQLConnection);
begin
  inherited Create();
  FDataset := TSQLQuery.Create(nil);
  FDataset.SQLConnection := AConnection;
end;

destructor TDataAccessDataset.Destroy();
begin
  FreeAndNil(FDataset);
  inherited;
end;

function TDataAccessDataset.Call(const AStoredName: string;
  const AParams: array of const): TDataAccessCustomDataset;
begin
  FDataset.SQL.Text := 'Call ' + AStoredName;
  FDataset.Open();
  Result := Self;
end;

function TDataAccessDataset.ReadRow(): Boolean;
begin
  if (FContinue) then
    FDataset.Next();
  Result := FDataset.Eof;
end;

function TDataAccessDataset.ReadDateTime(const AFieldName: string): TDateTime;
begin
  Result := FDataset.FieldByName(AFieldName).AsDateTime;
end;

function TDataAccessDataset.ReadInteger(const AFieldName: string): Integer;
begin
  Result := FDataset.FieldByName(AFieldName).AsInteger;
end;

function TDataAccessDataset.ReadString(const AFieldName: string): string;
begin
  Result := FDataset.FieldByName(AFieldName).AsString;
end;

end.
