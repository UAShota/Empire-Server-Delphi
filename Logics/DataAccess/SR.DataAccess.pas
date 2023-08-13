{**********************************************}
{                                              }
{ Контроллер управления доступом к БД          }
{ Copyright (c) 2016 UAShota                    }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.DataAccess;

interface

uses
  System.SysUtils,

  SR.Globals.Log,
  SR.DataAccess.Custom,
  SR.DataAccess.FireDac;

type
  // Модуль управления доступа к БД
  TDataAccess = class
  private class var
    // Коннектор
    FInstance: TDataAccessCustom;
  public
    // Старт
    class procedure Start();
    // Остановка
    class procedure Stop();
    // Вызов хранимой процедуры с параметрами
    class function Call(const AStoredName: string; const AParams: array of const): TDataAccessCustomDataset; overload;
    // Вызов хранимой процедуры без параметров
    class function Call(const AStoredName: string): TDataAccessCustomDataset; overload;
  end;

implementation

class procedure TDataAccess.Start();
begin
  try
    FInstance := TDataAccessConnection.Create();
    FInstance.Connect();
  except
    on E: Exception do
      TLogAccess.Write(E, True);
  end;
end;

class procedure TDataAccess.Stop();
begin
  try
    FInstance.Disconnect();
    FreeAndNil(FInstance);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class function TDataAccess.Call(const AStoredName: string;
  const AParams: array of const): TDataAccessCustomDataset;
begin
  Result := nil;
  try
    Result := FInstance.Call(AStoredName, AParams);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class function TDataAccess.Call(const AStoredName: string): TDataAccessCustomDataset;
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
