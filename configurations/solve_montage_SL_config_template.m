%% define options struct

% solver options
sl.solver_options.degree                = 1;
sl.solver_options.solver                = 'backslash';
sl.solver_options.min_points            = 10;
sl.solver_options.max_points            = 100;
sl.solver_options.lambda                = 0.1;              % regularization parameter
sl.solver_options.edge_lambda           = 0.1;
sl.solver_options.translation_fac       = 1;
sl.solver_options.use_peg               = 1;                % peg
sl.solver_options.peg_weight            = 1e-1;            % peg
sl.solver_options.peg_npoints           = 5;                % peg

sl.solver_options.outlier_lambda        = 1000;
sl.solver_options.small_region          = 5;
sl.solver_options.calc_confidence       = 1;
sl.solver_options.small_region_lambda   = 10;
sl.solver_options.stvec_flag            = 0;
sl.solver_options.conn_comp             = 1;
sl.solver_options.distributed           = 0;
sl.solver_options.min_tiles             = 3;

% configure source collection
sl.source_collection.stack          = 'v12_acquire_merged';
sl.source_collection.owner          = 'flyTEM';
sl.source_collection.project        = 'FAFB00';
sl.source_collection.service_host   = '10.37.5.60:8080';
sl.source_collection.baseURL        = 'http://10.37.5.60:8080/render-ws/v1';
sl.source_collection.verbose        = 0;

% configure target collection
sl.target_collection.stack          = 'EXP_montage_section_2880';
sl.target_collection.owner          = 'flyTEM';
sl.target_collection.project        = 'test';
sl.target_collection.service_host   = '10.37.5.60:8080';
sl.target_collection.baseURL        = 'http://10.37.5.60:8080/render-ws/v1';
sl.target_collection.versionNotes   = 'experiments to optimize general section montaging';
sl.target_collection.verbose        = 0;

% configure point-match collection(s)
clear pm;
pmix = 1;
pm(pmix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(pmix).owner  = 'flyTEM';
pm(pmix).match_collection = 'FAFB_pm_2';
pmix = pmix + 1;
sl.source_point_match_collection = pm;

% other configurations
sl.z_value = 2880;
sl.filter_point_matches = 1;
sl.temp_dir = '/scratch/khairyk';
sl.verbose = 0;

%% call solve_montage_SL
solve_montage_SL(sl);

%% generate diagnostics
dopts.nbrs = 0;
dopts.min_points = 3;
dopts.show_deformation = 1;
dopts.show_residuals = 1;
dopts.show_deformation_summary = 0;

[mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, tidsvec, section_conf ] =...
    gen_diagnostics(sl.source_collection,...
                    sl.target_collection,...
                   sl.z_value, ...
                   sl.z_value, ...
                   sl.source_point_match_collection,...
                   dopts);
figure;hist(section_conf,100);title('Residual histogram');
figure;hist(tile_areas{1},100);title('Areas histogram');
median(section_conf)
%%
del_ix = find(section_conf>9.0);
del_tids = tidsvec{1}(del_ix);
delete_renderer_tiles(sl.target_collection, del_tids);  %%% 

%% evaluate regularization parameter
dopts.nbrs = 0;
dopts.min_points = 3;
dopts.show_deformation = 0;
dopts.show_residuals = 0;
dopts.show_deformation_summary = 0;
for lix = -2:2
    sl.solver_options.lambda = 10^(lix);   % set regularization parameter
    sl.solver_options.edge_lambda = sl.solver_options.lambda; % set both lambdas equal
    solve_montage_SL(sl);

    [mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, tidsvec, Resx,Resy] =...
    gen_diagnostics(sl.source_collection,...
                    sl.target_collection,...
                   sl.z_value, ...
                   sl.z_value, ...
                   sl.source_point_match_collection,...
                   dopts);
end






