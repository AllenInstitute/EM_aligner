function resp = delete_renderer_section(rc, z)
% remove section if it already exists
% z is the z-value of the section
% rc is a struct with fields (baseURL, owner, project, stack)
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verbose = 0;
check_input(rc);
% default the renderer binary to Janelia's setup
if ~isfield(rc, 'renderbinPath')
    rc.renderbinPath = '/groups/flyTEM/flyTEM/render/bin';
end


set_renderer_stack_state_loading(rc);

str1 = sprintf('PROJECT_PARAMS="--baseDataUrl %s --owner %s --project %s";', rc.baseURL, rc.owner, rc.project);
str2 = sprintf('TARGET_STACK="%s";', rc.stack);
str3 = sprintf('%s/manage-stack.sh ${PROJECT_PARAMS} --action DELETE --stack ${TARGET_STACK} --zValues %d', ...
    rc.renderbinPath, z);
strcmd = [str1 str2 str3];

try
[a, resp] = system(strcmd);
catch err_cmd_exec
    kk_disp_err(err_cmd_exec);
    error(['Error executing: ' strcmd]);
end

if strfind(resp, 'caught exception')
    disp(resp);
    error('delete_renderer_section: server-side error reported');
end

if verbose,
    disp(a);
    disp(resp);
end

%set_renderer_stack_state_complete(rc);
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