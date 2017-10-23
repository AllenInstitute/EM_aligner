function resp = set_tiles_z(rc, tiles, znew)
% set section z value
% tiles is an array of tiles whose z value will be set to znew
% znew is the z-value that this section will be set to.
% rc is a struct with fields (baseURL, owner, project, stack)
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verbose = 0;
check_input(rc);

set_renderer_stack_state_loading(rc);

%%% convert tile renderer ids to json format
tids = {tiles(:).renderer_id};
tids = tids';
strtiles = savejson('', tids);
strtiles(1) = [];
strtiles(end-1:end) = [];
strtiles = strrep(strtiles, '"', '\"');

urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%d/tileIds',...
    rc.baseURL, rc.owner, rc.project, rc.stack,znew);
% webread(char(urlChar);
%%% get rid of curl command and use Matlab built-in function
str = sprintf('curl -X PUT --header "Content-Type: application/json" --header "Accept: application/json" -d "%s" "%s"', ...
      strtiles, urlChar);

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