program Hermes;
uses
  Forms,
  ShellApp in 'Shell\ShellApp.pas',
  ExtensionEnumerator in 'Shell\ExtensionEnumerator.pas';

{$R *.res}

begin
  ShellApp.TShellApp.ShellInstantiate;
end.
