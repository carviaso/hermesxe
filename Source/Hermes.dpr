program Hermes;

uses
  Forms,
  midaslib, //!!! �� ���� midas.dll
  ExtensionEnumerator in 'Shell\ExtensionEnumerator.pas',
  ShellApp in 'Shell\ShellApp.pas';

{$R *.res}

begin
 // Application.Initialize;   for enabled applicaion options

//  Application.MainFormOnTaskbar := True;
  ShellApp.TShellApp.ShellInstantiate;
end.
