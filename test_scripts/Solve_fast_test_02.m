% Script to solve a FAFBv12 rough aligned slabs for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%
%% Step 0: configure 
clc;kk_clock;

nfirst = 1185;
nlast  = 1186;

% configure rough collection
rc.stack          = 'Revised_slab_1185_1204_rough';
rc.owner          ='flyTEM';
rc.project        = 'test';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 1;

% configure fine output collection
rcout.stack          = ['Revised_slab_1185_1204_fine'];
rcout.owner          ='flyTEM';
rcout.project        = 'test';
rcout.service_host   = '10.40.3.162:8080';
rcout.baseURL        = ['http://' rcout.service_host '/render-ws/v1'];
rcout.verbose        = 1;
rcout.versionNotes   = 'testing SURF point-match quality crosslayer';

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_SURF';


% nfirst = 200;
% nlast  = 201;
% 
% % configure rough collection
% rc.stack          = 'FUSED_ROUGH_01';
% rc.owner          ='flyTEM';
% rc.project        = 'test2';
% rc.service_host   = '10.40.3.162:8080';
% rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
% rc.verbose        = 1;
% 
% % configure fine output collection
% rcout.stack          = ['EXP_FAFBv13_slab_' num2str(nfirst) '_' num2str(nlast) '_fine_pastix'];
% rcout.owner          ='flyTEM';
% rcout.project        = 'test2';
% rcout.service_host   = '10.40.3.162:8080';
% rcout.baseURL        = ['http://' rcout.service_host '/render-ws/v1'];
% rcout.verbose        = 1;
% rcout.versionNotes   = 'testing pastix for massive joint solution and distributed A generation';
% 
% % configure point-match collection
% pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner            = 'flyTEM';
% pm.match_collection = 'v12_dmesh';



% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';%'pastix';%%'gmres';%'backslash';'pastix';



opts.pastix.ncpus = 8;
opts.pastix.parms_fn = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_production_scripts/params_file.txt';
opts.pastix.split = 1; % set to either 0 (no split) or 1

opts.matrix_only = 0;   % 0 = solve , 1 = only generate the matrix
opts.distribute_A = 1;  % # shards of A
opts.dir_scratch = '/scratch/khairyk';


opts.min_points = 3;
opts.max_points = 100;
opts.nbrs = 3;
opts.xs_weight = 0.5;
opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 0;

opts.lambda = 10.^(-1);
%opts.edge_lambda = 10^(-1);
opts.A = [];
opts.b = [];
opts.W = [];

% % configure point-match filter
opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
opts.pmopts.MaximumRandomSamples = 1000;
opts.pmopts.DesiredConfidence = 99.5;
opts.pmopts.PixelDistanceThreshold = 1;

opts.verbose = 1;
opts.debug = 0;


disp('---------------');
disp('Processing:');
disp(rc);
disp('---------------');
%kk_clock;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
system_solve(nfirst, nlast, rc, pm, opts, rcout);








     