function resp = set_section_z_by_section_id(rc, zid, znew)
% set section z value
% zid is the zid of the original section
% znew is the z-value that this section will be set to.
% rc is a struct with fields (baseURL, owner, project, stack)
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verbose = 0;
check_input(rc);

set_renderer_stack_state_loading(rc);

urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/section/%s/z',...
    rc.baseURL, rc.owner, rc.project, rc.stack,zid);

%%% todo: get rid of curl command
str = sprintf('curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" -d "%d" "%s"', ...
      znew, urlChar);

[a, resp] = system(str);

set_renderer_stack_state_complete(rc);

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