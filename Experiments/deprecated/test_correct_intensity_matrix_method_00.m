%% Experimental: load point matches and section tiles. Minimize residual intensity difference between point-match locations

% configure rough collection
nfirst = 1;
nlast  = 100;
rc.stack          = ['EXP_v12_rough_' num2str(nfirst) '_' num2str(nlast)];
rc.owner          ='flyTEM';
rc.project        = 'test';
rc.service_host   = '10.37.5.60:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;


[L, tIds, PM, pm_mx, sectionId, z] = load_point_matches(1, 1, rc, pm, nbr, min_points, xs_weight)