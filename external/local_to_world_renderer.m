function p = local_to_world_renderer(rc, tid, fn, lp)
% convert a point from local (raw) tile (tid) coordinate system (the original image) to world coordinate system.
% the "world" is defined by the collection rc.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
x = lp(1);
y = lp(2);
url_W2L =...
    sprintf('http://tem-services.int.janelia.org:8080/render-ws/v1/owner/%s/project/%s/stack/%s/tile/%s/local-to-world-coordinates/%.2f,%.2f',...
    rc.owner, rc.project, rc.stack, tid, x,y);%         v = webread(url_W2L); should be used in the future (fix comma issue), v is a struct
cmd = sprintf('curl -X GET --connect-timeout 30 --header "Content-Type: application/json" --header "Accept: application/json" -o "%s" "%s"',...
    fn, url_W2L);
[a, resp]= evalc('system(cmd)');%disp(a);disp(resp);
jstr = fileread(fn); %disp(str);
delete(fn);
v = JSON.parse(jstr);
p = [v.world{1} v.world{2} v.world{3}];