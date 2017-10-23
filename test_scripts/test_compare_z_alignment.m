%%%% check point-match data in a collection

%%% check dmesh point-match collection for FAFBv12
clc;kk_clock;
scale = 1.0;
dy = 25;
x = 19000;
y = 19700;
width = 5000;
res = [4 4 50]; % voxel resolution in nm
%% configurations

% nfirst = 11;
% nlast  = 16;
% % configure rough collection
% rc.stack          = 'v12_align';
% rc.owner          ='flyTEM';
% rc.project        = 'FAFB00';
% rc.service_host   = '10.37.5.60:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 1;
% 
% % configure point-match collection
% pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner            = 'flyTEM';
% pm.match_collection = 'v12_dmesh';


% nfirst = 1;
% nlast  = 4;
% % configure rough collection
% rc.stack          = ['EXP_v12_rough_' num2str(nfirst) '_' num2str(nlast)];
% rc.owner          ='flyTEM';
% rc.project        = 'test';
% rc.service_host   = '10.37.5.60:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 1;
% 
% % configure point-match collection
% pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner            = 'flyTEM';
% pm.match_collection = 'FAFBv12Test18';


% nfirst = 1;
% nlast  = 16;
% % configure rough collection
% rc.stack          = ['EXP_v12_alignP1_' num2str(nfirst) '_' num2str(nlast)];
% rc.owner          ='flyTEM';
% rc.project        = 'test';
% rc.service_host   = '10.37.5.60:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 1;
% 
% % configure point-match collection
% pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner            = 'flyTEM';
% pm.match_collection = 'FAFBv12Test18';

%%
nfirst = 1;
nlast  = 100;
% configure collection

rc.owner          ='flyTEM';
rc.project        = 'test';
rc.service_host   = '10.37.5.60:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rc.stack          = ['EXP_v12_rough_' num2str(nfirst) '_' num2str(nlast)];
figure(1);[I1, Io] = get_xz_image_renderer(rc, x, y, width, dy, scale, nfirst, nlast, res);
title('rough');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
rc.stack          = ['EXP_v12_alignP1_' num2str(nfirst) '_' num2str(nlast)];
figure(2);[I2, Io] = get_xz_image_renderer(rc, x, y, width, dy, scale, nfirst, nlast, res);
title('P1');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rc.stack          = ['EXP_v12_alignP2_' num2str(nfirst) '_' num2str(nlast)];
figure(3);[I3, Io] = get_xz_image_renderer(rc, x, y, width, dy, scale, nfirst, nlast, res);
title('P2');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
rc.stack          = ['EXP_v12_alignP3_' num2str(nfirst) '_' num2str(nlast)];
figure(4);[I4, Io] = get_xz_image_renderer(rc, x, y, width, dy, scale, nfirst, nlast, res);
title('P3');
 