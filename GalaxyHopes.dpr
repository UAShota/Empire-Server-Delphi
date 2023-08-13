program GalaxyHopes;

uses
  madExcept,
  Winapi.Windows,
  System.SysUtils,
  SR.DataAccess.Custom in 'Logics\DataAccess\SR.DataAccess.Custom.pas',
  SR.DataAccess in 'Logics\DataAccess\SR.DataAccess.pas',
  SR.DataAccess.FireDac in 'Logics\DataAccess\SR.DataAccess.FireDac.pas',
  SR.DataAccess.DBX in 'Logics\DataAccess\SR.DataAccess.DBX.pas',
  SR.Globals.Types in 'Logics\Globals\SR.Globals.Types.pas',
  SR.Globals.Player in 'Logics\Globals\Classes\SR.Globals.Player.pas',
  SR.Globals.Dictionaries in 'Logics\Globals\Classes\SR.Globals.Dictionaries.pas',
  SR.Globals.Log in 'Logics\Globals\SR.Globals.Log.pas',
  SR.Engine.Server in 'Logics\Engine\SR.Engine.Server.pas',
  SR.Engine.Galaxy in 'Logics\Engine\SR.Engine.Galaxy.pas',
  SR.Engine.Planetar in 'Logics\Engine\SR.Engine.Planetar.pas',
  SR.Transport.Custom in 'Logics\Transport\SR.Transport.Custom.pas',
  SR.Transport.Indy in 'Logics\Transport\SR.Transport.Indy.pas',
  SR.Transport in 'Logics\Transport\SR.Transport.pas',
  SR.Transport.Buffer in 'Logics\Transport\SR.Transport.Buffer.pas',
  SR.Planetar.Custom in 'Logics\Planetar\Engine\SR.Planetar.Custom.pas',
  SR.Planetar.Dictionary in 'Logics\Planetar\Engine\SR.Planetar.Dictionary.pas',
  SR.Planetar.Profile in 'Logics\Planetar\Engine\SR.Planetar.Profile.pas',
  SR.Planetar.Thread in 'Logics\Planetar\Engine\SR.Planetar.Thread.pas',
  SR.Planetar.Classes in 'Logics\Planetar\Engine\SR.Planetar.Classes.pas',
  SR.Planetar.Socket.Reader in 'Logics\Planetar\Protocol\SR.Planetar.Socket.Reader.pas',
  SR.Planetar.Socket.Writer in 'Logics\Planetar\Protocol\SR.Planetar.Socket.Writer.pas',
  SR.Planetar.Worker.Ships in 'Logics\Planetar\Workers\SR.Planetar.Worker.Ships.pas',
  SR.Planetar.Worker.Planet in 'Logics\Planetar\Workers\SR.Planetar.Worker.Planet.pas',
  SR.Planetar.Controller.Buildings in 'Logics\Planetar\Controller\SR.Planetar.Controller.Buildings.pas',
  SR.Planetar.Controller.Storage in 'Logics\Planetar\Controller\SR.Planetar.Controller.Storage.pas',
  SR.Planetar.Controller.Ships in 'Logics\Planetar\Controller\SR.Planetar.Controller.Ships.pas',
  SR.Planetar.Controller.Planets in 'Logics\Planetar\Controller\SR.Planetar.Controller.Planets.pas',
  SR.PL.Ships.AddToPlanet in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.AddToPlanet.pas',
  SR.PL.Ships.Annihilation in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Annihilation.pas',
  SR.PL.Ships.Attach in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Attach.pas',
  SR.PL.Ships.Capture in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Capture.pas',
  SR.PL.Ships.ChangeActivity in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.ChangeActivity.pas',
  SR.PL.Ships.Fly in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Fly.pas',
  SR.PL.Ships.Construct in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Construct.pas',
  SR.PL.Ships.Custom in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Custom.pas',
  SR.PL.Ships.Destruct in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Destruct.pas',
  SR.PL.Ships.Escape in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Escape.pas',
  SR.PL.Ships.Fuel in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Fuel.pas',
  SR.PL.Ships.Group in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Group.pas',
  SR.PL.Ships.Hypodispersion in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Hypodispersion.pas',
  SR.PL.Ships.JumpToPlanet in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.JumpToPlanet.pas',
  SR.PL.Ships.Merge in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Merge.pas',
  SR.PL.Ships.MoveFromHangar in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.MoveFromHangar.pas',
  SR.PL.Ships.MoveToHangar in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.MoveToHangar.pas',
  SR.PL.Ships.MoveToPlanet in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.MoveToPlanet.pas',
  SR.PL.Ships.RemoveFromPlanet in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.RemoveFromPlanet.pas',
  SR.PL.Ships.Repair in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Repair.pas',
  SR.PL.Ships.Retarget in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Retarget.pas',
  SR.PL.Ships.Separate in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Separate.pas',
  SR.PL.Ships.StandDown in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.StandDown.pas',
  SR.PL.Ships.StandUp in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.StandUp.pas',
  SR.PL.Ships.TargetLocal in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.TargetLocal.pas',
  SR.PL.Ships.TargetMarker in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.TargetMarker.pas',
  SR.PL.Ships.Portal in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Portal.pas',
  SR.PL.Ships.Skill.Construct in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Skill.Construct.pas',
  SR.PL.Planets.Battle in 'Logics\Planetar\Controller\Planets\SR.PL.Planets.Battle.pas',
  SR.PL.Ships.Battle in 'Logics\Planetar\Controller\Ships\SR.PL.Ships.Battle.pas',
  SR.PL.Planets.Custom in 'Logics\Planetar\Controller\Planets\SR.PL.Planets.Custom.pas',
  SR.PL.Planets.Pulsar in 'Logics\Planetar\Controller\Planets\SR.PL.Planets.Pulsar.pas',
  SR.PL.Planets.Capture in 'Logics\Planetar\Controller\Planets\SR.PL.Planets.Capture.pas',
  SR.PL.Planets.Wormhole in 'Logics\Planetar\Controller\Planets\SR.PL.Planets.Wormhole.pas',
  SR.Planetar.Hangar in 'Logics\Planetar\Engine\SR.Planetar.Hangar.pas';

{$APPTYPE CONSOLE}
{$SETPEFLAGS $0001}
{$WEAKLINKRTTI ON}
{$RTTI EXPLICIT METHODS([]) PROPERTIES([]) FIELDS([])}

var
  s: string;
  TmpTime: UInt64;

begin
  TmpTime := GetTickCount64;

  Randomize();  Randomize();  Randomize();

  TEngineServer.Start();

  TLogAccess.Write('TEngineServer', Format(' #1 ticks %d', [GetTickCount64() - TmpTime]));

  repeat
    Readln(s);
    if (s<>'s') then
      Writeln('> unknown command');
  until s = 's';

  TEngineServer.Stop();
end.


