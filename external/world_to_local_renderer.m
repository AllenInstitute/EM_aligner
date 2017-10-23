function [pGroupId, p] = world_to_local_renderer(rc, fn, wp)
%%%
% associate point-matches with tiles and convert to "after-LC" coordinates, i.e. "acquire"
% making them suitable for insertion into a the pm database
%
%  to convert map world coordinates to local coordinates:
% /v1/owner/{owner}/project/{project}/stack/{stack}/z/{z}/world-to-local-coordinates/{x},{y}
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
verbose = 0;
x = wp(1);
y = wp(2);
z = wp(3);
pGroupId = [];
p = [];
url_W2L =...
    sprintf('http://tem-services.int.janelia.org:8080/render-ws/v1/owner/%s/project/%s/stack/%s/z/%s/world-to-local-coordinates/%.2f,%.2f',...
    rc.owner, rc.project, rc.stack, num2str(z), x,y);
%         v = webread(url_W2L); should be used in the future (fix comma issue), v is a struct
cmd = sprintf('curl -X GET --connect-timeout 30 --header "Content-Type: application/json" --header "Accept: application/json" -o "%s" "%s"',...
    fn, url_W2L);
[a, resp]= evalc('system(cmd)');%disp(a);disp(resp);
jstr = fileread(fn); %disp(str);
delete(fn);
if isempty(strfind(jstr, 'no tile specifications found'))
    try
        v  = JSON.parse(jstr);
        p  = [v{end}.local{1} v{end}.local{2} v{end}.local{3}]; % --> this is the point in question, needs to be converted
        
    catch err_constructing_v
        if verbose, kk_disp_err(err_constructing_v);end
    end
    % we only use the visible tile (which is the last one in v) ---> generate point-match entries on a tile-to-tile basis
    try
        pGroupId= v{end}.tileId;
    catch
        pGroupID = [];
        %disp('Warning: invalid field tileId');
    end
else
    if verbose, disp('Tile specification not found:');
    disp(url_W2L);
    end
end
