unit CustomTaskItemPresenter;

interface

uses classes, CoreClasses, CustomContentPresenter, ShellIntf, CommonViewIntf,
  Variants, BPMConst, EntityServiceIntf, db, ViewServiceIntf;

const
  strTaskUpdateProcessFinished = '���������� ������ ����������';

  VAL_TASK_LINKED_SELECTED = '{CCFE412F-0DC1-4E71-B20A-D445CBB6CCCE}';
  VAL_TASK_UPDATE_SELECTED = '{0E21A2FF-13F1-409D-8E1C-485E471F22AF}';
  Command_OpenTaskLinked = '{7A8321CB-0E33-4E63-BA59-3766CA536608}';
  Command_ProcessTaskUpdate = '{19BE8A84-624C-4A26-A551-7CA9E7EE8501}';

type
  ICustomTaskItemView = interface(IContentView)
  ['{7CB3BE2F-DEA9-4483-99B3-AFA8F6649B52}']
    procedure LinkData(Task, Data, DataRec, Links, Updates: TDataSet);
  end;

  TTaskItemPresenterData = class(TPresenterData)
  private
    FID: Variant;
    procedure SetID(const Value: Variant);
  published
    property ID: Variant read FID write SetID;
  end;

  TCustomTaskItemPresenter = class(TCustomContentPresenter)
  private
    procedure CmdTaskLinkedOpen(Sender: TObject);
    procedure CmdTaskUpdateProcess(Sender: TObject);
  protected
    procedure DoInitialize; override;
    procedure DoViewInitialize; override;
    procedure DoViewReady; override;
    function GetEntityName: string;
    function GetEntityViewName: string;
    function GetEVItem: IEntityView;

    function GetEVData: IEntityView; virtual;
    function GetEntityDataViewName: string; virtual;

    function GetEVDataRec: IEntityView; virtual;
    function GetEntityDataRecViewName: string; virtual;

    function GetEVLinks: IEntityView; virtual;
    function GetEntityLinksViewName: string; virtual;

    function GetEVUpdates: IEntityView; virtual;
    function GetEntityUpdatesViewName: string; virtual;
  public
    class function ExecuteDataClass: TActionDataClass; override;
  end;

implementation

{ TCustomTaskItemPresenter }


procedure TCustomTaskItemPresenter.CmdTaskLinkedOpen(Sender: TObject);
var
  _taskID: Variant;
  _action: IAction;
begin
  _taskID := GetView.Value[VAL_TASK_LINKED_SELECTED];
  if not VarIsEmpty(_taskID) then
  begin
    _action := WorkItem.Actions[ACT_BPM_TASK_ITEM_OPEN];
    (_action.Data as TTaskItemPresenterData).ID := _taskID;
    _action.Execute(WorkItem);
    _action := nil;
  end;
end;

procedure TCustomTaskItemPresenter.CmdTaskUpdateProcess(Sender: TObject);
var
  _taskID: Variant;
begin
  _taskID := GetView.Value[VAL_TASK_UPDATE_SELECTED];
  if not VarIsEmpty(_taskID) then
  begin
    App.Entities[ENT_BPM_TASK].
      GetOper(ENT_BPM_TASK_OPER_UPDATE_PROCESS, WorkItem).Execute(_taskID);
    GetEVUpdates.ReloadRecord(_taskID);
    App.Views.MessageBox.InfoMessage(strTaskUpdateProcessFinished);
  end;

end;

procedure TCustomTaskItemPresenter.DoInitialize;
begin
  inherited;
  WorkItem.State['TASK_ID'] := WorkItem.State['ID'];
  FreeOnViewClose := true;
end;

procedure TCustomTaskItemPresenter.DoViewInitialize;
begin
  ViewTitle := '������: ' + VarToStr(GetEVItem.Values['TASK_ID']);
  inherited;
end;

procedure TCustomTaskItemPresenter.DoViewReady;
begin


  (GetView as ICustomTaskItemView).LinkData(GetEVItem.DataSet, GetEVData.DataSet, GetEVDataRec.DataSet,
    GetEVLinks.DataSet, GetEVUpdates.DataSet);

  WorkItem.Commands[COMMAND_CLOSE].
    Init(COMMAND_CLOSE_CAPTION, COMMAND_CLOSE_SHORTCUT, CmdClose);
  (GetView as IContentView).CommandBar.AddCommand(COMMAND_CLOSE);


  WorkItem.Commands[Command_OpenTaskLinked].SetHandler(CmdTaskLinkedOpen);
  WorkItem.Commands[Command_ProcessTaskUpdate].SetHandler(CmdTaskUpdateProcess);


  inherited;

end;

class function TCustomTaskItemPresenter.ExecuteDataClass: TActionDataClass;
begin
  Result := TTaskItemPresenterData;
end;

function TCustomTaskItemPresenter.GetEntityDataRecViewName: string;
begin
  Result := '';
end;

function TCustomTaskItemPresenter.GetEntityDataViewName: string;
begin
  Result := ENT_BPM_TASK_VIEW_DATA;
end;

function TCustomTaskItemPresenter.GetEntityLinksViewName: string;
begin
  Result := ENT_BPM_TASK_VIEW_LINKS;
end;

function TCustomTaskItemPresenter.GetEntityName: string;
begin
  Result := ENT_BPM_TASK;
end;

function TCustomTaskItemPresenter.GetEntityUpdatesViewName: string;
begin
  Result := ENT_BPM_TASK_VIEW_UPDATES;
end;

function TCustomTaskItemPresenter.GetEntityViewName: string;
begin
  Result := ENT_BPM_TASK_VIEW_ITEM;
end;

function TCustomTaskItemPresenter.GetEVData: IEntityView;
begin
  Result := Self.GetEView(GetEntityName, GetEntityDataViewName);
end;

function TCustomTaskItemPresenter.GetEVDataRec: IEntityView;
begin
  if GetEntityDataRecViewName <> '' then
    Result := Self.GetEView(GetEntityName, GetEntityDataRecViewName)
  else
    Result := nil;
end;

function TCustomTaskItemPresenter.GetEVItem: IEntityView;
begin
  Result := Self.GetEView(GetEntityName, GetEntityViewName);
end;

function TCustomTaskItemPresenter.GetEVLinks: IEntityView;
begin
  Result := Self.GetEView(GetEntityName, GetEntityLinksViewName);
end;

function TCustomTaskItemPresenter.GetEVUpdates: IEntityView;
begin
  Result := Self.GetEView(GetEntityName, GetEntityUpdatesViewName);
end;


{ TTaskItemPresenterData }

procedure TTaskItemPresenterData.SetID(const Value: Variant);
begin
  FID := Value;
  PresenterID := Value;
end;

end.
