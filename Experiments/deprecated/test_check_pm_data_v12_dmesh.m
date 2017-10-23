%%%% check point-match data in a collection

%%% check point-match collection
clc;kk_clock;
%% configurations

%%
nfirst = 22;
nlast  = 22;

% configure align collection
rc.stack          = 'v12_acquire';
rc.owner          ='flyTEM';
rc.project        = 'FAFB00';
rc.service_host   = '10.37.5.60:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;
% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';
% configure point match fetching
opts.min_points = 5;
opts.nbrs = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[L, tIds, PM, pm_mx, sectionIds, zvals] = check_pm_data(nfirst, nlast, rc, pm, opts);






















