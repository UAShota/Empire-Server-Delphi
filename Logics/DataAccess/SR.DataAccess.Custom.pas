{**********************************************}
{                                              }
{ Абстрактный модуль управления доступом к БД  }
{ Copyright (c) 2016 UAShota                    }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.DataAccess.Custom;

interface

uses
  System.SysUtils,

  SR.Globals.Log;

type
  // Датасет, выполняющий запросы
  TDataAccessCustomDataset = class abstract
  public
    // Вызов хранимой процедуры
    function Call(const AStoredName: string; const AParams: array of const): TDataAccessCustomDataset; overload; virtual; abstract;
    // Чтение очередной записи
    function ReadRow(): Boolean; virtual; abstract;
    // Возврат значения как Integer
    function ReadInteger(const AFieldName: string): Integer; virtual; abstract;
    // Возврат значения как String
    function ReadString(const AFieldName: string): string; virtual; abstract;
    // Возврат значения как DateTime
    function ReadDateTime(const AFieldName: string): TDateTime; virtual; abstract;
  end;

  // Коннектор к БД
  TDataAccessCustom = class abstract
  protected const
    S_USERNAME = 'root';
    S_PWD = 'root';
    S_DATABASE = 'planetar';
  public
    // Соединение
    procedure Connect(); virtual; abstract;
    // Отсоединение
    procedure Disconnect(); virtual; abstract;
    // Вызов хранимой процедуры с параметрами
    function Call(const AStoredName: string; const AParams: array of const): TDataAccessCustomDataset; overload; virtual; abstract;
    // Вызов хранимой процедуры без параметров
    function Call(const AStoredName: string): TDataAccessCustomDataset; overload;
  end;

implementation

function TDataAccessCustom.Call(const AStoredName: string): TDataAccessCustomDataset;
begin
  Result := nil;
  try
    Result := Call(AStoredName, []);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
