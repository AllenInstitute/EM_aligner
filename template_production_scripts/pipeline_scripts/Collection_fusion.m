function [] = Collection_fusion(start_slab, end_slab, slab_def_fn, opts_fn)
    %% get the input args
    if nargin < 2, error('Start and end  slabs must be specified'); end
    if nargin < 3, error('Missing rough slabs definition file argument'); end

    if ischar(start_slab)
        start_slab = str2double(start_slab);
    end
    if ischar(end_slab)
        end_slab = str2double(end_slab);
    end

    if start_slab < 2
       error('Start slab must be larger than or equal to 2');
    end
    if start_slab > end_slab
       error('Start slab cannot be larger than the end slab');
    end

    slab_defs = loadjson(fileread(slab_def_fn));

    rcout_opts = struct();
    default_rs = struct();
    rs_source_opts = struct();

    if nargin >= 4
        fusion_opts = loadjson(fileread(opts_fn));
        if isfield(fusion_opts, 'rs_fused_collection')
            rcout_opts = fusion_opts.rs_fused_collection;
        end
        if isfield(fusion_opts, 'default_rs')
            default_rs = fusion_opts.default_rs;
        else
            default_rs = rcout_opts;
        end
        if isfield(fusion_opts, 'rs_acq_collection')
            rs_source_opts = fusion_opts.rs_acq_collection;
        end
    end
    nworkers = eval_field(rcout_opts, 'nworkers', 0);
    cluster_profile = eval_field(rcout_opts, 'cluster_profile', '', true);

    slab_defs = validate_slabs(slab_defs, default_rs);

    % configure acquisition collection
    rcsource.stack = eval_field(rs_source_opts, 'stack', 'v12_acquire_merged', true);
    rcsource.owner = eval_field(rs_source_opts, 'owner', 'flyTEM', true);
    rcsource.project = eval_field(rs_source_opts, 'project', 'test2', true);
    rcsource.service_host = eval_field(rs_source_opts, 'service_host', '10.40.3.162:8080', true);
    rcsource.baseURL = ['http://' rcsource.service_host '/render-ws/v1'];
    rcsource.verbose = eval_field(rs_source_opts, 'verbose', 1);

    %% configure fixed collection
    rcfixed_o.stack = eval_field(rcout_opts, 'stack', 'v14_fused', true);
    rcfixed_o.owner = eval_field(rcout_opts, 'owner', 'flyTEM', true);
    rcfixed_o.project = eval_field(rcout_opts, 'project', 'test2', true);
    rcfixed_o.service_host = eval_field(rcout_opts, 'service_host', '10.40.3.162:8080', true);
    rcfixed_o.baseURL = ['http://' rcfixed_o.service_host '/render-ws/v1'];
    rcfixed_o.verbose = eval_field(rcout_opts, 'verbose', 1, false);
    rcfixed_o.grid_account = eval_field(rcout_opts, 'grid_account', '', true);
    rcfixed_o.grid_user = eval_field(rcout_opts, 'grid_user', '', true);
    if nworkers > 0
        % set the parpool
        delete(gcp('nocreate'));  % close current pool if it exists
        if strcmp(cluster_profile, '')
            cluster_profile = parallel.defaultClusterProfile;
        end
        disp(['Set parallel pool profile to ' cluster_profile]);
        myCluster = parcluster(cluster_profile);
        parpool(myCluster, nworkers);
        poolobj = gcp('nocreate');
        disp(['Parallel pool created. Pool size: ' num2str(poolobj.NumWorkers)]);
    end

    disp(['Fuse ' num2str(start_slab) ' ' num2str(end_slab)])
    disp('RC OUT: ')
    disp(rcfixed_o)

    %% fuse slabs
    kk_clock;
    for ix = [start_slab:end_slab]
        if ix < 2
            error('ix must be larger than or equal to 2');
        elseif ix == 2
            %  use the first collection as fixed
            rcfixed = slab_defs{1}.slab_collection;
        else
            rcfixed = rcfixed_o;
        end
        rcfixed.nfirst = slab_defs{ix-1}.slab_start;
        rcfixed.nlast = slab_defs{ix-1}.slab_end;
        % configure collection
        rcmoving = slab_defs{ix}.slab_collection;
        rcmoving.nfirst = slab_defs{ix}.slab_start;
        rcmoving.nlast = slab_defs{ix}.slab_end;

        % configure output collection
        rcout = rcfixed_o;
        overlap = [slab_defs{ix}.slab_start slab_defs{ix-1}.slab_end];

        % just to check
        disp('-----------------------');
        disp('Fixed:'); disp(rcfixed);
        disp('Moving:'); disp(rcmoving);
        disp('Out:'); disp(rcout);
        disp('Overlap:'); disp(overlap);
        disp('-----------------------');

        if ix == 2
            collection_start = 1;
        else
            collection_start = 0;
        end
        disp(['Fuse ' num2str(ix-1) ' ' slab_defs{ix-1}.slab_collection.stack ' ' num2str(ix) ' ' slab_defs{ix}.slab_collection.stack ' into ' rcout.stack])
        fuse_collections(rcsource, rcfixed, rcmoving, overlap, rcout, collection_start);
    end
    kk_clock;
end
