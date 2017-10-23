% Example script to solve a FAFBv12 slab for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%% [0] configure collections and prepare quantities
clc;kk_clock;

nfirst = 1502;
nlast  = 1511;

% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;


% configure align collection
rctarget_align.stack          = ['EXP_dmesh_P2_' num2str(nfirst) '_' num2str(nlast)];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';

% configure solver
opts.min_tiles = 200; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 2;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';
opts.min_points = 5;
opts.nbrs = 4;
opts.xs_weight = 1/10;
opts.stvec_flag = 0;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 1;

% % test for best regularization parameter
% % This is the smallest that does not cause shrinkage of tiles
regstart = -2;
regfinish = 5;
step = 0.5;

% [L, ~, ~, pm_mx] = load_point_matches(nfirst, nlast, rcsource, pm, opts.nbrs, opts.min_points, opts.xs_weight); % disp(pm_mx{ix});


[L, L_vec, pm_mx, err, scl, h] = ...
    solver_regularization_parameter_sweep(nfirst, nlast, rcsource, pm, ...
                                          opts, regstart, regfinish, step);

% 
%% solve
% 
opts.lambda = 10^(-0.5);
opts.edge_lambda = 10^(-0.5);
% [mL2, pm_mx, err, R, L_vec, ntiles]= solve_slab(rcsource, pm, nfirst, nlast, [], opts);
[mL2, err_res, R] = solve_clusters(L_vec, opts, opts.stvec_flag);   % solves individual clusters and reassembles them into one
% 
delete_renderer_stack(rctarget_align);
ingest_section_into_LOADING_collection(mL2, rctarget_align, rcsource, pwd, 1);
resp = set_renderer_stack_state_complete(rctarget_align);
kk_clock;


















