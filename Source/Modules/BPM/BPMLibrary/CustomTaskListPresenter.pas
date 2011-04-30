unit CustomTaskListPresenter;

interface
uses CustomContentPresenter, classes, CoreClasses, ShellIntf, SysUtils, db,
  CommonViewIntf, Variants, EntityServiceIntf, BPMConst, ReportServiceIntf,
  Controls, CustomTaskItemPresenter, ViewServiceIntf;

const
  Command_ChangeState_Auto = '{59D529B3-E650-46A8-9428-FB5487478232}';
  Command_ChangeState_Started = '{A4CD6372-01FA-4C7F-9246-44C31698F15F}';
  Command_ChangeState_Suspended = '{B9AE060C-AC0C-4055-A0E6-BF7D60428001}';
  Command_ChangeState_Finished = '{62B2471C-E306-4B35-A57E-488DFD31782B}';

  Command_PrintTask = '{98E71B26-DE68-47AE-A35E-C8F6B007CFCC}';
  Command_ExecutorSet = '{5BF195D4-8B8B-4301-A912-6189AB1AB520}';
  Command_ExecutorClear = '{4446F39E-1BA8-4653-810E-7DB876D72107}';
//  Command_OpenTask = '{73D6CFD5-E757-4453-9E64-E6ADFA7C7258}';
//  Command_OpenTaskByID = '{1119D3A9-3CD5-421F-B782-61A21DA6BE7A}';
//  Command_OpenTaskByDataNum = '{05216C4C-9F5D-4EAB-AC11-4D7A4E08DD01}';

type
  ICustomTaskListView = interface(IContentView)
  ['{3258CF87-43D8-4150-BABC-FC093281D041}']
    procedure LinkData(AData: TDataSet);
    function Tabs: ITabs;
    function Selection: ISelection;
  end;

  TCustomTaskListPresenter = class(TCustomContentPresenter)
  private
    FLaneCode: string;
    FAutoPrintTask: boolean;
    procedure ViewSelectionChangedHandler;
    procedure ViewStateTabChangedHandler;

    procedure CmdReload(Sender: TObject);
    procedure CmdOpenTask(Sender: TObject);
    procedure CmdChangeState(Sender: TObject);
    procedure CmdPrintTask(Sender: TObject);
    procedure CmdExecutorSet(Sender: TObject);
    procedure CmdExecutorClear(Sender: TObject);

  protected
    function OnGetWorkItemState(const AName: string): Variant; override;
    function GetSelectedIDList: Variant;
    function View: ICustomTaskListView;
    //������ ���������� �������� �� �� (BPM_LANES.ID)
    function GetLaneID: Variant; virtual; abstract;

    //���������� �������� �� �� (BPM_LANES.CODE)
    function GetLaneCode: string;

    // ID ������ ������������� �� �������� "������ ������"
    // ��� ������������� ��������������
    // �� ���������: 'reports.bpm.' + GetLaneCode + '.task';
    function GetTaskReportID: string; virtual;

    // ������������ EntityView ��� ������ ������
    function GetEVListName: string; virtual;

    function GetStateID: Integer;
    function GetEVList: IEntityView;
    function GetUseDateRange: integer;
    function GetOnlyUpdated: integer;

    procedure TaskListReload;
    procedure TaskListPrint(AIDList: Variant; AutoPrint: boolean);

    procedure DoViewReady; override;
    procedure DoSelectionChanged;
    procedure OnSelectionChanged; virtual;
    procedure DoStateTabChanged;
    procedure OnViewValueChanged(const AName: string); override;

    procedure OnAfterChangeState(OldState, NewState: Integer; ATaskIDList: Variant); virtual;
  end;

implementation


{ TCustomTaskListPresenter }



function TCustomTaskListPresenter.GetStateID: Integer;
begin
  case View.Tabs.Active of
    0: Result := TASK_STATE_MONITOR;
    1: Result := TASK_STATE_NEW;
    2: Result := TASK_STATE_STARTED;
    3: Result := TASK_STATE_SUSPENDED;
    4: Result := TASK_STATE_FINISHED;
    5: Result := TASK_STATE_CANCELED;
    else
      raise Exception.Create('Task''s state unknown');
  end;
