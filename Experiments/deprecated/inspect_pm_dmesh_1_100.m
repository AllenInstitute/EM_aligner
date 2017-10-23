% Example script to solve a FAFBv12 slab for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%% [0] configure collections and prepare quantities
clc;kk_clock;

nfirst = 20;
nlast  = 30;

% % configure source collection
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;
% 
% % configure source collection
% rcsource.stack          = 'EXP_v12_montage_1_7060';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'test';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;


% configure source collection
rcsource.stack          = 'EXP_v12_montage_21_22';
rcsource.owner          ='flyTEM';
rcsource.project        = 'test';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;


% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';
% configure point match fetching
opts.min_points = 5;
opts.nbrs = 0;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
for ix = nfirst:nlast
    [L, tIds, PM, pm_mx, sectionIds, zvals] = check_pm_data(ix, ix, rcsource, pm, opts);
    title(num2str(ix));
    drawnow;
end

%%%%%%%%%%% if happy with point matches, solve
% % configure align collection
% rctarget_align.stack          = ['EXP_v12_dmesh_alignP2_' num2str(nfirst) '_' num2str(nlast)];
% rctarget_align.owner          = 'flyTEM';
% rctarget_align.project        = 'test';
% rctarget_align.service_host   = '10.37.5.60:8080';
% rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rctarget_align.verbose        = 1;

% % configure solver
% opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
% opts.degree = 2;    % 1 = affine, 2 = second order polynomial, maximum is 3
% opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
% opts.lambda = 1e3;
% opts.edge_lambda = 1e4;
% opts.solver = 'backslash';
% opts.min_points = 0;
% opts.nbrs = 3;
% opts.xs_weight = 1/10;
% opts.stvec_flag = 0;   % 0 =  do not assume rcsource providing the starting values.
% [mL, A]= solve_slab(rcsource, pm, nfirst, nlast, rctarget_align, opts);
% kk_clock;

