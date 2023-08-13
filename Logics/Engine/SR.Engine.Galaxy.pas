{**********************************************}
{                                              }
{ ������ ���������� ����������� ��������       }
{ Copyright (c) 2016 UAShota                    }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Engine.Galaxy;

interface

uses
  System.SysUtils,

  SR.Globals.Player,
  SR.Globals.Log;

type
  // ����� ���������� ����������� ��������
  TEngineGalaxy = class
  private const
    // ��� ������� ����� ���������
    CMD_SELECT_GALAXY = $2F00;
  private
    // �������� ����� ���������
    class procedure DoSelectGalaxy(AInfo: TGlPlayerInfo);
  public
    // ������ ������
    class procedure Start();
    // ��������� ������
    class procedure Stop();
    // ��������� �������� �������
    class procedure Process(AInfo: TGlPlayerInfo);
  end;

implementation

uses
  SR.Planetar.Profile,
  SR.Planetar.Thread;

class procedure TEngineGalaxy.DoSelectGalaxy(AInfo: TGlPlayerInfo);
begin
  try
    // ������ �������� � ���������� �������
    TPlanetarProfile(AInfo.Player.PlanetarProfile).Disconnect();
    // �������� ��������� ��� �������� ���������
    TPlanetarThread(TPlanetarProfile(AInfo.Player.PlanetarProfile).Subscribed).SocketWriter.GalaxyLoadAccept(AInfo.Player);
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEngineGalaxy.Process(AInfo: TGlPlayerInfo);
var
  TmpCommand: Integer;
begin
  { TODO -omdv : Galaxy �������� � ������ }
{  try
    TmpCommand := AInfo.ReadBuffer.ReadCommand();
    // �������� ����� ���� ����� ���� � ������� ����������
    case TmpCommand of
      CMD_SELECT_GALAXY:
        DoSelectGalaxy(AInfo);
    end;
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;}
end;

class procedure TEngineGalaxy.Start();
begin
  try
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

class procedure TEngineGalaxy.Stop();
begin
  try
  except
    on E: Exception do
      TLogAccess.Write(E);
  end;
end;

end.
