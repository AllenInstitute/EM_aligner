clc; clear all;
kk_clock;
nfirst = 1;
nlast  = 50;


% configure source collection
rcsource.stack          = 'v12_acquire_merged_fix_1_00';
rcsource.owner          ='flyTEM';
rcsource.project        = 'test_2';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure montage collection
rctarget_montage.stack          = ['EXP_dmesh_montage_P1_peg_fix_1_00'];
rctarget_montage.owner          ='flyTEM';
rctarget_montage.project        = 'test_2';
rctarget_montage.service_host   = '10.37.5.60:8080';
rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
rctarget_montage.verbose        = 1;

% % configure montage collection
% rctarget_montagep2.stack          = ['EXP_dmesh_montage_P2_peg'];
% rctarget_montagep2.owner          ='flyTEM';
% rctarget_montagep2.project        = 'test';
% rctarget_montagep2.service_host   = '10.37.5.60:8080';
% rctarget_montagep2.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
% rctarget_montagep2.verbose        = 1;
% 
% % configure montage collection
% rctarget_montagep3.stack          = ['EXP_dmesh_montage_P3_peg'];
% rctarget_montagep3.owner          ='flyTEM';
% rctarget_montagep3.project        = 'test';
% rctarget_montagep3.service_host   = '10.37.5.60:8080';
% rctarget_montagep3.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
% rctarget_montagep3.verbose        = 1;


% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';


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


optsp2 = opts;
optsp2.outlier_lambda = 1e1;
optsp2.degree = 2;
optsp2.lambda = 10^(5);
optsp2.edge_lambda = 10^6;

optsp3 = opts;
optsp3.outlier_lambda = 1e1;
optsp3.degree = 3;
optsp3.lambda = 10^(7);
optsp3.edge_lambda = 10^8;


lix = 1;

% solve montages and ingest into collection
%% delete existing collection if present
% resp = delete_renderer_stack(rctarget_montage);
% resp = create_renderer_stack(rctarget_montage);

%%
err = {};
R = {};
failed_list = [];
count = 1;
parfor lix = 1:50
    disp(['Solving section: ' num2str(lix) ' of ' num2str(nlast)]);
    try
        %[mL1, A, err{lix}, R{lix}]= solve_slab(rcsource, pm, lix, lix, [], opts);
        
        
        %     [L_vec, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
        %                    load_point_matches(lix, lix, rcsource, pm, opts.nbrs, opts.min_points, opts.xs_weight);
        %     L_vect = add_translation_peggs(L_vec, opts.peg_npoints, opts.peg_weight);
        %
        %
        
        %%
        %load L4;
        %   L4a = add_translation_peggs(L4, opts.peg_npoints, opts.peg_weight);
        %  [L4ar, errR, mL, is, it, Res]  = get_rigid_approximation(L4a, opts.solver);
        
        %%
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
        
        
        %%%%% ingest affine solution
        try
            ingest_section_into_LOADING_collection(mLra, rctarget_montage, rcsource, pwd, 1);
            %resp = set_renderer_stack_state_complete(rctarget_montage);
        catch err_ingesting
            
            disp(['Error ingesting affine: ' num2str(lix) ]);
            kk_disp_err(err_ingesting);
        end
        
%         %%% ingest second order polynomial solution
%         try
%             ingest_section_into_LOADING_collection(mLrap2, rctarget_montagep2, rcsource, pwd, 1);
%             %resp = set_renderer_stack_state_complete(rctarget_montage);
%         catch err_ingesting
%             
%             disp(['Error ingesting second order polynomial: ' num2str(lix) ]);
%             kk_disp_err(err_ingesting);
%         end
%         
%         %%% ingest third order polynomial solution
%         try
%             ingest_section_into_LOADING_collection(mLrap3, rctarget_montagep3, rcsource, pwd, 1);
%             %resp = set_renderer_stack_state_complete(rctarget_montage);
%         catch err_ingesting
%             
%             disp(['Error ingesting third order polynomial: ' num2str(lix) ]);
%             kk_disp_err(err_ingesting);
%         end
        
        
    catch err_solving
        disp(['************ Error solving: ' num2str(lix) ]);
        kk_disp_err(err_solving);
        failed_list = [failed_list lix];
    end
    
    
end
%%
resp = set_renderer_stack_state_complete(rctarget_montage);
% resp = set_renderer_stack_state_complete(rctarget_montagep2);
% resp = set_renderer_stack_state_complete(rctarget_montagep3);
kk_clock;
%resp = set_renderer_stack_state_complete(rctarget_montage);
%%
% delete_renderer_stack(rctarget_montage);
% delete_renderer_stack(rctarget_montagep2);
% delete_renderer_stack(rctarget_montagep3);
% 
% 



























