function resp = delete_renderer_tile(rc, tileIDs)
% remove tileIDs from stack
% tileIDs is an array of the tileIDs to be deleted
% rc is a struct with fields (baseURL, owner, project, stack)
%
% Author: David Ackerman
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Ensure tileIDs is a cell array of character vectors; easier for sprintf
% later
if ~(iscellstr(tileIDs) || iscell(tileIDs))
    tileIDs = cellstr(tileIDs);
end

verbose = 0;
check_input(rc);

% Method that uses bash script; advantage was that you could submit all tiles
% at once:
%
% set_renderer_stack_state_loading(rc);
% default the renderer binary to Janelia's setup
% if ~isfield(rc, 'renderbinPath')
%     rc.renderbinPath = '/groups/flyTEM/flyTEM/render/bin';
% end
% str1 = sprintf('PROJECT_PARAMS="--baseDataUrl %s --owner %s --project %s";', rc.baseURL, rc.owner, rc.project);
% str2 = sprintf('TARGET_STACK="%s";', rc.stack);
% str3 = sprintf('%s/remove-tiles.sh ${PROJECT_PARAMS} --stack ${TARGET_STACK} %s ', ...
%     rc.renderbinPath, strjoin(tileIDs));
% strcmd = [str1 str2 str3];
% system(strcmd);
% set_renderer_stack_state_complete(rc);

% Use curl
set_renderer_stack_state_loading(rc);
number_of_tiles_to_delete = numel(tileIDs);
resp=cell(number_of_tiles_to_delete,1);
parfor idx = 1:number_of_tiles_to_delete
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s',...
        rc.baseURL, rc.owner, rc.project, rc.stack,tileIDs{idx});

    strcmd = sprintf('curl -X DELETE --header "Accept: application/json" "%s"',urlChar);  
    
    try
        [status, resp{idx}] = system(strcmd);
    catch err_cmd_exec
        kk_disp_err(err_cmd_exec);
        error(['Error executing: ' strcmd]);
    end
    
    if strfind(resp{idx}, 'caught exception')
        disp(resp{idx});
        error('delete_renderer_tile: server-side error reported');
    end
    
    if verbose,
        disp(status);
        disp(resp{idx});
    end
end
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
disp('Provide an input struct with fields: baseURL, owner, project, stack, and a cell string array of tileIDs');