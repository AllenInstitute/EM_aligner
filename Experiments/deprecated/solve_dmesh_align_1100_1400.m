% The script assumes the existence of a Renderer collection (configured below)
% Dependencies:
%               - Renderer service
%               - script to generate spark_montage_scapes
%
% Calculate the full stitching (montage and alignment) of a set of sections
% Ingest this slab into a new collection
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% [0] configure collections and prepare quantities
clc; clear all;
kk_clock;
nfirst = 1000;
nlast  = 1700;

% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure montage collection

rctarget_montage.stack          = ['EXP_dmesh_montage_P1_' num2str(nfirst) '_' num2str(nlast)];
rctarget_montage.owner          ='flyTEM';
rctarget_montage.project        = 'test';
rctarget_montage.service_host   = '10.37.5.60:8080';
rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
rctarget_montage.verbose        = 1;

% configure rough collection
rctarget_rough.stack          = ['EXP_dmesh_rough_P1' num2str(nfirst) '_' num2str(nlast)];
rctarget_rough.owner          ='flyTEM';
rctarget_rough.project        = 'test';
rctarget_rough.service_host   = '10.37.5.60:8080';
rctarget_rough.baseURL        = ['http://' rctarget_rough.service_host '/render-ws/v1'];
rctarget_rough.verbose        = 1;

% configure output "align" collection
rctarget_align.stack          = ['EXP_dmesh_align_P2_' num2str(nfirst) '_' num2str(nlast)];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';


%% 
% configure solver
opts.min_tiles = 10; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded post-solution
opts.solver = 'backslash';
opts.min_points = 5;
opts.nbrs = 4;      % how many neighboring sections to include in point-match loading
opts.xs_weight = 1/50;  % small numbers ==> less weight for cross-layer points relative to montage points
opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
                       % 1 = regularize against input collection
                       
opts.distributed = 1;  % 1 = use Matlab cluster for solving matrix
opts.lambda = 10^(0);
opts.edge_lambda = 10^(0);
opts.calc_confidence = 1;
opts.conn_comp = 0; 
opts.translation_fac = 1.0;
%%
[mL, pm_mx, pm_err, R, ~, ntiles, PM, sectionId_load, z_load] = ...
    solve_slab(rctarget_rough, pm, nfirst, nlast, [], opts);

%% ingest into Renderer database (optional);
delete_renderer_stack(rctarget_align);  % delete existing collection if present
append_resp = ingest_section_into_LOADING_collection(mL, rctarget_align, rcsource, pwd, 1); % ingest
resp = set_renderer_stack_state_complete(rctarget_align);  % set to state COMPLETE

kk_clock();
































