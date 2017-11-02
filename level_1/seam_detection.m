% the goal is to have some measure of how good our montage point-match set 
% is, by determining cross-correlation quality at tile-tile borders


pm.server = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner = 'flyTEM';
pm.match_collection = 'v12_dmesh';


rc1.stack          = ['Revised_FAFB_montage_pass_10'];
rc1.owner          ='flyTEM';
rc1.project         = 'FAFB00v14_kk';
rc1.service_host   = 'tem-services.int.janelia.org:8080';
rc1.baseURL        = ['http://' rc1.service_host '/render-ws/v1'];
rc1.verbose        = 0;

rc2.stack          = ['Revised_FAFB_montage_remove_small_clusters'];
rc2.owner          ='flyTEM';
rc2.project         = 'FAFB00_beautification';
rc2.service_host   = 'tem-services.int.janelia.org:8080';
rc2.baseURL        = ['http://' rc2.service_host '/render-ws/v1'];
rc2.verbose        = 0;

nfirst = 3899;

L = Msection(rc2, nfirst);

%% example  tile 140730171354062094.3899.0
% good neighbor: 140730171354062095.3899.0
% bad  neighbor: 140730171354062093.3899.0
tileId = 140730171354062094.3899.0;


% map from tile local to rc2 world and return new coordinate
url = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/local-to-world-coordinates/%d,%d',...
    rc2.baseURL, rc2.owner, rc2.project, rc2.stack, tileId, c(1), c(2));

U = matlab.net.URI(url);
jj2 = webread(char(U));

x = jj2.world(1);
y = jj2.world(2);