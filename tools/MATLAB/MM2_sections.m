%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 

% configure 
diary on;
clc
profile on;

%for sending files back and forth to the solver
opts.AIBS_dir=set_AIBS_exchange_path('/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab');
dir_scratch = strcat(opts.AIBS_dir,'scratch');
renderbinPath = '/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts';
%opts.pm_data_file='/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/2017-11-01_1/scratch/temp_1897078/split_PM_1015_1100_2784982189_1.mat'

nfirst= 1015;
nlast = 1016;

disp('specifying source collection')
% configure source
% configure source collection
rcsource.stack          = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2';
rcsource.owner          ='gayathri';
rcsource.project        = 'MM2';
rcsource.service_host   = 'em-131fs:8080';
rcsource.baseURL        = ['http://em-131fs:8080/render-ws/v1'];
rcsource.verbose        = 1;
rcsource.renderbinPath = renderbinPath;

%dir_scratch = '/data/nc-em2/danielk/Janelia_Pipeline/scratch/fine';

disp('specifying target collection')
% configure fine output collection
rcfine.stack = sprintf('mm2_acquire_8bit_reimage_postVOXA_TEMCA2_DK_aligned_g_%d_%d',nfirst,nlast);
rcfine.owner          ='danielk';
rcfine.project        = 'MM2';
rcfine.service_host   = 'em-131fs:8080';
rcfine.baseURL        = ['http://em-131fs:8080/render-ws/v1'];
rcfine.verbose        = 1;
rcfine.renderbinPath = renderbinPath;

disp('specifying point-match collection')
% configure point-match collection
pm.server = 'http://em-131fs:8080/render-ws/v1';
pm.owner = 'gayathri_MM2';
pm.match_collection = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine';

kk_clock();

disp('specifying solver options')
% configure solver
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.solver = 'backslash';
opts.transfac = 1;  % translation parameter regidity
opts.nbrs = 36;
opts.nbrs_step = 1;
opts.xs_weight = 1.0;
opts.min_points = 3;
opts.max_points = inf;
opts.Width = [];
opts.Height = [];
opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.distribute_A = 1;  % # shards of A
opts.dir_scratch = dir_scratch;
opts.disableValidation = 1;
opts.use_peg = 0;
opts.verbose = 1;
opts.debug = 0;
opts.outside_group=true;

% % configure point-match filter
opts.filter_point_matches = 0;
opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
opts.pmopts.MaximumRandomSamples = 50000;
opts.pmopts.DesiredConfidence = 99.3;
opts.pmopts.PixelDistanceThreshold = 0.5e0;

%% configure Affine fine alignment

% configure solver
%opts.PM = PM;              % let's use the same PM struct so that we save time and don't generate it again
opts.transfac = 1e-4; 
opts.lambda = 10^(5); % 
opts.constrain_by_z = 0;
opts.sandwich = 0;
opts.constraint_fac = 1e15;
%opts.filter_point_matches = 1;
opts.save_matrix = 0;  % for debugging you can save the matrix if set to 1

% configure solver
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.solver = 'backslash';

opts.nbrs = 36;
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

% % % configure point-match filter  --- commented out because we are using PM from translation (or rigid approximation) above
% opts.filter_point_matches = 1;
% opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
% opts.pmopts.MaximumRandomSamples = 5000;
% opts.pmopts.DesiredConfidence = 99.9;
% opts.pmopts.PixelDistanceThreshold = .1;
% opts.verbose = 1;
% opts.debug = 0;

%%
disp('solving affinewith contstraints')             
rcfine.versionNotes = gen_versionNotes(opts);
[err,R, Tout, D_affine] = system_solve_affine_with_constraint(nfirst, nlast, rcsource, pm, opts, rcfine);
disp(err);

%% generate x y residual plots
% disp('generating some plots')
% h = figure;plot([D_affine.rms_o(:,1) Diagnostics.rms(:,1) D_affine.rms(:,1)]); 
% title('Scale 0.4 Comparison rms per tile (or section) between acquire, translation and affine stacks');
% xlabel('section number');ylabel('total pixel residual error');legend('Acquire', 'Translation', 'Affine');


% %%% generate additional plots if needed
% h = figure;plot([Diagnostics.tile_err_o(:,1) Diagnostics.tile_err(:,1) D_affine.tile_err(:,1)]); 
% title('Comparison of total residual error per tile (or section) for x between acquire, translation and affine stacks');
% xlabel('section number');ylabel('total pixel residual error');legend('Acquire', 'Translation', 'Affine');
% 
h = figure;plot([D_affine.tile_err(:,2)]); 
title('Comparison of total residual error per tile (or section) for ybetween acquire, translation and stacks');
xlabel('section number');ylabel('total pixel residual error');legend('Acquire', 'Translation', 'Affine');


% %% generate mini stack (optional -- to look at image stack post-alignment in the BigDataViewer for example (or Fiji))
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

