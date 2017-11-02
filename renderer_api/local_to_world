function [x, y] = world_to_world(rc1, rc2, x, y, z)
% coordinate mapping of a point from rc1 to rc2

% map from rc1 world to tile local
% http://tem-services.int.janelia.org:8080/render-ws/v1/owner/flyTEM/
%       project/FAFBv14_kk/stack/patch_FULL_FAFB_FUSED_kk_02/z/5000/world-to-local-coordinates/211846,188595
url = sprintf('%s/owner/%s/project/%s/stack/%s/z/%s/world-to-local-coordinates/%d,%d',...
    rc1.baseURL, rc1.owner, rc1.project, rc1.stack, num2str(z), x,y);

U = matlab.net.URI(url);
jj1 = webread(char(U));
if iscell(jj1)
jj1 = jj1{1};
end
% map from tile local to rc2 world and return new coordinate
url = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/local-to-world-coordinates/%d,%d',...
    rc2.baseURL, rc2.owner, rc2.project, rc2.stack, jj1.tileId, jj1.local(1),jj1.local(2));

U = matlab.net.URI(url);
jj2 = webread(char(U));

x = jj2.world(1);
y = jj2.world(2);