end;

function TCustomTaskListPresenter.GetEVList: IEntityView;
begin
  Result := App.Entities[ENT_BPM_TASK].GetView(GetEVListName, WorkItem);
end;


procedure TCustomTaskListPresenter.DoViewReady;
begin

  FAutoPrintTask := true;

  View.Tabs.Add('�����������');
  View.Tabs.Add('�����');
  View.Tabs.Add('�����������');
  View.Tabs.Add('����������');
  View.Tabs.Add('�����������');
  View.Tabs.Add('����������');
  View.Tabs.Active := 1;

  WorkItem.Commands[COMMAND_CLOSE].Caption := COMMAND_CLOSE_CAPTION;
  WorkItem.Commands[COMMAND_CLOSE].ShortCut := COMMAND_CLOSE_SHORTCUT;
  WorkItem.Commands[COMMAND_CLOSE].SetHandler(CmdClose);
  (GetView as IContentView).CommandBar.AddCommand(COMMAND_CLOSE);

  WorkItem.Commands[COMMAND_RELOAD].Caption := COMMAND_RELOAD_CAPTION;
  WorkItem.Commands[COMMAND_RELOAD].ShortCut := COMMAND_RELOAD_SHORTCUT;
  WorkItem.Commands[COMMAND_RELOAD].SetHandler(CmdReload);
  (GetView as IContentView).CommandBar.AddCommand(COMMAND_RELOAD);

  WorkItem.Commands[COMMAND_OPEN].Caption := COMMAND_OPEN_CAPTION;
  WorkItem.Commands[COMMAND_OPEN].ShortCut := COMMAND_OPEN_SHORTCUT;
  WorkItem.Commands[COMMAND_OPEN].SetHandler(CmdOpenTask);
  (GetView as IContentView).CommandBar.AddCommand(COMMAND_OPEN);

  WorkItem.Commands[Command_ChangeState_Auto].Caption := '������� ��������� (����)';
  WorkItem.Commands[Command_ChangeState_Auto].SetHandler(CmdChangeState);
  (GetView as IContentView).CommandBar.AddCommand(Command_ChangeState_Auto, '������� ���������', true);

  WorkItem.Commands[Command_ChangeState_Started].Caption := '������� ��������� (����������)';
  WorkItem.Commands[Command_ChangeState_Started].SetHandler(CmdChangeState);
  (GetView as IContentView).CommandBar.AddCommand(Command_ChangeState_Started, '������� ���������');

  WorkItem.Commands[Command_ChangeState_Suspended].Caption := '������� ��������� (��������)';
  WorkItem.Commands[Command_ChangeState_Suspended].SetHandler(CmdChangeState);
  (GetView as IContentView).CommandBar.AddCommand(Command_ChangeState_Suspended, '������� ���������');

  WorkItem.Commands[Command_ChangeState_Finished].Caption := '������� ��������� (���������)';
  WorkItem.Commands[Command_ChangeState_Finished].SetHandler(CmdChangeState);
  (GetView as IContentView).CommandBar.AddCommand(Command_ChangeState_Finished, '������� ���������');

  WorkItem.Commands[Command_PrintTask].Caption := '������ ������';
  WorkItem.Commands[Command_PrintTask].SetHandler(CmdPrintTask);
  (GetView as IContentView).CommandBar.AddCommand(Command_PrintTask, '������', true);
  
  WorkItem.Commands[Command_ExecutorSet].Caption := '��������� �����������';
  WorkItem.Commands[Command_ExecutorSet].SetHandler(CmdExecutorSet);
  (GetView as IContentView).CommandBar.AddCommand(Command_ExecutorSet, '������ ��������');

  WorkItem.Commands[Command_ExecutorClear].Caption := '��������� �����������';
  WorkItem.Commands[Command_ExecutorClear].SetHandler(CmdExecutorClear);
  (GetView as IContentView).CommandBar.AddCommand(Command_ExecutorClear, '������ ��������');


  View.Value['DBEG'] := Date;
  View.Value['DEND'] := Date;

  View.ValueStatus['DBEG'] := vsDisabled;
  View.ValueStatus['DEND'] := vsDisabled;


 // View.LinkDataSet('Main', GetEVList.DataSet);
  (View as ICustomTaskListView).LinkData(GetEVList.DataSet);
  inherited;


  View.Selection.SetSelectionChangedHandler(ViewSelectionChangedHandler);
  View.Tabs.SetTabChangedHandler(ViewStateTabChangedHandler);
  
  ViewStateTabChangedHandler;
  ViewSelectionChangedHandler;
