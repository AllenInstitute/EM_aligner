function v = get_tile_spec_renderer(t1)
% Returns renderer-parameters for tile t
url1 = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/render-parameters?filter=true',...
    t1.server, t1.owner, t1.project, t1.stack, t1.renderer_id);
v = webread(url1);
