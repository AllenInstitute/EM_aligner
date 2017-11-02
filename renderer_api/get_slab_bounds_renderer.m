function [Wbox, bbox, url, minZ, maxZ] = get_slab_bounds_renderer(rc)
% returns Wbox = [x y width height] of collection as specified in rc
% get /v1/owner/{owner}/project/{project}/stack/{stack}/bounds 


url = sprintf('%s/owner/%s/project/%s/stack/%s/bounds',...
    rc.baseURL, rc.owner, rc.project, rc.stack);
try
js = webread(url);
Wbox = [js.minX js.minY js.maxX-js.minX js.maxY-js.minY];
bbox = [js.minX js.minY js.maxX js.maxY];
minZ = js.minZ;
maxZ = js.maxZ;
catch err_bounds
    kk_disp_err(err_bounds);
    Wbox = [];
    bbox = [];
    disp('Returning empty box');
end