end;

procedure TCustomTaskListPresenter.TaskListReload;
begin
  GetEVList.Load([GetLaneID, GetStateID, View.Value['DBEG'], View.Value['DEND'], GetUseDateRange, GetOnlyUpdated]);
end;

procedure TCustomTaskListPresenter.OnViewValueChanged(const AName: string);
begin
  if SameText(AName, 'DBEG') or SameText(AName, 'DEND') then
    TaskListReload;
end;

procedure TCustomTaskListPresenter.DoSelectionChanged;
var
  IsSelected: boolean;
begin

  IsSelected := View.Selection.Count <> 0;

  SetCommandStatus(Command_ChangeState_Auto,
    IsSelected and
    (GetStateID in [TASK_STATE_NEW, TASK_STATE_STARTED, TASK_STATE_SUSPENDED]));

  SetCommandStatus(Command_ChangeState_Started,
    IsSelected and
    (GetStateID in [TASK_STATE_NEW, TASK_STATE_SUSPENDED]));

  SetCommandStatus(Command_ChangeState_Suspended,
    IsSelected and
    (GetStateID in [TASK_STATE_NEW, TASK_STATE_STARTED]));

  SetCommandStatus(Command_ChangeState_Finished,
    IsSelected and
    (GetStateID in [TASK_STATE_NEW, TASK_STATE_STARTED, TASK_STATE_SUSPENDED]));

  SetCommandStatus(Command_PrintTask,IsSelected);

  SetCommandStatus(Command_Open,IsSelected);

  SetCommandStatus(Command_ExecutorSet,IsSelected);

  SetCommandStatus(Command_ExecutorClear,IsSelected);
    
  OnSelectionChanged;


end;

procedure TCustomTaskListPresenter.CmdChangeState(Sender: TObject);
var
  cmd: ICommand;
  I: integer;
  NewStateID: integer;
  StateChanged: integer;
  IDList: Variant;
begin

  Sender.GetInterface(ICommand, cmd);
  if cmd.Name = command_ChangeState_Auto then
    NewStateID := -1
  else if cmd.Name = command_ChangeState_Started then
    NewStateID := TASK_STATE_STARTED
  else if cmd.Name = command_ChangeState_Suspended then
    NewStateID := TASK_STATE_SUSPENDED
  else if cmd.Name = command_ChangeState_Finished then
    NewStateID := TASK_STATE_FINISHED
  else
    NewStateID := -1;

  if not App.Views.MessageBox.ConfirmYesNo('������� ������� ��������� ?') then Exit;

  try
    IDList := VarArrayCreate([0, View.Selection.Count - 1], varVariant);
    for I := 0 to View.Selection.Count - 1 do
    begin
      StateChanged := App.Entities[ENT_BPM_TASK].
        GetOper(ENT_BPM_TASK_OPER_STATE_CHANGE, WorkItem).
          Execute([View.Selection[I], NewStateID])['STATE_CHANGED'];
      if StateChanged = 1 then
        IDList[I] := View.Selection.Items[I];

    end;
  finally
    TaskListReload;
  end;

  OnAfterChangeState(GetStateID, NewStateID, IDList);
