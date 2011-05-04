unit ShellApp;

interface
uses bfwShellApp, classes;

type
  TShellApp = class(TApp)
  protected
    procedure AddServices; override;
  end;

implementation

{ TShellApp }

procedure TShellApp.AddServices;
begin
  inherited;
end;

end.
