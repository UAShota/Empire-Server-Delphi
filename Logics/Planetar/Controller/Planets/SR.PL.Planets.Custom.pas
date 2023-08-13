{**********************************************}
{                                              }
{ ���������� : ����� �������                   }
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
  // ����� ��������� ����� ������� �����
  TPLPlanetsControlCustom = class
  protected var
    // ������ ����������� �������
    Engine: TObject;
  public
    // �������� ����������� ��� ���������� ���������
    constructor Create(AEngine: TObject); virtual;
  end;

implementation

constructor TPLPlanetsControlCustom.Create(AEngine: TObject);
begin
  inherited Create();

  Engine := AEngine;
end;

end.