end;

procedure TCustomTaskListPresenter.DoStateTabChanged;
begin
  if GetUseDateRange = 1 then
  begin
    View.ValueStatus['DBEG'] := vsEnabled;
    View.ValueStatus['DEND'] := vsEnabled;
  end
  else
  begin
    View.ValueStatus['DBEG'] := vsDisabled;
    View.ValueStatus['DEND'] := vsDisabled;
  end;

  inherited;

  TaskListReload;
end;


procedure TCustomTaskListPresenter.CmdPrintTask(Sender: TObject);
begin
  TaskListPrint(GetSelectedIDList, false);
end;

function TCustomTaskListPresenter.GetTaskReportID: string;
begin
  Result := 'reports.bpm.' + GetLaneCode + '.task';
end;

function TCustomTaskListPresenter.GetLaneCode: string;
begin
  if FLaneCode = '' then
    FLaneCode := App.Entities[ENT_BPM_LANE].
      GetOper(ENT_BPM_LANE_OPER_GET_CODE, WorkItem).
        Execute([GetLaneID])['CODE'];
  Result := FLaneCode;
end;

function TCustomTaskListPresenter.GetEVListName: string;
begin
  Result := 'ListDefault';
end;

procedure TCustomTaskListPresenter.CmdExecutorSet(Sender: TObject);
var
  I: integer;
  _action: IAction;
  _actionData: TPresenterData;
begin
  _action := WorkItem.Actions[ACT_BPM_EXECUTOR_SELECT];
  _actionData := _action.Data as TPresenterData;
  _action.Execute(WorkItem);

  if _actionData.ModalResult = mrOk then
  begin
    for I := 0 to View.Selection.Count - 1 do
    begin
      App.Entities[ENT_BPM_TASK].
          GetOper(ENT_BPM_TASK_OPER_EXECUTOR_ADD, WorkItem).
            Execute([View.Selection[I], _actionData['ID']]);
      GetEVList.ReloadRecord(View.Selection[I]);
    end;
  end;

{  with WorkItem.Actions[ACT_BPM_EXECUTOR_SELECT] do
  begin
    DataIn['TASK_ID'] := View.Selection.First;
    Execute(WorkItem);
    selectAction := DataOut['SelectViewAction'];
    _listID := DataOut['SelectViewID'];
  end;

  if (selectAction = svaOK) and VarIsArray(_listID) then
  begin
    for I := 0 to View.Selection.Count - 1 do
      for Y := 0 to VarArrayHighBound(_listID, 1) do
      begin
        App.Entities[ENT_BPM_TASK].
          GetOper(ENT_BPM_TASK_OPER_EXECUTOR_ADD, WorkItem).
            Execute([View.Selection[I], _listID[Y]]);
        GetEVList.ReloadRecord(View.Selection[I]);
      end;
  end
  else if selectAction = svaClear then
  begin
    for I := 0 to View.Selection.Count - 1 do
     begin
       App.Entities[ENT_BPM_TASK].
          GetOper(ENT_BPM_TASK_OPER_EXECUTOR_REMOVE, WorkItem).
            Execute([View.Selection[I], -1]);
        GetEVList.ReloadRecord(View.Selection[I]);
     end;
  end;
 }
end;

procedure TCustomTaskListPresenter.CmdOpenTask(Sender: TObject);
var
  action: IAction;
begin
  action := WorkItem.Actions[ACT_BPM_TASK_ITEM_OPEN];
  (action.Data as TTaskItemPresenterData).ID := WorkItem.State['ID'];
  action.Execute(WorkItem);
end;

procedure TCustomTaskListPresenter.OnAfterChangeState(OldState, NewState: Integer;
  ATaskIDList: Variant);
begin
  if FAutoPrintTask and (OldState = TASK_STATE_NEW) and
    ((NewState = TASK_STATE_STARTED) or (NewState = -1))   then
    TaskListPrint(ATaskIDList, true);
end;

