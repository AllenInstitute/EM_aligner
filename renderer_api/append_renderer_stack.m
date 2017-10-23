function resp = append_renderer_stack(rc, rc_base, fn, MET_format, disableValidation, verbose)
% ingests tiles provided in the fn MET format file into an existing Renderer collection
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
if nargin<6
verbose = 0;
end
if nargin<5, disableValidation = 0;end
check_input(rc, rc_base, fn, MET_format);

% str1_source     = sprintf('PROJECT_PARAMS="--baseDataUrl %s --owner %s --project %s --changeMode REPLACE_LAST";', rc.baseURL, rc_base.owner, rc_base.project);
% target_project  = sprintf('TARGET_PROJECT="%s";', rc.project);
% str2            = sprintf('SOURCE_STACK="%s";', rc_base.stack);
% str3            = sprintf('TARGET_STACK="%s";', rc.stack);
% str4            = sprintf('TARGET_OWNER="%s";', rc.owner);
% str6            = sprintf('MET_FORMAT="%s";', MET_format);
% 
% str9            = sprintf('MEMORY="1G";');
% str10           = sprintf('JAVA_CLASS="org.janelia.render.client.ImportMETClient";');
% str11           = sprintf('MET_FILE="%s";', fn);
% str12           = sprintf('/groups/flyTEM/flyTEM/render/pipeline/bin/run_ws_client.sh ${MEMORY} ${JAVA_CLASS} ${PROJECT_PARAMS} --targetProject ${TARGET_PROJECT} --stack ${SOURCE_STACK} --targetStack ${TARGET_STACK} --targetOwner ${TARGET_OWNER} --metFile ${MET_FILE} --formatVersion ${MET_FORMAT};');
% strcmd          = [str9 str10 str1_source target_project str2 str3 str4 str11 str6 str12];

if ~isfield(rc, 'renderbinPath')
    rc.renderbinPath = '/groups/flyTEM/flyTEM/render/bin';
end

if disableValidation==0
    str12           = sprintf('%s/run_ws_client.sh 1G org.janelia.render.client.ImportMETClient --baseDataUrl %s --owner %s --project %s --changeMode REPLACE_LAST --targetProject %s --stack %s --targetStack %s --targetOwner %s --metFile %s --formatVersion %s;', ...
        rc.renderbinPath, rc.baseURL, rc_base.owner, rc_base.project, rc.project, rc_base.stack, rc.stack, rc.owner, fn, MET_format);
else
    if verbose, disp('Disabling validation on the Renderer side');end
    str12           = sprintf('%s/run_ws_client.sh 1G org.janelia.render.client.ImportMETClient --baseDataUrl %s --owner %s --project %s --changeMode REPLACE_LAST --targetProject %s --stack %s --targetStack %s --targetOwner %s --metFile %s --formatVersion %s --disableValidation;', ...
        rc.renderbinPath, rc.baseURL, rc_base.owner, rc_base.project, rc.project, rc_base.stack, rc.stack, rc.owner, fn, MET_format);
end
strcmd          = [str12];


try
    if verbose 
        kk_clock();
        disp('Issuing system command to ingest:');
        disp(strcmd);
    end
    [a, resp] = system(strcmd);
    if verbose, disp(resp);end
catch err_cmd_exec
    kk_disp_err(err_cmd_exec);
    error(['Error executing: ' strcmd]);
end

if strfind(resp, 'caught exception'),
    disp(resp);
    warning('append_renderer_stack: server reported an error');
end


if verbose,
    
    disp(strcmd);
    kk_clock();
   % disp(a);
   % disp(resp);
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

%%
function disp_usage()
disp('Usage:  resp = append_renderer_collection(rc,rc_base,fn, MET_format)');
disp('rc and rc_base: structs with fields: baseURL, owner, project, stack');
disp('fn: path to MET file with tiles');
disp('MET_format: string of value "v1" for affine or "v3" for polynomial transformations');



