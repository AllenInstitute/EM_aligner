function slab_defs = validate_slabs(slab_defs, default_rs_opts)
    parfor si = 1:numel(slab_defs)
        slab_collection = slab_defs{si}.slab_collection;
        if ~isfield(slab_collection, 'stack') || isempty(slab_collection.stack)
            error(['Slab ' num2str(si) ': Missing stack'])
        end
        slab_collection.owner = eval_field(slab_collection, 'owner', default_rs_opts.owner, true);
        slab_collection.project = eval_field(slab_collection, 'project', default_rs_opts.project, true);
        slab_collection.service_host = eval_field(slab_collection, 'service_host', default_rs_opts.service_host, true);
        slab_collection.verbose = eval_field(slab_collection, 'verbose', default_rs_opts.verbose, true);
        slab_collection.baseURL = ['http://' slab_collection.service_host '/render-ws/v1'];
        collection_exists = stack_exists(slab_collection);
        slab_defs{si}.slab_collection = slab_collection;
        if ~collection_exists
            slab_defs{si}.run_rough_align = slab_defs{si}.run_rough_align || ~collection_exists;
        end
    end
end