procedure TCustomTaskListPresenter.TaskListPrint(AIDList: Variant; AutoPrint: boolean);
var
  I: integer;
  _count: integer;
  _rptData: TDataSet;
  _rptID: string;
begin
  _count := VarArrayHighBound(AIDList, 1);

  for I := 0 to _count do
  begin
    _rptData := App.Entities.Entity[ENT_BPM_TASK].
      GetOper(ENT_BPM_TASK_OPER_REPORTS_GET, WorkItem).Execute([AIDList[I]]);

    while not _rptData.Eof do
    begin
      _rptID := _rptData['Report_ID'];
      App.Reports.Report[_rptID].Params['ID'] := VarToStr(AIDList[I]);
      App.Reports.Report[_rptID].Params['OutCode'] := _rptData['Out_Code'];

      if _count = 0 then
        App.Reports.Report[_rptID].Execute(WorkItem, reaExecute)
      else if I = 0 then
        App.Reports.Report[_rptID].Execute(WorkItem, reaPrepareFirst)
      else if I = _count then
        App.Reports.Report[_rptID].Execute(WorkItem, reaExecutePrepared)
      else
        App.Reports.Report[_rptID].Execute(WorkItem, reaPrepareNext);

      _rptData.Next;
    end;

  end;
end;

function TCustomTaskListPresenter.GetUseDateRange: integer;
begin
  if GetStateID in [TASK_STATE_FINISHED, TASK_STATE_CANCELED] then
    Result := 1
  else
    Result := 0;
end;

function TCustomTaskListPresenter.GetOnlyUpdated: integer;
begin
  if GetStateID in [TASK_STATE_MONITOR] then
    Result := 1
  else
    Result := 0;

end;


procedure TCustomTaskListPresenter.CmdExecutorClear(Sender: TObject);
var
  I: integer;
begin
  for I := 0 to View.Selection.Count - 1 do
  begin
    App.Entities[ENT_BPM_TASK].
      GetOper(ENT_BPM_TASK_OPER_EXECUTOR_REMOVE, WorkItem).
         Execute([View.Selection[I], -1]);
    GetEVList.ReloadRecord(View.Selection[I]);
  end;
end;


function TCustomTaskListPresenter.View: ICustomTaskListView;
begin
  Result := GetView as ICustomTaskListView;
end;

procedure TCustomTaskListPresenter.ViewSelectionChangedHandler;
begin

  DoSelectionChanged;

end;

procedure TCustomTaskListPresenter.ViewStateTabChangedHandler;
begin

  DoStateTabChanged;

end;

function TCustomTaskListPresenter.GetSelectedIDList: Variant;
var
  I: integer;
begin
  if View.Selection.Count > 0 then
  begin
    Result := VarArrayCreate([0, View.Selection.Count - 1], varVariant);
    for I := 0 to View.Selection.Count - 1 do
      Result[I] := View.Selection.Items[I];
  end
  else
    Result := Unassigned;

end;

procedure TCustomTaskListPresenter.OnSelectionChanged;
begin

end;

procedure TCustomTaskListPresenter.CmdReload(Sender: TObject);
begin
  GetEVList.Reload;
end;

function TCustomTaskListPresenter.OnGetWorkItemState(
  const AName: string): Variant;
var
  I: integer;
begin
  if SameText(AName, 'ID') then
    Result := View.Selection.First
  else if SameText(AName, 'IDList') then
  begin
    Result := '';
    for I := 0 to View.Selection.Count - 1 do
      if Result = '' then
        Result := VarToStr(View.Selection[I])
      else
        Result := Result + ';' + VarToStr(View.Selection[I]);
  end
  else if SameText(Result, 'IDList2') then
  begin
    Result := '';
    for I := 0 to View.Selection.Count - 1 do
      if Result = '' then
        Result := VarToStr(View.Selection[I])
      else
        Result := Result + ',' + VarToStr(View.Selection[I]);
  end
  else

    Result := inherited OnGetWorkItemState(AName);

end;

end.
