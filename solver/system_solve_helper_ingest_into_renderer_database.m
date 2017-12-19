function system_solve_helper_ingest_into_renderer_database(rc, rcout, ...
    Tout, tIds, z_val, opts, zu)

%% Step 5: ingest into Renderer database
if ~isfield(opts, 'translate_to_positive_space'),
    opts.translate_to_positive_space = 1;
end
if ~isempty(rcout)
    disp('--------------- Ingesting data .....');
    
    if opts.translate_to_positive_space
        disp(' ..... translating to +ve space: To turn off: > opts.translate_to_positive_space = 0;');
        % determine W and H:
        webopts = weboptions('Timeout', 60);
        urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
            rc.baseURL, rc.owner, rc.project, rc.stack,zu(1));
        j = webread(urlChar, webopts);
        jt1 = tile(j(1));
        Width = jt1.W;
        Height = jt1.H;
        
        delta = -(5000 + max([Width Height]));
        dx = min(Tout(:,3)) +  delta;
        dy = min(Tout(:,6)) +  delta;
        for ix = 1:size(Tout,1)
            Tout(ix,[3 6]) = Tout(ix, [3 6]) - [dx dy];
        end
    end
    
    disp('... export to MET (in preparation to be ingested into the Renderer database)...');
    v = 'v1';
    if ~stack_exists(rcout)
        disp('.... target collection not found, creating new collection in state: ''Loading''');
        resp = create_renderer_stack(rcout);
    end
    ntiles = size(Tout,1);
    if ntiles<opts.nchunks_ingest, opts.nchunks_ingest = ntiles;end
    
    chks = round(ntiles/opts.nchunks_ingest);
    cs = 1:chks:ntiles;
    cs(end) = ntiles;
    disp(' .... ingesting ....');
    for ix = 1:numel(cs)-1
        vec = cs(ix):cs(ix+1);
        export_to_renderer_database(rcout, rc, opts.dir_scratch, Tout(vec,:),...
            tIds(vec), z_val(vec), v, opts.disableValidation);
    end
    
    % % complete stack
    disp(' .... completing stack...');
    resp = set_renderer_stack_state_complete(rcout);
else
    warning('Not ingesting anything because output collection is not specified');
end
disp('.... done!');
