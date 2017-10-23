function [] = Register_fine(slabs, slab_def_fn, slabs_dir, opts_fn)
    % Register fine alignment collections for the specified slabs
    % Input: slabs for which to register the rough alignment
    %        slab_def_fn - slab definition file name
    %        slabs_dir where to store serialized matlab slabs
    %        opts_fn json config file
    % Output: (none)

    if nargin < 1, error('Missing slabs argument'); end
    if nargin < 2, error('Missing rough slabs definition file argument'); end
    if nargin < 3, slabs_dir = ''; end

    if ischar(slabs)
        if isempty(slabs)
            slabs = (1:numel(slabs));
        else
            slabs = eval(slabs);
        end
    end

    if isempty(slabs_dir)
        slabs_dir = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_slabs/fine_alignment';
    end
    fine_slab_defs = loadjson(fileread(slab_def_fn)); % read rough slab definitions

    default_rs = struct();
    rs_source_opts = struct();
    rs_rough_opts = struct();
    pm_opts = struct();
    pm_filter_opts = struct();
    solver_opts = struct();

    if nargin >= 4
        fine_align_opts = loadjson(fileread(opts_fn));
        if isfield(fine_align_opts, 'default_rs')
            default_rs = fine_align_opts.default_rs;
        end
        if isfield(fine_align_opts, 'rs_acq_collection')
            rs_source_opts = fine_align_opts.rs_acq_collection;
        end
        if isfield(fine_align_opts, 'rs_rough_collection')
            rs_rough_opts = fine_align_opts.rs_rough_collection;
        end
        if isfield(fine_align_opts, 'pm_opts')
            pm_opts = fine_align_opts.pm_opts;       
        end
        if isfield(fine_align_opts, 'pm_filter_opts')
            pm_filter_opts = fine_align_opts.pm_filter_opts;       
        end
        if isfield(fine_align_opts, 'solver_opts')
            solver_opts = fine_align_opts.solver_opts;       
        end
    end

    % configure default renderer server
    default_rs.owner = eval_field(default_rs, 'owner', 'flyTEM', true);
    default_rs.project = eval_field(default_rs, 'project', 'test2', true);
    default_rs.service_host = eval_field(default_rs, 'service_host', '10.40.3.162:8080', true);
    default_rs.baseURL = ['http://' default_rs.service_host '/render-ws/v1'];
    default_rs.verbose = eval_field(default_rs, 'verbose', 1);

    % configure acquisition collection
    rcsource.stack = eval_field(rs_source_opts, 'stack', 'v12_acquire_merged', true);
    rcsource.owner = eval_field(rs_source_opts, 'owner', 'flyTEM', true);
    rcsource.project = eval_field(rs_source_opts, 'project', 'test2', true);
    rcsource.service_host = eval_field(rs_source_opts, 'service_host', '10.40.3.162:8080', true);
    rcsource.baseURL = ['http://' rcsource.service_host '/render-ws/v1'];
    rcsource.verbose = eval_field(rs_source_opts, 'verbose', 1, false);

    % configure rough collection
    rcrough.stack = eval_field(rs_rough_opts, 'stack', 'v12_acquire_merged', true);
    rcrough.owner = eval_field(rs_rough_opts, 'owner', 'flyTEM', true);
    rcrough.project = eval_field(rs_rough_opts, 'project', 'test2', true);
    rcrough.service_host = eval_field(rs_rough_opts, 'service_host', '10.40.3.162:8080', true);
    rcrough.baseURL = ['http://' rcrough.service_host '/render-ws/v1'];
    rcrough.verbose = eval_field(rs_rough_opts, 'verbose', 1, false);

    % configure point-match collection
    pm.server = eval_field(pm_opts, 'server', 'http://10.40.3.162:8080/render-ws/v1', true);
    pm.owner = eval_field(pm_opts, 'owner', 'flyTEM', true);
    pm.match_collection = eval_field(pm_opts, 'match_collection', 'v12_dmesh', true);

    %% configure solver
    opts.min_tiles = eval_field(solver_opts, 'min_tiles', 20); % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
    opts.degree = eval_field(solver_opts, 'degree', 1); % degree: 1 = affine, 2 = second order polynomial, maximum is 3
    opts.outlier_lambda = eval_field(solver_opts, 'outlier_lambda', 1e2); % outlier_lambda: large numbers result in fewer tiles excluded
    opts.lambda = eval_field(solver_opts, 'lambda', 10^(-2));
    opts.edge_lambda = eval_field(solver_opts, 'edge_lambda', 10^(-2));
    opts.solver = eval_field(solver_opts, 'solver', 'backslash', true);
    opts.min_points = eval_field(solver_opts, 'min_points', 5);
    opts.nbrs = eval_field(solver_opts, 'nbrs', 4);
    opts.xs_weight = eval_field(solver_opts, 'xs_weight', 1);
    opts.stvec_flag = eval_field(solver_opts, 'stvec_flag', 1); % 0 - do not assume rcsource providing the starting values.
    opts.distributed = eval_field(solver_opts, 'distributed', 1); % 1 - use distributed solver
    opts.conn_comp = eval_field(solver_opts, 'conn_comp', 0);
    opts.filter_pm = eval_field(solver_opts, 'filter_pm', 1);
    opts.use_peg = eval_field(solver_opts, 'use_peg', 0);
    opts.peg_weight = eval_field(solver_opts, 'peg_weight', 1e-3);
    opts.peg_npoints = eval_field(solver_opts, 'peg_npoints', 5);

    fine_slab_defs = validate_slabs(fine_slab_defs, default_rs);

    failed = [];

    for si = 1:numel(slabs)
        ix = slabs(si);

        nfirst = fine_slab_defs{ix}.slab_start;
        nlast = fine_slab_defs{ix}.slab_end;

        % configure align collection
        rctarget_align = fine_slab_defs{ix}.slab_collection;

        try
            disp('---------------');
            disp('Processing:');
            disp(rcrough);
            disp(ix);
            disp('---------------');

            %% read point-matches and filter them
            [L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
                load_point_matches(nfirst, nlast, rcrough, pm, opts.nbrs, ...
                opts.min_points, opts.xs_weight);

            ntiles = max(L.pm.adj(:));
            if ntiles ~= numel(L.tiles)
                disp('Discrepancy between number of tiles and availability of point-matches');
            end

            if opts.filter_pm
                disp('Filtering point-matches');
                L.pm = filter_pm(L.pm, pm_filter_opts);
            end

            % save starting
            str = sprintf('save %s rcsource rctarget_align L nfirst nlast pm opts;',...
                ['Read_EXP_dmesh_rough_P1_' num2str(nfirst) '_' num2str(nlast) '.mat']);
            disp(['Saving starting slab ' str]);
            dir_curr = pwd;
            cd(slabs_dir);
            eval(str);
            cd(dir_curr);

            %% start actual solver process
            if opts.degree==1
                disp('----------------- Solving using affine model:');
                tic
                [mL, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td, invalid] = solve_affine_explicit_region(L, opts);
                toc
                disp('Done!');
            else
                disp('----------------- Solving using polynomial degree:');
                tic
                disp(opts.degree);
                [mL, err1, Res1] = solve_polynomial_explicit_region(L, opts.degree, opts);
                toc
                disp('Done!');
            end
            %% save solution
            try
                disp('Saving solution slab');
                kk_clock;
                dir_curr = pwd;
                cd(slabs_dir);
                str = sprintf('save %s rcsource rctarget_align mL A d xout nfirst nlast pm opts err1 Res1;',...
                    ['Solved_PRD_dmesh_fine_P1_' num2str(nfirst) '_' num2str(nlast) '_xs_2']);
                eval(str);
                cd(dir_curr);
                kk_clock;
                disp('Done!');
            catch err_saving
                disp('Error saving solution slab')
                kk_disp_err(err_saving);
            end
            %% ingest affine solution
            try
                ingest_section_into_renderer_database_overwrite(mL, rctarget_align, rcsource, pwd, 1);
            catch err_ingesting
                disp(['Error ingesting affine: ' num2str(nfirst) ]);
                kk_disp_err(err_ingesting);
            end
            disp('Error in pixels per tile:');
            disp(err1/numel(mL.tiles));
        catch err_solving
            kk_disp_err(err_solving);
            failed = [failed ix];
        end
    end
    failed(failed==0) = [];  % delete zero entries in failed_list
    if ~isempty(failed)
        disp('---------- Set of failed sections ----------');
        disp(failed);
    end

end
