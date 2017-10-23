function [strcmd] = get_append_renderer_cmd(rc,rc_base,fn, MET_format)
% generate the command to ingest tiles provided in the fn MET format file into an existing Renderer collection
% in the LOADING state. If the collection is in the 'COMPLETE'  state an
% error will occur.
% (To change the state to 'LOADING' call "set_renderer_collection_state_to_loading" before)
% All tiles in the MET file have to be present in the rc_base collection
% Input:
%       rc      : target collection that will be appended with tile data
%       rc_base : collection to be used as basis for the new collection
%                 (this is not a tile source)
%       fn      : MET file with tile information including their renderer  ids.
%       MET_format: 'v1' for affine or 'v3' for any polynomial
%
% Author: Khaled Khairy. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
check_input(rc, rc_base, fn, MET_format);
% default the renderer binary to Janelia's setup
if ~isfield(rc, 'renderbinPath')
    rc.renderbinPath = '/groups/flyTEM/flyTEM/render/bin';
end

str1_source     = sprintf('--baseDataUrl %s --owner %s --project %s --changeMode REPLACE_LAST ', rc.baseURL, rc_base.owner, rc_base.project);
target_project  = rc.project;
source_stack    = rc_base.stack;
target_stack    = rc.stack;
target_owner    = rc.owner;
mem             = '1G ';
java_class      = sprintf('org.janelia.render.client.ImportMETClient ');
script          = sprintf('%s/run_ws_client.sh ', rc.renderbinPath);
strcmd          = [script mem java_class str1_source ...
    ' --targetOwner ' target_owner ...
    ' --targetProject ' target_project ...
    ' --targetStack ' target_stack ...
    ' --stack ' source_stack ...
    ' --metFile ' fn ' --formatVersion ' MET_format];
end

%%
function check_input(rc, rc_base, fn, MET_format)
if stack_complete(rc), disp(rc);error('The stack is in state: COMPLETE');end
if ~isfield(rc, 'baseURL'), disp_usage; error('baseURL not provided');end
if ~isfield(rc, 'owner'), disp_usage; error('owner not provided');end
if ~isfield(rc, 'project'), disp_usage; error('project not provided');end
if ~isfield(rc, 'stack'), disp_usage; error('stack not provided');end

if ~isfield(rc_base, 'baseURL'), disp_usage; error('baseURL not provided');end
if ~isfield(rc_base, 'owner'), disp_usage; error('owner not provided');end
if ~isfield(rc_base, 'project'), disp_usage; error('project not provided');end
if ~isfield(rc_base, 'stack'), disp_usage; error('stack not provided');end

if ~exist(fn,'file'), disp_usage; error('Invalid MET file or file not found');end

if ~(strcmp(MET_format, 'v1') || strcmp(MET_format, 'v3')), disp_usage; error('Invalid option for MET format');end
end

%%
function disp_usage()
disp('Usage:  resp = append_renderer_collection(rc,rc_base,fn, MET_format)');
disp('rc and rc_base: structs with fields: baseURL, owner, project, stack');
disp('fn: path to MET file with tiles');
disp('MET_format: string of value "v1" for affine or "v3" for polynomial transformations');
end
