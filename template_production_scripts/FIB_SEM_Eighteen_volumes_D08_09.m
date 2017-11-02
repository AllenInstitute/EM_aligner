%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% configure 
diary on;
clc
nfirst= 1;%23;%96301;
nlast = 1295;
% configure source
% configure source collection
rcsource.stack          = 'Z0416_04male_Sec10_D08_09_acquire';
rcsource.owner          ='hessh';
rcsource.project        = 'flyem_04male_082017';
rcsource.service_host   = '10.40.3.162:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 0;

% configure translation-only alignment
rctranslation.stack          = ['kk_Z0416_04male_Sec10_D08_09_temp_translation_scale_0_7_' num2str(nfirst) '_' num2str(nlast)];
rctranslation.owner          ='hessh';
rctranslation.project        = 'flyem_04male_082017';
rctranslation.service_host   = '10.40.3.162:8080';
rctranslation.baseURL        = ['http://' rctranslation.service_host '/render-ws/v1'];
rctranslation.verbose        = 0;

% configure fine output collection
rcfine.stack          = ['kk_Z0416_04male_Sec10_D08_09_fine_scale_0_7'];
rcfine.owner          ='hessh';
rcfine.project        = 'flyem_04male_082017';
rcfine.service_host   = '10.40.3.162:8080';
rcfine.baseURL        = ['http://' rcfine.service_host '/render-ws/v1'];
rcfine.verbose        = 0;
rcfine.versionNotes   = 'Fine alignment using -- Translation-only regularized affine';


% configure point-match collection
pm.server = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner = 'hessh';
pm.match_collection = 'test_flyem_D08_09_scale_0_7_d_1';
% pm.match_collection = 'flyem_04male_082017_Z0416_04male_Sec10_D08_09';

dir_scratch = '/scratch/khairyk';
kk_clock();

% %% produce a translation-only stack
% 
% 
% % configure solver
% 
% configure solver
opts.degree = 0;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.solver = 'backslash';

opts.transfac = 1;  % translation parameter regidity
% opts.xfac = 1;   % 2nd order parameter rigidity in x
% opts.yfac = 1;   % 2nd order parameter regidity in y
% opts.lambda = 10^(6.5); % 10^4.5 (best results so far for affine) ------------------>

opts.nbrs = 1;
opts.nbrs_step = 1;
opts.xs_weight = 1.0;
opts.min_points = 3;
opts.max_points = inf;
opts.filter_point_matches = 1;
opts.Width = [];
opts.Height = [];

%opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
%opts.matrix_only = 0;   % 0 = solve , 1 = only generate the matrix
opts.distribute_A = 1;  % # shards of A
opts.dir_scratch = dir_scratch;

% opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
%opts.distributed = 0;
opts.disableValidation = 1;
%opts.edge_lambda = opts.lambda;
opts.use_peg = 0;
opts.verbose = 1;
opts.debug = 0;

% % configure point-match filter
opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
opts.pmopts.MaximumRandomSamples = 5000;
opts.pmopts.DesiredConfidence = 99.5;
opts.pmopts.PixelDistanceThreshold = 1e-4;


[err,R, Tout, PM, Diagnostics] = system_solve_translation(nfirst, nlast, rcsource, pm, opts, rctranslation);

% h = figure;plot([Diagnostics.rms_o(:,1) Diagnostics.rms(:,1)]); 
% title('Scale 0.7 Comparison rms per tile (or section) between acquire, translation and affine stacks');
% xlabel('section number');ylabel('total pixel residual error');legend('Acquire', 'Translation');
% 

% h = figure;plot([Diagnostics.tile_err_o(:,1) Diagnostics.tile_err(:,1)]); 
% title('Comparison of total residual error per tile (or section) for x between acquire and translation stacks');
% xlabel('section number');ylabel('total pixel residual error');legend('Acquire', 'Translation');
% 
% h = figure;plot([Diagnostics.tile_err_o(:,2) Diagnostics.tile_err(:,2)]); 
% title('Comparison of total residual error per tile (or section) for ybetween acquire and translation stacks');
% xlabel('section number');ylabel('total pixel residual error');legend('Acquire', 'Translation');


%% configure Affine fine alignment
rcrough = rctranslation;
% configure solver
opts.PM = PM;
opts.transfac = 1e-4; 
opts.lambda = 10^(5); % 
opts.constrain_by_z = 0;
opts.sandwich = 0;
opts.constraint_fac = 1e15;
opts.filter_point_matches = 1;
opts.save_matrix = 0;  % for debugging you can save the matrix if set to 1

% configure solver
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.solver = 'backslash';

opts.nbrs = 1;
opts.nbrs_step = 1;
opts.xs_weight = 1.0;
opts.min_points = 5;
opts.max_points = inf;

opts.Width = [];
opts.Height = [];

opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.matrix_only = 0;   % 0 = solve , 1 = only generate the matrix
opts.distribute_A = 1;  % # shards of A
opts.dir_scratch = dir_scratch;

% opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 0;
opts.disableValidation = 1;
opts.edge_lambda = opts.lambda;
opts.use_peg = 0;

% % % configure point-match filter
% opts.filter_point_matches = 1;
% opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
% opts.pmopts.MaximumRandomSamples = 5000;
% opts.pmopts.DesiredConfidence = 99.9;
% opts.pmopts.PixelDistanceThreshold = .1;
% opts.verbose = 1;
% opts.debug = 0;

%%
             
rcfine.versionNotes = gen_versionNotes(opts);
[err,R, Tout, D_affine] = system_solve_affine_with_constraint(nfirst, nlast, rcrough, pm, opts, rcfine);disp(err);

%% generate x y residual plots
h = figure;plot([Diagnostics.rms_o(:,1) Diagnostics.rms(:,1) D_affine.rms(:,1)]); 
title('Scale 0.7 Comparison rms per tile (or section) between acquire, translation and affine stacks');
xlabel('section number');ylabel('total pixel residual error');legend('Acquire', 'Translation', 'Affine');
% 
% h = figure;plot([Diagnostics.tile_err_o(:,1) Diagnostics.tile_err(:,1) D_affine.tile_err(:,1)]); 
% title('Comparison of total residual error per tile (or section) for x between acquire, translation and affine stacks');
% xlabel('section number');ylabel('total pixel residual error');legend('Acquire', 'Translation', 'Affine');
% 
% h = figure;plot([Diagnostics.tile_err_o(:,2) Diagnostics.tile_err(:,2) D_affine.tile_err(:,2)]); 
% title('Comparison of total residual error per tile (or section) for ybetween acquire, translation and stacks');
% xlabel('section number');ylabel('total pixel residual error');legend('Acquire', 'Translation', 'Affine');


% %% generate mini stack (optional)
% [Wbox, bbox, url, minZ, maxZ] = get_slab_bounds_renderer(rcfine);
% 
% n_spark_nodes = 2;
% bill_to = 'hessh';
% spark_dir = '/groups/flyem/data/render/spark_output';
% dir_out = '/groups/flyem/data/khairy_alignments/D08_09_ministack';% '/groups/flyTEM/home/khairyk/mwork/FIBSEM/mini_stacks'; % /groups/flyem/data/khairy_alignments/D08_09_ministack
% max_images = 5000;
% scale = 0.5;
% zscale = 0.5;
% minz = 1;
% maxz = 1295;
% minx = Wbox(1);%11405;
% width = Wbox(3);% 2000
% str = generate_mini_stack(rcfine, scale, zscale, dir_out, minz, maxz, minx, width,  n_spark_nodes, bill_to);

