%%%% check point-match data in a collection

%%% check point-match collection
clc;kk_clock;
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
nfirst = 22;
nlast  = 22;

% configure align collection
rc.stack          = ['EXP_dmesh_P1_' num2str(nfirst) '_' num2str(nlast)];
rc.owner          = 'flyTEM';
rc.project        = 'test';
rc.service_host   = '10.37.5.60:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;

% configure point match fetching
opts.min_points = 5;
opts.nbrs = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[L, tIds, PM, pm_mx, sectionIds, zvals] = check_pm_data(nfirst, nlast, rc, pm, opts);






















