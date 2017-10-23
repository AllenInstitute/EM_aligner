function [] = Register_montage(nfirst, nlast, opts_fn)
% Register rough montage collections for the specified slabs
% Input: nfirst - first section to montage
%        nlast - last section to montage
%        opts_fn json config file
% Output: (none)

if nargin < 2, error('Missing section interval: first section and last section'); end

rs_source_opts = struct();
rs_target_opts = struct();
pm_opts = struct();
pm_filter_opts = struct();
solver_opts = struct();
verbose = true;

if nargin >= 3
    montage_opts = loadjson(fileread(opts_fn));
    if isfield(montage_opts, 'rs_acq_collection')
        rs_source_opts = montage_opts.rs_acq_collection;
    end
    if isfield(montage_opts, 'rs_montage_collection')
        rs_target_opts = montage_opts.rs_montage_collection;
    end
    if isfield(montage_opts, 'pm_opts')
        pm_opts = montage_opts.pm_opts;
    end
    if isfield(montage_opts, 'pm_filter_opts')
        pm_filter_opts = montage_opts.pm_filter_opts;
    end
    if isfield(montage_opts, 'solver_opts')
        solver_opts = montage_opts.solver_opts;
    end
    if isfield(montage_opts, 'verbose')
        verbose = montage_opts.verbose;
    end
end

if ischar(nfirst)
    nfirst = str2double(nfirst);
end
if ischar(nlast)
    nlast = str2double(nlast);
end

% configure source collection
rcsource.stack = eval_field(rs_source_opts, 'stack', 'v12_acquire_merged_fix_1_00', true);
rcsource.owner = eval_field(rs_source_opts, 'owner', 'flyTEM', true);
rcsource.project = eval_field(rs_source_opts, 'project', 'test2', true);
rcsource.service_host = eval_field(rs_source_opts, 'service_host', '10.40.3.162:8080', true);
rcsource.baseURL = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose = eval_field(rs_source_opts, 'verbose', 1, false);

% configure montage collection
rctarget_montage.stack = eval_field(rs_target_opts, 'stack', 'EXP_dmesh_montage_P1_peg', true);
rctarget_montage.owner = eval_field(rs_target_opts, 'owner', 'flyTEM', true);
rctarget_montage.project = eval_field(rs_target_opts, 'project', 'test2', true);
rctarget_montage.service_host = eval_field(rs_target_opts, 'service_host', '10.40.3.162:8080', true);
rctarget_montage.baseURL = ['http://' rctarget_montage.service_host '/render-ws/v1'];
rctarget_montage.verbose = eval_field(rs_target_opts, 'verbose', 1);

% configure point-match collection
pm.server = eval_field(pm_opts, 'server', 'http://10.40.3.162:8080/render-ws/v1', true);
pm.owner = eval_field(pm_opts, 'owner', 'flyTEM', true);
pm.match_collection = eval_field(pm_opts, 'match_collection', 'v12_dmesh', true);
pm.verbose = eval_field(pm_opts, 'verbose', 0);

% pm filter options
pm_filter_opts.NumRandomSamplingsMethod = eval_field(pm_filter_opts, 'NumRandomSamplingsMethod', 'Desired confidence', true);
pm_filter_opts.MaximumRandomSamples = eval_field(pm_filter_opts, 'MaximumRandomSamples', 3000);
pm_filter_opts.DesiredConfidence = eval_field(pm_filter_opts, 'DesiredConfidence', 99.8); % typical values 99.5 to 99.9, the higher the stricter
pm_filter_opts.PixelDistanceThreshold = eval_field(pm_filter_opts, 'PixelDistanceThreshold', 0.01);% typical values 0.001 to 1.0, the lower the stricter

% configure solver
opts.min_tiles = eval_field(solver_opts, 'min_tiles', 2); % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = eval_field(solver_opts, 'degree', 1); % degree: 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = eval_field(solver_opts, 'outlier_lambda', 1e1); % outlier_lambda: large numbers result in fewer tiles excluded
opts.lambda = eval_field(solver_opts, 'lambda', 10^(-1));
opts.edge_lambda = eval_field(solver_opts, 'edge_lambda', 10^(-1));
opts.solver = eval_field(solver_opts, 'solver', 'backslash', true);
opts.min_points = eval_field(solver_opts, 'min_points', 3);
opts.max_points = eval_field(solver_opts, 'max_points', 10000);
opts.nbrs = eval_field(solver_opts, 'nbrs', 0);
opts.xs_weight = eval_field(solver_opts, 'xs_weight', 1/100);
opts.stvec_flag = eval_field(solver_opts, 'stvec_flag', 0); % 0 - do not assume rcsource providing the starting values.
opts.distributed = eval_field(solver_opts, 'distributed', 1); % 1 - use distributed solver
opts.conn_comp = eval_field(solver_opts, 'conn_comp', 1);
opts.filter_pm = eval_field(solver_opts, 'filter_pm', 1);
opts.use_peg = eval_field(solver_opts, 'use_peg', 1);
opts.peg_weight = eval_field(solver_opts, 'peg_weight', 1e-4);
opts.peg_npoints = eval_field(solver_opts, 'peg_npoints', 5);

