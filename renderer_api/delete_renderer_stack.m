function resp = delete_renderer_stack(rc)
% remove stack if it already exists
% rc is a struct with fields (baseURL, owner, project, stack)
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verbose = 0;
check_input(rc);
if ~stack_read_only(rc)
% default the renderer binary to Janelia's setup
if ~isfield(rc, 'renderbinPath')
    rc.renderbinPath = '/groups/flyTEM/flyTEM/render/bin';
end

str1 = sprintf('PROJECT_PARAMS="--baseDataUrl %s --owner %s --project %s";', rc.baseURL, rc.owner, rc.project);
str2 = sprintf('TARGET_STACK="%s";', rc.stack);
str3 = sprintf('%s/manage-stack.sh ${PROJECT_PARAMS} --action DELETE --stack ${TARGET_STACK}', rc.renderbinPath);
strcmd = [str1 str2 str3];

try
[a, resp] = system(strcmd);
catch err_cmd_exec
    kk_disp_err(err_cmd_exec);
    error(['Error executing: ' strcmd]);
end

if strfind(resp, 'caught exception'), 
    disp(resp);
    error('delete_renderer_stack: server-side error reported');
end

if verbose
    disp(a);
    disp(resp);
end
else
    warning('You cannot delete a stack in READ_ONLY state. Set to COMPLETE or LOADING first');
end


%%
function check_input(rc)
if ~isfield(rc, 'baseURL'), disp_usage; error('baseURL not provided');end
if ~isfield(rc, 'owner'), disp_usage; error('owner not provided');end
if ~isfield(rc, 'project'), disp_usage; error('project not provided');end
if ~isfield(rc, 'stack'), disp_usage; error('stack not provided');end


%%
function disp_usage()
disp('Usage:');
disp('Provide an input struct with fields: baseURL, owner, project, stack');