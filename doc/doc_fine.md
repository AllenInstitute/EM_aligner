## Prerequisites
We are assuming that the Renderer and point-match services (and associated database) are set up and accessible for example at http://tem-services.int.janelia.org.
Also, you are using Matlab 2016b and above with toolboxes: Computer Vision Systems (or Video and Blockset), ImageProcessing, Statistics, (optional) Matlab compiler and (optional) Parallel computing. The latest EM_aligner directory and subdirectories are on your Matlab path.

NOTE:
For massive numbers of tiles/canvases (more than 250k) Matlab's backslash operator is not able to handle the least-squares solution. There is one of three options to solve this:
1. Use an iterative method (bicgstab, bicg or gmres). This should work but needs experimentation for these large systems
2. Use PaSTiX: Needs a properly installed and set-up PaSTiX. Documentation about this will follow.
3. Solve your volume as two or more overlapping slabs (contiguous sections) and "fuse" using "fuse_collections.m" to interpolate within the overlap zone and generate a new volume. Documentation and examples will follow.

Additional assumptions:
[1] A Renderer collection of roughly aligned (contiguous) sections exists as regularizer (starting value). 
[2] A full set of one or more point-match collections exists, that encompasses point-matches across and within sections.

## Option 1: Solve fine-alignment from within a Matlab session

Calculates an affine or higher order polynomial (restricted to 2nd at the moment) solution for a volume


------------------------------------------- Example -----------------------------
```json
%% configure
nfirst= 1;
nlast = 10;

%%%% define collection of point-matches that will be aggregated for the solve.

clear pm;ix = 1;
% 
pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'Me_owner';
pm(ix).match_collection = 'pm_dataset_1';
ix = ix + 1;

pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'Me_owner';
pm(ix).match_collection = 'pm_dataset_2';
ix = ix + 1;

pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'Me_owner';
pm(ix).match_collection = 'pm_dataset_3';
ix = ix + 1;



% configure rough (input) stack
rcrough.stack          = ['My_slab_' num2str(nfirst) '_' num2str(nlast) '_rough'];
rcrough.owner          ='Me_owner';
rcrough.project        = 'My_project';
rcrough.service_host   = '10.40.3.162:8080';
rcrough.baseURL        = ['http://' rcrough.service_host '/render-ws/v1'];
rcrough.verbose        = 1;

% configure output fine-aligned stack
rcfine_filtered.stack          = ['My_slab_' num2str(nfirst) '_' num2str(nlast) '_fine'];
rcfine_filtered.owner          ='Me_owner';
rcfine_filtered.project        = 'My_project';
rcfine_filtered.service_host   = '10.40.3.162:8080';
rcfine_filtered.baseURL        = ['http://' rcfine_filtered.service_host '/render-ws/v1'];
rcfine_filtered.verbose        = 1;


% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';%'pastix';%%'gmres';%'bicgstab'

%%% if degree > 1 these additional settings are expected --- example values provided below
%opts.transfac = 1e-5;  % translation parameter regidity
%opts.xlambdafac = 10^(0);% 1st order parameter regidity in x
%opts.ylambdafac = 10^(0);% 1st order parameter regidity in y
%opts.xfac = 10^(0);   % 2nd order parameter rigidity in x
%opts.yfac = 10^(0);   % 2nd order parameter regidity in y


% only relevant when solver is pastix
opts.pastix.ncpus = 8;
opts.pastix.parms_fn = '/path_to_parameters_file/params_file.txt';
opts.pastix.split = 1; % set to either 0 (no split) or 1

opts.matrix_only = 0;   % 0 = solve (default) , 1 = only generate the matrix. For debugging only
opts.distribute_A = 1;  % # shards of A
opts.dir_scratch = '/myscratch_directory';
opts.nchunks_ingest = 64;

opts.min_points = 8;
opts.max_points = 100;
opts.nbrs = 4;
opts.xs_weight = 0.1;  % ------------------------------------->
opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 0;

opts.transfac = 1;  % let tiles translate more freely if transfac<1 (e.g. 1e-5)

opts.lambda = 10.^(-3);  % -----------------------------------> regularization parameters
opts.A = [];
opts.b = [];
opts.W = [];

% % configure point-match filter
opts.filter_point_matches = 1;  %------------------------------->
opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
opts.pmopts.MaximumRandomSamples = 5000;
opts.pmopts.DesiredConfidence = 99.9;
opts.pmopts.PixelDistanceThreshold = .01;

opts.verbose = 1;
opts.debug = 0;

opts.use_peg   = 0;   % ------------------------------------>
opts.peg_weight = 0.0001;
opts.peg_npoints = 10;
opts.disableValidation = 1;

%%%% sove important parameters in Renderer collection meta data
rcfine_filtered.versionNotes = ['lambda: ' num2str(opts.lambda) ' -- transfac: ' num2str(opts.transfac) ...
                                ' -- filter pms: ' num2str(opts.filter_point_matches) ' -- use peg: ' ...
                                num2str(opts.use_peg)];
%%% solve the system
[mL, err] =  system_solve(nfirst, nlast, rcrough, pm, opts, rcfine_filtered);  %%% fast solve and ingest

%%% alternatively use: (uncomment)
% [mL, pm_mx, err, R, ~, ntiles, PM, sectionId_load, z_load] = solve_slab(rcrough, pm, nfirst, nlast, rcfine_filtered, opts);


%% diagnostics (optional) -- uncomment to use

% % dopts.nbrs = 3;
% % dopts.min_points = 5;
% % dopts.show_deformation = 0;
% % dopts.show_residuals = 0;
% % dopts.show_deformation_summary = 0;
% % [mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, tidsvec, Resx,Resy] =...
% %     gen_diagnostics(rcsource, rcfine_filtered, nfirst, nfirst+5, pm, dopts);


%% find best lambda (optional) -- uncomment to use (before final solve)

% % diagnostics parameters
% dopts.nbrs = 4;
% dopts.min_points = 8;
% dopts.show_deformation = 0;
% dopts.show_residuals = 0;
% dopts.show_deformation_summary = 0;
% 
% count = 1;
% def = [];
% err = [];
% l_used = [];
% for lexp = -3:0.5:4    % range of lambda to explore
%     opts.lambda = 10^(lexp);
%     opts.edge_lambda = opts.lambda;
%     % solve system and ingest
%     [err(count)] = system_solve(zstart, zfinish, rcrough_filtered, pm, opts, rcfine_filtered);
%     % generate diagnostics on sections/tiles
%     [mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, tidsvec] =...
%         gen_diagnostics(rcsource, rcfine_filtered, zstart, zfinish, pm, dopts);
%     % aggregate deformation data
%     def(count) = 1/mean(mA);
%     l_used(count) = opts.lambda;
%     disp([l_used(count) err(count) def(count)]);
%     count = count + 1;
% end
% disp([l_used(:) err(:) def(:)]);
% plot(log10(l_used), log10(err), 'o-', log10(l_used), log10(def), 'k-');

% --------------------------------------- END of EXAMPLE -------------------------------
```


If CATMAID dynamic rendering is set up, you can view your fine alignment using a URL for example similar to this:
http://tem-services.int.janelia.org:8080/render-ws/view/stacks.html?owner=flyTEM&project=test&dynamicRenderHost=renderer:8080&catmaidHost=renderer-catmaid:8000



## Option 2: (In progress) Fine alignment strategies. 
(under construction)






