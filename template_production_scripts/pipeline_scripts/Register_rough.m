function [] = Register_rough(slabs, slab_def_fn, rough_slabs_dir, intermediate_store_dir, opts_fn)
    % Register rough alignment collections for the specified slabs
    % Input: slabs for which to register the rough alignment
    %        slab_def_fn - slab definition file name
    %        intermediate_store_dir where to store intermediate data
    %        opts_fn json config file
    % Output: (none)

    if nargin < 1, error('Missing slabs argument'); end
    if nargin < 2, error('Missing slab definition file argument'); end
    if nargin < 3, rough_slabs_dir = ''; end
    if nargin < 4, intermediate_store_dir = ''; end

    %% general configuration
    if ischar(slabs)
        if isempty(slabs)
            slabs = (1:numel(slabs));
        else
            slabs = eval(slabs);
        end
    end

    if isempty(rough_slabs_dir)
        rough_slabs_dir = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_slabs/rough';
    end
    if isempty(intermediate_store_dir)
        intermediate_store_dir = '/nobackup/flyTEM/khairy/FAFB00v13/montage_scape_pms';
    end

    rough_slab_defs = loadjson(fileread(slab_def_fn)); % read slab definitions

    default_rs = struct();
    rs_source_opts = struct();
    rs_montage_opts = struct();
    msopts = struct();

    if nargin >= 4
        rough_align_opts = loadjson(fileread(opts_fn));
        if isfield(rough_align_opts, 'default_rs')
            default_rs = rough_align_opts.default_rs;
        end
        if isfield(rough_align_opts, 'rs_acq_collection')
            rs_source_opts = rough_align_opts.rs_acq_collection;
        end
        if isfield(rough_align_opts, 'rs_montage_collection')
            rs_montage_opts = rough_align_opts.rs_montage_collection;
        end
        if isfield(rough_align_opts, 'montage_scape_options')
            msopts = rough_align_opts.montage_scape_options;
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
    rcsource.verbose = eval_field(rs_source_opts, 'verbose', 1);

    % configure montage collection
    rctarget_montage.stack = eval_field(rs_montage_opts, 'stack', 'EXP_dmesh_montage_P1_peg', true);
    rctarget_montage.owner = eval_field(rs_montage_opts, 'owner', 'flyTEM', true);
    rctarget_montage.project = eval_field(rs_montage_opts, 'project', 'test2', true);
    rctarget_montage.service_host = eval_field(rs_montage_opts, 'service_host', '10.40.3.162:8080', true);
    rctarget_montage.baseURL = ['http://' rctarget_montage.service_host '/render-ws/v1'];
    rctarget_montage.verbose = eval_field(rs_montage_opts, 'verbose', 1);

    % configure montage-scape point-match generation
    ms.service_host = rctarget_montage.service_host;
    ms.owner = rctarget_montage.owner;
    ms.project = rctarget_montage.project;
    ms.stack = rctarget_montage.stack;
    ms.verbose = rctarget_montage.verbose;

    ms.fd_size = eval_field(msopts, 'fd_size', '10', true);
    ms.min_sift_scale = eval_field(msopts, 'min_sift_scale', '0.2', true);
    ms.max_sift_scale = eval_field(msopts, 'max_sift_scale', '1.0', true);
    ms.steps = eval_field(msopts, 'steps', '3', true);
    ms.similarity_range = eval_field(msopts, 'similarity_range', '15', true);
    ms.skip_similarity_matrix = eval_field(msopts, 'skip_similarity_matrix', 'y', true);
    ms.skip_aligned_image_generation = eval_field(msopts, 'skip_aligned_image_generation', 'y', true);
    ms.base_output_dir = eval_field(msopts, 'base_output_dir', '/nobackup/flyTEM/spark_montage', true);
    ms.script = eval_field(msopts, 'script', '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh', true);
    ms.number_of_spark_nodes = eval_field(msopts, 'number_of_spark_nodes', '2.0', true);

    rough_slab_defs = validate_slabs(rough_slab_defs, default_rs);

    %% %% calculate rough alignment, solve and generate renderer collection
    failed = []; % list failures

    for si = 1:numel(slabs)
        ix = slabs(si);
        kk_clock;
        % configure rough collection
        rctarget_rough = rough_slab_defs{ix}.slab_collection;

        ms_slab = ms;
        ms_slab.first = num2str(rough_slab_defs{ix}.slab_start);
        ms_slab.last = num2str(rough_slab_defs{ix}.slab_end);
        ms_slab.scale = num2str(rough_slab_defs{ix}.slab_scale_factor);
        ms_slab.run_dir = ['Slab_' num2str(ix) '_' ms_slab.first '_' ms_slab.last '_scale_' ms_slab.scale];
        run_now = rough_slab_defs{ix}.run_rough_align;
        disp(['-------------------- Processing slab: ' ms_slab.first ' to ' ms_slab.last ' at scale ' ms_slab.scale]);
        % do the actual slab solve
        try
            [L2, needs_correction, pmfn, zsetd, zrange, t, dir_spark_work, cmd_str, fn_ids, ...
             target_solver_path, target_ids, target_matches, target_layer_images] =  ...
            solve_rough_slab(rough_slabs_dir, rcsource, ...
                             rctarget_montage, rctarget_rough, ms_slab, ...
                             rough_slab_defs{ix}.slab_start, rough_slab_defs{ix}.slab_end, ...
                             intermediate_store_dir, ...
                             run_now);
        catch err_rough
            kk_disp_err(err_rough);
            failed = [failed ix];
        end
        kk_clock;
    end
    failed(failed==0) = [];  % delete zero entries in failed_list
    if ~isempty(failed)
        disp('---------- Set of failed sections ----------');
        disp(failed);
    end
end