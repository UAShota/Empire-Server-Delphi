{**********************************************}
{                                              }
{ Базовый модуль оперативных модулей           }
{ Copyright (c) 2016 UAShota                   }
{                                              }
{ Rev A  2016.12.14                            }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Planetar.Custom;

interface

uses
  System.SysUtils,

  SR.Globals.Log;

type
  // Базовый класс оперативных модулей
  TPlanetarCustom = class
  protected var
    // Объект планетарной системы
    Engine: TObject;
  public
    // Создание контроллера для указанного созвездия
    constructor Create(AEngine: TObject); virtual;
    // Вызов процедуры работы класса
    procedure Start(); virtual;
    // Вызов процедуры работы класса
    procedure Work(); virtual;
  end;

implementation

uses
  SR.Planetar.Thread;

constructor TPlanetarCustom.Create(AEngine: TObject);
begin
  try
    Engine := AEngine;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

procedure TPlanetarCustom.Start();
begin
  raise Exception.Create('Not a start method');
end;

procedure TPlanetarCustom.Work();
begin
  raise Exception.Create('Not a work method');
end;

end.
