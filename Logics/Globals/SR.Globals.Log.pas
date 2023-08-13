{**********************************************}
{                                              }
{ Модуль управления подсистемой логирования    }
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
  // Класс управления подсистемой логирования
  TLogAccess = class
  private const
    // Каталог логов
    S_LOG_DIR = 'logs';
    // Расширение файла лога
    S_LOG_EXT = '.log';
    // Формат имени лога
    S_LOG_NAME = 'yyyymmdd_hhmmss';
    // Событие запуска логирования
    S_LOG_INIT = 'Log init';
    // Событие завершения логирования
    S_LOG_DONE = 'Log done';
  private class var
    // Файл лога
    FText: TextFile;
  private
    // Инициализация синглтона
    class procedure Init(); static;
    // Фиинализация синглтона
    class procedure Done(); static;
  public
    // Запись кастомного сообщения
    class procedure Write(const AClassName, AMessage: string); overload; static;
    // Запись исключения
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
