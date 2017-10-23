function [err, resp] = create_renderer_stack(rc)
% Creates a new collection in the Renderer database
% rc is a struct with fields (baseURL, owner, project, stack)
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verbose = 0;
err = 0;
check_input(rc);
if ~isfield(rc, 'versionNotes'), rc.versionNotes = 'none';end

% str1 = sprintf('PROJECT_PARAMS="--baseDataUrl %s --owner %s --project %s";', ...
%     rc.baseURL, rc.owner, rc.project);
% str3 = sprintf('TARGET_STACK="%s";', rc.stack);
% str_versionNotes = sprintf('--versionNotes "%s" ', rc.versionNotes);
% 
% str8 = sprintf('/groups/flyTEM/flyTEM/render/bin/manage-stack.sh ${PROJECT_PARAMS} --action CREATE --stack ${TARGET_STACK} %s;',...
%     str_versionNotes);
% strcmd = [str1 str3 str8];

% default the renderer binary to Janelia's setup
if ~isfield(rc, 'renderbinPath')
    rc.renderbinPath = '/groups/flyTEM/flyTEM/render/bin';
end

strcmd = sprintf('%s/manage-stack.sh --baseDataUrl %s --owner %s --project %s --action CREATE --stack %s --versionNotes "%s";',...
    rc.renderbinPath, rc.baseURL, rc.owner, rc.project, rc.stack, rc.versionNotes);



if verbose,
    disp('In create_renderer_stack: command issued');
    disp(strcmd);
end

try
    [a, resp] = system(strcmd);
catch err_cmd_exec
    kk_disp_err(err_cmd_exec);
    error(['Error executing: ' strcmd]);
end

if verbose,
    disp('system response:');
    disp(a);
    disp(resp);
end

if strfind(resp, 'caught exception'),
    disp(resp);
    error('create_renderer_stack: server-side error reported');
end


if verbose,
    disp(strcmd);
    disp(a);
    disp(resp);
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