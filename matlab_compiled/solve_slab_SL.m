function solve_slab_SL(fn)
% Intended for deployment: solve matrix system based on json input provided by fn


% read json input
sl = loadjson(fileread(fn));

if sl.verbose,
    kk_clock();
    disp(['Using input file: ' fn]);
    disp(['First section:' num2str(sl.first_section)]);
    disp(['Last section:' num2str(sl.last_section)]);
    disp('Using solver options:');disp(sl.solver_options);
    disp('Using source collection:');disp(sl.source_collection);
    disp('Using target collection:');disp(sl.target_collection);
    disp('Using point match collection:');disp(sl.source_point_match_collection);
end


%%% deprecated?
[mL, pm_mx, err, R, ~, ntiles, PM, sectionId_load, z_load] = ...
    solve_slab(sl.source_collection, sl.source_point_match_collection, ...
    sl.first_section, sl.last_section, [], sl.solver_options);


% nfirst = sl.first_section;
% nlast = sl.last_section;
% rcsource_rough = sl.source_collection;
% pm = sl.source_point_match_collection;
% nbrs = sl.solver_options.nbrs;
% min_points = sl.solver_options.min_points;
% max_points = sl.solver_options.max_points;
% xs_weight = sl.solver_options.xs_weight;
% 
% % start parallel pool
% poolobj = gcp('nocreate');
% delete_pool_at_exit = 0;
% if isempty(poolobj)
%     delete_pool_at_exit = 1;
%     if sl.verbose, disp('Starting parallel pool');end
%     defaultProfile = parallel.defaultClusterProfile;
%     myCluster = parcluster(defaultProfile);
%     parpool(myCluster);
% end
% 
% %if sl.verbose, disp(['Parallel pool created. Pool size: ' num2str(poolobj.NumWorkers)]);end
% 
% % load point matches
% [L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
%     load_point_matches(nfirst, nlast, rcsource_rough, pm, nbrs, ...
%     min_points, xs_weight, max_points); 
% 
% if sl.solver_options.degree==1
% % solve affine
% [mL, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
%     invalid] = solve_affine_explicit_region(L, sl.solver_options);
% else
%     
% 
% 
% %% ingest into Renderer database (optional);
% if sl.target_collection.overwrite
% delete_renderer_stack(sl.target_collection);  % delete existing collection if present
% end
%                                  
%   
% if sl.solver_options.degree==1
% ingest_tiles(sl.source_collection, sl.target_collection, mL, sl.ingest_cpus); % fast for affine
% else
%     disableValidation = 1;
%     ingest_section_into_LOADING_collection(mL, sl.target_collection,...
%                                        sl.source_collection, pwd, 1, disableValidation); % ingest
%   
% end
%                                    
% resp = set_renderer_stack_state_complete(sl.target_collection);  % set to state COMPLETE
% 
% if sl.verbose
%     disp(resp);
%     disp('Finished:');
%     kk_clock();
% end
% % delete pool
% if delete_pool_at_exit
% delete(poolobj);
% end
% %%%%%%%%%%%%%%%%%%%55
% %%
% function ingest_tiles(rc, rcout, L, n)
% %% Step 5: ingest into Renderer database
% opts.disableValidation = 1;
% ntiles = numel(L.tiles);
% Tout = zeros(ntiles,6);
% tiles = L.tiles;
% for tix = 1:ntiles
%    Tout(tix,:) = tiles(tix).tform.T(1:6)';
% end
% tIds = cell(ntiles,1);
% for tix = 1:ntiles
%  tIds{tix} = L.tiles(tix).renderer_id;
% end
% z_val = zeros(ntiles,1);
% for tix = 1:ntiles
%  z_val(tix)= L.tiles(tix).z;
% end
% 
% disp('** STEP 5:   Ingesting data .....');
% disp(' ..... translate to +ve space');
% delta = 0;
% dx = min(Tout(:,3)) + delta;%mL.box(1);
% dy = min(Tout(:,6)) + delta;%mL.box(2);
% for ix = 1:size(Tout,1)
%     Tout(ix,[3 6]) = Tout(ix, [3 6]) - [dx dy];
% end
% 
% disp('... export to MET (in preparation to be ingested into the Renderer database)...');
% 
% v = 'v1';
% if stack_exists(rcout)
%     resp = create_renderer_stack(rcout);
% end
% if ~stack_exists(rcout)
%     disp('.... target collection not found, creating new collection in state: ''Loading''');
%     resp = create_renderer_stack(rcout);
% end
% 
% chks = round(ntiles/n);
% cs = 1:chks:ntiles;
% cs(end) = ntiles;
% disp(' .... ingesting ....');
% parfor ix = 1:numel(cs)-1
%     disp(ix);
%     vec = cs(ix):cs(ix+1);
%     export_to_renderer_database(rcout, rc, pwd, Tout(vec,:),...
%         tIds(vec), z_val(vec), v, opts.disableValidation);
% end
% 
% 
% % % complete stack
% disp(' .... completing stack...');
% resp = set_renderer_stack_state_complete(rcout);
% disp('.... done!');
% diary off;