if verbose > 0
    disp('Source collection:');
    disp(rcsource);
    disp('Target collection:');
    disp(rctarget_montage);
    disp('Point match options:');
    disp(pm);
    disp('Point match filter options:');
    disp(pm_filter_opts);
    disp('Solver options:');
    disp(opts);
end

% create the target stack otherwise it may get created multiple times
% inside the parallel loop
if ~stack_exists(rctarget_montage)
    create_renderer_stack(rctarget_montage);
end

%% solve montages and ingest into collection
kk_clock;
failed_list = zeros(numel(nfirst:nlast),1);

[zu, sID, sectionId, z, ns] = get_section_ids(rcsource, nfirst, nlast);
parfor lix = 1:numel(zu)
    %disp(['Solving section: ' num2str(lix) ' of ' num2str(numel(zu)) ' with z of ' num2str(zu(lix)) ]);
    try
        %%
        [L, tIds, PM, pm_mx, sectionId_load, z_load]= ...
        load_point_matches(zu(lix), zu(lix), rcsource, pm, opts.nbrs, opts.min_points, opts.xs_weight, opts.max_points);
        if opts.filter_pm
            L.pm = filter_pm(L.pm, pm_filter_opts);
            if L.pm.verbose > 2
                logInfo = struct();
                logInfo.info = ['Section ' num2str(lix) ' point matches after filtering'];
                logInfo.nPointMatches = table([L.pm.adj(:, 1), L.pm.adj(:, 2) L.pm.np]);
                disp(logInfo);
                disp(logInfo.nPointMatches)
                if L.pm.verbose > 3
                    for tpix = 1:size(L.pm.adj, 1)
                        disp(['Tile pair ' num2str(L.pm.adj(1,1)) ',' num2str(L.pm.adj(1,2))]);
                        disp(table(L.pm.M{tpix, 1}, L.pm.M{tpix, 2}, 'VariableNames', {'P', 'Q'}));
                    end
                end
            end
        end
        if opts.use_peg
            L = add_translation_peggs(L, opts.peg_npoints, opts.peg_weight);
        end
        [L, ntiles] = reduce_to_connected_components(L);
        L = L(1);
        % solve rigid problem
        [Lr, errR, mL, is, it, Res]  = get_rigid_approximation(L, opts.solver, opts);
        
        if opts.use_peg
            %% remove peggs and last tile
            last_tile = numel(Lr.tiles);
            del_ix = find(Lr.pm.adj(:,2)==last_tile);
            Lr.pm.M(del_ix,:)  = [];
            Lr.pm.adj(del_ix,:) = [];
            Lr.pm.W(del_ix) = [];
            Lr.pm.np(del_ix) = [];
            Lr.tiles(end) = [];
            Lr = update_adjacency(Lr);
        end
        
        % solve affine problem
        [mLra, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,invalid] = ...
            solve_affine_explicit_region(Lr, opts);
        [mLra, A, S] = filter_based_on_tile_area(mLra, opts.outlier_lambda);
        
        if opts.degree > 1
            [mLra, err2, Res2] =...
                solve_polynomial_explicit_region(mLra, opts.degree, opts);
            disp(sum([Res1 Res2].^2));
            disp([err1 err2])
        end
        
        %% ingest affine solution
        try
            ingest_section_into_LOADING_collection(mLra, rctarget_montage, rcsource, pwd, 1);
        catch err_ingesting
            disp(['Error ingesting affine: ' num2str(lix) ]);
            kk_disp_err(err_ingesting);
        end
    catch err_solving
        disp(['************ Error solving: ' num2str(lix) ]);
        kk_disp_err(err_solving);
        failed_list(lix) = lix;
    end
    
end
failed_list(failed_list==0) = [];  % delete zero entries in failed_list
if ~isempty(failed_list)
    disp('---------- Set of failed sections ----------');
    disp(failed_list);
end
%%
disp(['Complete ' rctarget_montage.stack])
resp = set_renderer_stack_state_complete(rctarget_montage);
kk_clock;
end
