{**********************************************}
{                                              }
{ ������ ���������� ����������� �����������    }
{ Copyright (c) 2016 UAShota                    }
{                                              }
{ Rev D  2018.03.13                            }
{                                              }
{**********************************************}
unit SR.Globals.Log;

interface

uses
  System.SysUtils,
  System.Classes;

type
  // ����� ���������� ����������� �����������
  TLogAccess = class
  private const
    // ������� �����
    S_LOG_DIR = 'logs';
    // ���������� ����� ����
    S_LOG_EXT = '.log';
    // ������ ����� ����
    S_LOG_NAME = 'yyyymmdd_hhmmss';
    // ������� ������� �����������
    S_LOG_INIT = 'Log init';
    // ������� ���������� �����������
    S_LOG_DONE = 'Log done';
  private class var
    // ���� ����
    FText: TextFile;
  private
    // ������������� ���������
    class procedure Init(); static;
    // ������������ ���������
    class procedure Done(); static;
  public
    // ������ ���������� ���������
    class procedure Write(const AClassName, AMessage: string); overload; static;
    // ������ ����������
    class procedure Write(AException: Exception; ACritical: Boolean = False); overload; static;
  end;

implementation

class procedure TLogAccess.Init();
var
  TmpDir: String;
begin
  TmpDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)) + S_LOG_DIR);
  if not ForceDirectories(TmpDir) then
  begin
    WriteLn(S_LOG_INIT);
    WriteLn(SysErrorMessage(GetLastError));
    WriteLn(TmpDir);
    Readln;
    Halt(GetLastError);
  end;
  try
    TmpDir := TmpDir + FormatDateTime(S_LOG_NAME, Now())+ S_LOG_EXT;
    AssignFile(FText, TmpDir);
    Rewrite(FText);
  except
    on E: Exception do
    begin
      WriteLn(S_LOG_INIT);
      WriteLn(E.Message);
      WriteLn(SysErrorMessage(GetLastError));
      WriteLn(TmpDir);
      Readln;
      Halt(GetLastError);
    end;
  end;
end;

class procedure TLogAccess.Done();
begin
  try
    CloseFile(FText);
  except
    on E: Exception do
    begin
      WriteLn('Log had error on done');
      Writeln(E.Message);
      Readln;
    end;
  end;
end;

class procedure TLogAccess.Write(const AClassName, AMessage: string);
begin
  try
    Writeln(FText, DateTimeToStr(Now), FormatSettings.ListSeparator, AClassName,
      FormatSettings.ListSeparator, AMessage);
    {$IFDEF DEBUG}
    Writeln(DateTimeToStr(Now), FormatSettings.ListSeparator, AClassName,
      FormatSettings.ListSeparator, AMessage);
    {$ENDIF}
    Flush(FText);
  except
    on E: Exception do
      WriteLn('Log error ' + E.Message + E.StackTrace);
  end;
end;

class procedure TLogAccess.Write(AException: Exception; ACritical: Boolean);
begin
  try
    Writeln(FText, DateTimeToStr(Now), FormatSettings.ListSeparator, AException.Message,
      FormatSettings.ListSeparator, AException.StackTrace);
    Writeln(DateTimeToStr(Now), FormatSettings.ListSeparator, AException.Message);
    if (ACritical) then
    begin
      Writeln('Critical crash, process is stopped, press return for exit');
      Readln;
      Halt(0);
    end;
  except
    on E: Exception do
      WriteLn('Log error ' + E.Message + E.StackTrace);
  end;
end;

initialization
  TLogAccess.Init();
finalization
  TLogAccess.Done();

end.
