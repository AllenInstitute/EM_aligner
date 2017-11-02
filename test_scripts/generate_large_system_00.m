% Example script to solve a FAFBv12 slab for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%% [0] configure collections and prepare quantities
clc;kk_clock;

nfirst = 1;
nlast  = 2;

% % configure source collection
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;


% % configure source collection
% rcsource.stack          = 'testing_with_FULL_FAFB_FUSED_05_ROTATED';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB_beautification';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;

% configure source collection
rcsource.stack          = 'EXP_P1_SLAB_1_1_963';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFBv14';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;


% configure align collection
rctarget_align.stack          = ['PASTIX_tests_' num2str(nfirst) '_' num2str(nlast)];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'FAFB_pm_2';

%% configure solver
opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
opts.lambda = 1e-1;
opts.edge_lambda = 1e0;
opts.solver = 'backslash';
opts.min_points = 10;

opts.matrix_only = 0;   % 0 = solve , 1 = only generate the matrix
opts.distribute_A = 1;  % # shards of A
opts.dir_scratch = '/scratch/khairyk';

opts.nbrs = 2;
opts.xs_weight = 1;
opts.stvec_flag = 1;   % 0 = do not assume rcsource providing the starting values.

opts.use_peg  = 0;


[mL, A]= solve_slab(rcsource, pm, nfirst, nlast, rctarget_align, opts);
T = array2table(A{1});
disp(T);
kk_clock;

