% Example script to solve a FAFBv12 slab for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%% [0] configure collections and prepare quantities
clc;kk_clock;

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
opts.distributed = 0;  % 1 = use currently active Matlab cluster if available
opts.lambda = 10^(-1);
opts.edge_lambda = 10^(-1);
opts.small_region_lambda = 10^(1);
opts.small_region = 10;

opts.calc_confidence = 1;
opts.translation_fac = 1.0;
%% solve

[mL, pm_mx, err, R, L_vec, ntiles, PM, sectionId_load, z_load] = ...
    solve_slab(rcsource, pm, nfirst, nlast, [], opts);

%% ingest into Renderer database (optional);
delete_renderer_stack(rctarget_align);  % delete existing collection if present
ingest_section_into_LOADING_collection(mL, rctarget_align, rcsource, pwd, 1); % ingest
resp = set_renderer_stack_state_complete(rctarget_align);  % set to state COMPLETE




% %% (optional) look at a box in the middle of the section to spot-check alignment
% scale = 1.0;
% n = nlast-nfirst;
% dir_temp_render = '/scratch/khairyk';
% % [section_box, bbox, url] = get_section_bounds_renderer(rctarget_align, round((nlast-nfirst)/2));
% % x = section_box(1)+section_box(3)/2;
% % y = section_box(2)+section_box(4)/2;
% 
% x = 6300;
% y = 12500;
% 
% W = 1000;
% H = 1000;
% Wbox = [x y  W H];
% M = zeros(W*scale, H*scale,n);
% parfor z = 1:n
%     z_eff = z + nfirst-1;
%     %disp(z_eff);
%     [im, v, url] = get_image_box_renderer(rctarget_align, z_eff, Wbox, scale, dir_temp_render, rctarget_align.stack);
%     M(:,:,z) = mat2gray(im);
% end
% %
% for imix = 1:n
%     imshow(M(:,:,imix));
%     drawnow;
%     pause(0.5);
% end
