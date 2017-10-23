% Example script to solve a FAFBv12 slab for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%% [0] configure collections and prepare quantities
clc;kk_clock;

nfirst = 1;
nlast  = 15600;

rcsource.stack          = 'v2_acquire';
rcsource.owner          ='flyTEM';
rcsource.project        = '20161004_S3_cell11_Inlens_data';
rcsource.service_host   = '10.40.3.162:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 0;



% configure align collection

rctarget_align.stack          = ['v2_align_mx_solver_1_15600_v5'];
rctarget_align.owner          ='flyTEM';
rctarget_align.project        = '20161004_S3_cell11_Inlens_data';
rctarget_align.service_host   = '10.40.3.162:8080';
rctarget_align.baseURL        = ['http://' rctarget_align.service_host '/render-ws/v1'];
rctarget_align.verbose        = 0;
rctarget_align.versionNotes   = 'Fine alignment using matrix solver with Matlab backslash operator and translation-only regularization lambda 1e5';

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'hessh';
pm.match_collection = '20161004_S3_cell11_Inlens_data';


% configure solver
opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
opts.lambda = 1e5;
opts.edge_lambda = opts.lambda;
opts.solver = 'backslash';
opts.min_points = 5;
opts.max_points = 50;
opts.nbrs = 5;
opts.xs_weight = 1;
opts.stvec_flag = 0;   % i.e. do not assume rcsource providing the starting values.

opts.use_peg = 0;
opts.complete = 1;
opts.disableValidation = 1;
opts.apply_scaling = 1;
opts.scale_fac = 1.0;
opts.translation_only = 1;

[mL, A]= solve_slab(rcsource, pm, nfirst, nlast, rctarget_align, opts);

kk_clock;

[mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, tidsvec] =...
    gen_section_based_tile_deformation_statistics(rctarget_align, nfirst, nlast, pm);


%% reference
% 
% [mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, tidsvec] =...
%     gen_section_based_tile_deformation_statistics(rcsource, nfirst, nlast, pm);



% delete_renderer_stack(rctarget_align);

