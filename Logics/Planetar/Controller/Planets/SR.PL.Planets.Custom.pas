{**********************************************}
{                                              }
{ Планетоиды : общие функции                   }
{ Copyright (c) 2016 UAshota                   }
{                                              }
{                                              }
{**********************************************}
unit SR.PL.Planets.Custom;

interface

uses
  System.SysUtils,
  System.Math,

  SR.Globals.Log,
  SR.Globals.Player,
  SR.Planetar.Classes;

type
  // Класс обработки общих функций флота
  TPLPlanetsControlCustom = class
  protected var
    // Объект планетарной системы
    Engine: TObject;
  public
    // Создание контроллера для указанного созвездия
    constructor Create(AEngine: TObject); virtual;
  end;

implementation

constructor TPLPlanetsControlCustom.Create(AEngine: TObject);
begin
  inherited Create();

  Engine := AEngine;
end;

end.
