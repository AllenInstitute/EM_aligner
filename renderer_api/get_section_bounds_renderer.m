function [Wbox, bbox, url] = get_section_bounds_renderer(rc, z)
% returns Wbox = [x y width height] of the section L as specified in rc
% /v1/owner/{owner}/project/{project}/stack/{stack}/z/{z}/bounds 


url = sprintf('%s/owner/%s/project/%s/stack/%s/z/%s/bounds',...
    rc.baseURL, rc.owner, rc.project, rc.stack, num2str(z));
try
js = webread(url);
Wbox = [js.minX js.minY js.maxX-js.minX js.maxY-js.minY];
bbox = [js.minX js.minY js.maxX js.maxY];
catch err_bounds
    kk_disp_err(err_bounds);
    Wbox = [];
    bbox = [];
    disp('Returning empty box');
end