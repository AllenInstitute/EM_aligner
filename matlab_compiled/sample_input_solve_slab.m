% generate example input for solve_slab_SL
clear all;
nfirst = 1;
nlast  = 10;

% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure output "align" collection
rctarget_align.stack          = ['FAFB_v12_dmesh_align_' num2str(nfirst) '_' num2str(nlast)];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;

% configure point-match source collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';

% configure solver
opts.min_tiles = 50; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded post-solution
opts.solver = 'backslash';
opts.min_points = 2;
opts.nbrs = 4;      % how many neighboring sections to include in point-match loading
opts.xs_weight = 1/20;  % small numbers ==> less weight for cross-layer points relative to montage points
opts.stvec_flag = 0;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
                       % 1 = regularize against input collection
opts.conn_comp = 1;    % 1 = solve individual connected components             
opts.distributed = 0;  % 1 = use currently active Matlab cluster if available for solver step
opts.lambda = 10^(-1);
opts.edge_lambda = 10^(-1);
opts.small_region_lambda = 10^(1);
opts.small_region = 10;
opts.calc_confidence = 1;
opts.translation_fac = 1.0;
%%
sl.solver_options = opts;
sl.source_collection = rcsource;
sl.source_point_match_collection = pm;
sl.target_collection = rctarget_align;
sl.first_section = nfirst;
sl.last_section = nlast;
sl.verbose = 1;

fn = [pwd '/sample_solve_slab_input.json'];
str = savejson('', sl);
fid = fopen(fn,'w');
fprintf(fid,str);
fclose(fid);
%% make sure we can read this file
options = loadjson(fileread(fn));



























