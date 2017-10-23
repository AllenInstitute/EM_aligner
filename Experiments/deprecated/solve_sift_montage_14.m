clc;
kk_clock;


nfirst = 13;
nlast = 13;
% % solve for rigid and store in database
% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure montage collection

rctarget_montage.stack          = ['EXP_v12_montage_P3_s13_sift_scale2_9_filter'];
rctarget_montage.owner          ='flyTEM';
rctarget_montage.project        = 'test';
rctarget_montage.service_host   = '10.37.5.60:8080';
rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
rctarget_montage.verbose        = 1;

% configure point-match collection
% pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner            = 'flyTEM';
% pm.match_collection = 'v12_dmesh';

% configure point-match collection
% pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner            = 'flyTEM';
% pm.match_collection = 'trautmane_sift_matches_test';

% % configure point-match collection
% pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner            = 'flyTEM';
% pm.match_collection = 'trautmane_v12_am_sift_rod_0_97_inliers_30_filter';

% % configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'trautmane_v12_am_sift_2_to_9';

% configure solver
opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e1;  % large numbers result in fewer tiles excluded

opts.lambda = 10^(-1);
opts.edge_lambda = 10^(-1);

opts.solver = 'backslash';
opts.min_points = 5;
opts.nbrs = 0;
opts.xs_weight = 1/100;
opts.stvec_flag = 0;   % i.e. do not assume rcsource providing the starting values.
opts.distributed = 0;
opts.base_collection = [];
opts.conn_comp = 1;
opts.use_peg = 1;
opts.peg_weight = 1e-4;
opts.peg_npoints = 5;

opts.apply_scaling = 1;

%% solve montage
[L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
    load_point_matches(nfirst, nlast, rcsource, pm, opts.nbrs, opts.min_points, opts.xs_weight); % disp(pm_mx{ix});
L = remove_diagonal_point_matches(L);%%% delete entries for diagonal neighbors
L.pm = filter_pm(L.pm);
%L = upper_limit_on_point_matches(L, 40);
L = add_translation_peggs(L, opts.peg_npoints, opts.peg_weight);
[L, ntiles] = reduce_to_connected_components(L);
L = L(1);

[Lr, errR, mL, is, it, Res]  = get_rigid_approximation(L, opts.solver, opts);
%%% remove peggs and last tile
last_tile = numel(Lr.tiles);
del_ix = find(Lr.pm.adj(:,2)==last_tile);
Lr.pm.M(del_ix,:)  = [];
Lr.pm.adj(del_ix,:) = [];
Lr.pm.W(del_ix) = [];
Lr.pm.np(del_ix) = [];
Lr.tiles(end) = [];
Lr = update_adjacency(Lr);


[mLra, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
    invalid] = solve_affine_explicit_region(Lr, opts);

[mL, A, S] = filter_based_on_tile_area(mLra, opts.outlier_lambda);

resp_append = ...
    ingest_section_into_renderer_database_overwrite(mL,rctarget_montage, rcsource,...
    pwd, 1);

































