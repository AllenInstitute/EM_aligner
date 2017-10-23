% Example script to solve a FAFBv12 slab for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%% [0] configure collections and prepare quantities
clc;kk_clock;

nfirst = 1000;
nlast  = 1200;

% % configure source collection
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;


% configure source collection
rcsource.stack          = 'EXP_dmesh_rough_1_1000_1200';
rcsource.owner          ='flyTEM';
rcsource.project        = 'test';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure align collection
rctarget_align.stack          = ['EXP_dmesh_P1_' num2str(nfirst) '_' num2str(nlast)];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';

% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';
opts.min_points = 5;
opts.nbrs = 4;
opts.xs_weight = 1/50;
opts.stvec_flag = 0;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 1;

%%
opts.lambda = 10^(-1);
opts.edge_lambda = 10^(-1);

opts.base_collection = [];
opts.conn_comp = 0;
opts.use_peg = 0;
opts.peg_weight = 1e-3;
opts.peg_npoints = 5;



% % % % test for best regularization parameter
% % % % This is the smallest that does not cause shrinkage of tiles
% % regstart = -2;
% % regfinish = 5;
% % step = 0.5;
% % 
% % %[L, ~, ~, pm_mx] = load_point_matches(nfirst, nlast, rcsource, pm, opts.nbrs, opts.min_points, opts.xs_weight); % disp(pm_mx{ix});
% % 
% % 
% % [L, L_vec, pm_mx, err, scl, h] = ...
% %     solver_regularization_parameter_sweep(nfirst, nlast, rcsource, pm, ...
% %                                           opts, regstart, regfinish, step);

[L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
            load_point_matches(nfirst, nlast, rcsource, pm, opts.nbrs, ...
            opts.min_points, opts.xs_weight); % disp(pm_mx{ix});
L.pm = filter_pm(L.pm);

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
        
        
        [mLra, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
            invalid] = solve_affine_explicit_region(Lr, opts);
        
        
%         [mLrap2, err2, Res2] =...
%             solve_polynomial_explicit_region(mLra,opts.degree, optsp2);
% 
%         [mLrap3, err3, Res3] =...
%             solve_polynomial_explicit_region(mLra,opts.degree, optsp3);
%         
%         disp(sum([Res1 Res2 Res3].^2));
%         disp([err1 err2 err3]);
%         %[Lr, A, err, R]= solve_slab(rcsource, pm, lix, lix, [], opts);
        
        [mLra, A, S] = filter_based_on_tile_area(mLra, opts.outlier_lambda);
%         [mLrap2, A, S] = filter_based_on_tile_area(mLrap2, optsp2.outlier_lambda);
%         [mLrap3, A, S] = filter_based_on_tile_area(mLrap3, optsp3.outlier_lambda);
        
          %zmL = split_z(mLra);
          %show_map(zmL(1));
        %%%%% ingest affine solution
        try
            ingest_section_into_renderer_database_overwrite(mLra, rctarget_align, rcsource, pwd, 1);
            %resp = set_renderer_stack_state_complete(rctarget_montage);
        catch err_ingesting
            
            disp(['Error ingesting affine: ' num2str(nfirst) ]);
            kk_disp_err(err_ingesting);
        end
        
%% solve
% 
% opts.lambda = 10^(-1);
% opts.edge_lambda = 10^(-1);
%  [mL2, A]= solve_slab(rcsource, pm, nfirst, nlast, rctarget_align, opts);
% %[mL2, err_res, R] = solve_clusters(L_vec, opts, opts.stvec_flag);   % solves individual clusters and reassembles them into one
% % 
% delete_renderer_stack(rctarget_align);
% ingest_section_into_LOADING_collection(mL2, rctarget_align, rcsource, pwd, 1);
% resp = set_renderer_stack_state_complete(rctarget_align);
% kk_clock;
% render

















