clc;
kk_clock;


n = 22;

% % solve for rigid and store in database
% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure montage collection

rctarget_montage.stack          = ['EXP_v12_montage_P1_s14'];
rctarget_montage.owner          ='flyTEM';
rctarget_montage.project        = 'test';
rctarget_montage.service_host   = '10.37.5.60:8080';
rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
rctarget_montage.verbose        = 1;

% % configure point-match collection
% pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner            = 'flyTEM';
% pm.match_collection = 'v12_dmesh';

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'trautmane_sift_matches_test';


% configure solver
opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e1;  % large numbers result in fewer tiles excluded

opts.lambda = 10^(-1);
opts.edge_lambda = 10^(-1);

opts.solver = 'backslash';
opts.min_points = 3;
opts.nbrs = 0;
opts.xs_weight = 1/100;
opts.stvec_flag = 0;   % i.e. do not assume rcsource providing the starting values.
opts.distributed = 0;
opts.base_collection = [];
opts.conn_comp = 1;
opts.use_peg = 1;
opts.peg_weight = 1e-4;
opts.peg_npoints = 5;


% solve montage
 [L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
            load_point_matches(lix,lix, rcsource, pm, opts.nbrs, opts.min_points, opts.xs_weight); % disp(pm_mx{ix});
        %L.pm = filter_pm(L.pm);
        if opts.use_peg
            L = add_translation_peggs(L, opts.peg_npoints, opts.peg_weight);
        end
        [L, ntiles] = reduce_to_connected_components(L);
        L = L(1);
        [Lr, errR, mL, is, it, Res]  = get_rigid_approximation(L, opts.solver);
        %%% remove peggs and last tile
        last_tile = numel(Lr.tiles);
        del_ix = find(Lr.pm.adj(:,2)==last_tile);
        Lr.pm.M(del_ix,:)  = [];
        Lr.pm.adj(del_ix,:) = [];
        Lr.pm.W(del_ix) = [];
        Lr.pm.np(del_ix) = [];
        Lr.tiles(end) = [];
        Lr = update_adjacency(Lr);
        
        
        [mLra, err1{lix}, Res1{lix}, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
            invalid] = solve_affine_explicit_region(Lr, opts);
        
        [mLra, A, S] = filter_based_on_tile_area(mLra, opts.outlier_lambda);



































