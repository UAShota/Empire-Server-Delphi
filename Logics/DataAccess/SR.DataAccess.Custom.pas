{**********************************************}
{                                              }
{ ����������� ������ ���������� �������� � ��  }
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
  // �������, ����������� �������
  TDataAccessCustomDataset = class abstract
  public
    // ����� �������� ���������
    function Call(const AStoredName: string; const AParams: array of const): TDataAccessCustomDataset; overload; virtual; abstract;
    // ������ ��������� ������
    function ReadRow(): Boolean; virtual; abstract;
    // ������� �������� ��� Integer
    function ReadInteger(const AFieldName: string): Integer; virtual; abstract;
    // ������� �������� ��� String
    function ReadString(const AFieldName: string): string; virtual; abstract;
    // ������� �������� ��� DateTime
    function ReadDateTime(const AFieldName: string): TDateTime; virtual; abstract;
  end;

  // ��������� � ��
  TDataAccessCustom = class abstract
  protected const
    S_USERNAME = 'root';
    S_PWD = 'root';
    S_DATABASE = 'planetar';
  public
    // ����������
    procedure Connect(); virtual; abstract;
    // ������������
    procedure Disconnect(); virtual; abstract;
    // ����� �������� ��������� � �����������
    function Call(const AStoredName: string; const AParams: array of const): TDataAccessCustomDataset; overload; virtual; abstract;
    // ����� �������� ��������� ��� ����������
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
