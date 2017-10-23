function j = get_json(obj)
%% returns the json tilespec
urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s', ...
               obj.server, obj.owner, obj.project, obj.stack, obj.renderer_id);

j = webread(urlChar);
% cmd = sprintf('curl -X GET --header "Content-Type: application/json" --header "Accept: application/json" -d "@%s" "%s"',...
%     fn, urlChar);
% [a, resp]= evalc('system(cmd)');