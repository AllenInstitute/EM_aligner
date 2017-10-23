% run full montage for a slab using SURF
% rough align the slab
% fine-align the slab
% insert into final destination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% configure montage
clc
fn1 = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/config/solve_2630_2641.json';
sl = loadjson(fileread(fn1));
sl.ncpus = 8;
sl.local_scratch = '/scratch/khairyk';
sl.bin_fn = '/groups/flyTEM/home/khairyk/EM_aligner/matlab_compiled/montage_section_SL_prll';
sl.complete = 0;


% configure source
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.40.3.162:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

re_slice = 2636;  % this section is the actual issue that needs to be fixed
nfirst= 2630;
nlast = 2641;
overlap_delta = 4;
overlap = [nfirst nfirst+overlap_delta nlast-overlap_delta nlast];

montage_collection = rcsource;
montage_collection.stack = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_montage'];
montage_collection.project = 'FAFB00_beautification';
 


% configure rough
rcrough.stack          = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_rough'];
rcrough.owner          ='flyTEM';
rcrough.project        = 'FAFB00_beautification';
rcrough.service_host   = '10.40.3.162:8080';
rcrough.baseURL        = ['http://' rcrough.service_host '/render-ws/v1'];
rcrough.verbose        = 1;

dir_rough_intermediate_store = '/nrs/flyTEM/khairy/FAFB00v13/montage_scape_pms';% intermediate storage of files
dir_store_rough_slab = '/nrs/flyTEM/khairy/FAFB00v13/matlab_slab_rough_aligned';
dir_scratch = '/scratch/khairyk';
scale  = 0.03;  

% configure fine alignment
rcfine.stack          = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_fine'];
rcfine.owner          ='flyTEM';
rcfine.project        = 'FAFB00_beautification';
rcfine.service_host   = '10.40.3.162:8080';
rcfine.baseURL        = ['http://' rcrough.service_host '/render-ws/v1'];
rcfine.verbose        = 1;

finescale = 0.4;
nbrs = 3;
point_pair_thresh    = 5;

pm.server = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner = 'flyTEM';
pm.match_collection = 'v12_SURF';

sl.target_point_match_collection = pm;

rcfixed.stack          = 'FULL_FAFB_FUSED_05_ROTATED';
rcfixed.owner          ='flyTEM';
rcfixed.project        = 'FAFB00_beautification';
rcfixed.service_host   = '10.40.3.162:8080';
rcfixed.baseURL        = ['http://' rcfixed.service_host '/render-ws/v1'];
rcfixed.verbose        = 1;

rcmoving = rcfine;
kk_clock();
% % overrides
sl.source_collection = rcsource;
sl.target_collection = montage_collection;  
disp(sl);
disp(['-------  Using input file: ' fn]);
disp('-------  Using solver options:');disp(sl.solver_options);
%disp('-------  Using SURF options:');disp(sl.SURF_options);
disp('-------  Using source_collection:');disp(sl.source_collection);
disp('-------  Using source_point_match_collection:');disp(sl.source_point_match_collection);
disp('-------  Using target_point_match_collection:');disp(sl.target_point_match_collection);


%% [1] generate montage
% generate_full_montages(sl, nfirst, nlast);
% disp('Section full montage process started');
% resp = set_renderer_stack_state_complete(sl.target_collection);
%%
fnsm = '/groups/flyTEM/home/khairyk/EM_aligner/configurations/solve_montage_fafb_section_5.json';
sl = loadjson(fileread(fnsm));
% sl.target_collection = montage_collection;
% disp('Section solve-only montage process started');

%%%% construct pm struct array like so:
clear pm;ix = 1;
% 
pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'flyTEM';
pm(ix).match_collection = 'v12_dmesh';
ix = ix + 1;

% pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
% pm(ix).owner = 'flyTEM';
% pm(ix).match_collection = 'FAFB_pm_2';  % montage point-matches
% ix = ix + 1;

pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'flyTEM';
pm(ix).match_collection = 'Beautification_cross_sift_00';  % cross section point-matches
ix = ix + 1;
for ix = nfirst:nlast
    %delete_renderer_section(sl.target_collection, ix);
    sl.section_number = ix;
    sl.z_value = ix;
    
    sl.target_collection.initialize = 0;
    sl.target_collection.complete = 1;
    jstr = savejson('', sl);
    
    
%     fid = fopen(fn, 'w');
%     fprintf(fid, jstr);
%     fclose(fid);
    %montage_section_SL_prll(fn);
    solve_montage_SL(sl)
%     delete(fn);
end
set_renderer_stack_state_complete(sl.target_collection);
%% [2] (optional) if neessaary slice sections into pieces and assemble

%% [3] generate rough alignment
rcmontage = sl.target_collection;
% configure montage-scape point-match generation
ms.service_host                 = rcmontage.service_host;
ms.owner                        = rcmontage.owner;
ms.project                      = rcmontage.project;
ms.stack                        = rcmontage.stack;
ms.fd_size                      = '10'; % '8'
ms.min_sift_scale               = '0.2';%'0.55';
ms.max_sift_scale               = '1.0';
ms.steps                        = '3';
ms.similarity_range             = '2';
ms.skip_similarity_matrix       = 'y';
ms.skip_aligned_image_generation= 'y';
ms.base_output_dir              = '/nrs/flyTEM/khairy/FAFB00v13/experiments/temp_rough_base_output';
ms.script                       = '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%'../unit_tests/generate_montage_scape_point_matches_stub.sh'; %
ms.number_of_spark_nodes        = '2.0';
ms.first                        = num2str(nfirst);
ms.last                         = num2str(nlast);
ms.scale                        = num2str(scale);
ms.run_dir                      = ['Slab_' ms.first '_' ms.last '_scale_' ms.scale];
ms.FAFB                         = 1;
ms.rough_solve                  = 'rigid';

delete_renderer_stack(rcrough);
[L2, needs_correction, pmfn, zsetd, zrange, t, dir_spark_work, cmd_str, fn_ids, ...
    target_solver_path, target_ids, target_matches, target_layer_images] =  ...
    ...
    solve_rough_slab(dir_store_rough_slab, rcmontage, ...
    rcmontage, rcrough, ms, nfirst,...
    nlast, dir_rough_intermediate_store, ...
    1);

%% [4] Generate cross-layer point-matches
% generate_point_matches(rcrough, nfirst, nlast, fnjson); % SOSI -- not ready yet ------

%% [5] solve (first pass solve)

% define point-match sources
clear pm;
ix = 1;
% pm(1).server = 'http://10.40.3.162:8080/render-ws/v1';
% pm(1).owner = 'flyTEM';
% pm(1).match_collection = 'v12_dmesh';

pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'flyTEM';
pm(ix).match_collection = 'FAFB_pm_2';  % montage point-matches
ix = ix + 1;

pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'flyTEM';
pm(ix).match_collection = 'Beautification_cross_sift_00';  % cross section point-matches
ix = ix + 1;


% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';%'pastix';%%'gmres';%'backslash';'pastix';



opts.pastix.ncpus = 8;
opts.pastix.parms_fn = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/params_file.txt';
opts.pastix.split = 1; % set to either 0 (no split) or 1

opts.matrix_only = 0;   % 0 = solve , 1 = only generate the matrix
opts.distribute_A = 1;  % # shards of A
opts.dir_scratch = '/scratch/khairyk';


opts.min_points = 10;
opts.max_points = 100;
opts.nbrs = 3;
opts.xs_weight = 15.0;
opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 0;

opts.lambda = 10.^(-1);
opts.edge_lambda = 10^(-1);
opts.A = [];
opts.b = [];
opts.W = [];

% % configure point-match filter
opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
opts.pmopts.MaximumRandomSamples = 5000;
opts.pmopts.DesiredConfidence = 99.9;
opts.pmopts.PixelDistanceThreshold = .01;

opts.verbose = 1;
opts.debug = 0;

[mL,err] = ...
         system_solve(nfirst, nlast, rcrough, pm, opts, rcfine);
disp(err);
%% [6] (optional) filter deformed tiles and create a filtered rough collection
rcrough_filtered.stack          = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_rough_filtered'];
rcrough_filtered.owner          ='flyTEM';
rcrough_filtered.project        = 'FAFB00_beautification';
rcrough_filtered.service_host   = '10.40.3.162:8080';
rcrough_filtered.baseURL        = ['http://' rcrough_filtered.service_host '/render-ws/v1'];
rcrough_filtered.verbose        = 1;

mA_thresh = 0.2;
[mA, mS, sctn_map, tile_areas, tile_perimeters, tidsvec]  = ...
    filter_deformed_tiles(rcfine, rcrough, rcrough_filtered, nfirst, nlast, dir_scratch, mA_thresh);

%% [7] (optional) solve again (pass 2) based on filtered rough collection
% this solution will disregard tiles that we know will cause larger deformation if included
%delete_renderer_stack(rcfine_filtered); % remove this co

zstart = 2630;
zfinish = 2641;

clear pm;ix = 1;
% 
pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'flyTEM';
pm(ix).match_collection = 'v12_dmesh';
ix = ix + 1;

% pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
% pm(ix).owner = 'flyTEM';
% pm(ix).match_collection = 'FAFB_pm_2';  % montage point-matches
% ix = ix + 1;

pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'flyTEM';
pm(ix).match_collection = 'Beautification_cross_sift_00';  % cross section point-matches
ix = ix + 1;

rcfine_filtered.stack          = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_fine_filtered'];
rcfine_filtered.owner          ='flyTEM';
rcfine_filtered.project        = 'FAFB00_beautification';
rcfine_filtered.service_host   = '10.40.3.162:8080';
rcfine_filtered.baseURL        = ['http://' rcfine_filtered.service_host '/render-ws/v1'];
rcfine_filtered.verbose        = 1;


% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';%'pastix';%%'gmres';%'backslash';'pastix';


% only relevant when solver is pastix
opts.pastix.ncpus = 8;
opts.pastix.parms_fn = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_production_scripts/params_file.txt';
opts.pastix.split = 1; % set to either 0 (no split) or 1

opts.matrix_only = 0;   % 0 = solve (default) , 1 = only generate the matrix. For debugging only
opts.distribute_A = 1;  % # shards of A
opts.dir_scratch = '/scratch/khairyk';
opts.nchunks_ingest = 64;

opts.min_points = 8;
opts.max_points = 100;
opts.nbrs = 4;
opts.xs_weight = 0.1;  % ------------------------------------->
opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 0;

opts.transfac = 1;  % let tiles translate more freely if transfac<1 (e.g. 1e-5)

opts.lambda = 10.^(-1);  % ----------------------------------->
opts.A = [];
opts.b = [];
opts.W = [];

% % configure point-match filter
opts.filter_point_matches = 1;  %------------------------------->
opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
opts.pmopts.MaximumRandomSamples = 5000;
opts.pmopts.DesiredConfidence = 99.9;
opts.pmopts.PixelDistanceThreshold = .01;

opts.verbose = 1;
opts.debug = 0;

opts.use_peg   = 0;   % ------------------------------------>
opts.peg_weight = 0.0001;
opts.peg_npoints = 10;
opts.disableValidation = 0;

rcfine_filtered.stack = ['Revised_slab_2630_2641_fine_lambda_m1' ];
rcfine_filtered.versionNotes = ['lambda: ' num2str(opts.lambda) ' -- transfac: ' num2str(opts.transfac) ...
                                ' -- filter pms: ' num2str(opts.filter_point_matches) ' -- use peg: ' ...
                                num2str(opts.use_peg)];
                            
[err, R] = ...
         system_solve(zstart, zfinish, rcrough_filtered, pm, opts, rcfine_filtered);
disp(err);

%%%%%%%%%%%%%%%%%%%%%  
% alternatively (slow)
% [mL, pm_mx, err, R, ~, ntiles, PM, sectionId_load, z_load] = ...
%     solve_slab(rcrough_filtered, pm, ...
%     nfirst, nlast, rcfine_filtered, opts);


disp(err);
% % % % diagnostics
% % 
% % 
% % dopts.nbrs = 3;
% % dopts.min_points = 5;
% % dopts.show_deformation = 0;
% % dopts.show_residuals = 0;
% % dopts.show_deformation_summary = 0;
% % 
% % 
% % 
% % [mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, tidsvec, Resx,Resy] =...
% %     gen_diagnostics(rcsource, rcfine_filtered, zstart, zfinish, pm, dopts);

%% lambda vs deformation search
% % diagnostics
% dopts.nbrs = 4;
% dopts.min_points = 8;
% dopts.show_deformation = 0;
% dopts.show_residuals = 0;
% dopts.show_deformation_summary = 0;
% 
% count = 1;
% def = [];
% err = [];
% l_used = [];
% for lexp = -3:0.5:4
%     opts.lambda = 10^(lexp);
%     opts.edge_lambda = opts.lambda;
%     
%     [err(count)] = system_solve(zstart, zfinish, rcrough_filtered, pm, opts, rcfine_filtered);
%     
%     [mA, mS, sctn_map, confidence, tile_areas, tile_perimeters, tidsvec] =...
%         gen_diagnostics(rcsource, rcfine_filtered, zstart, zfinish, pm, dopts);
%     
%     def(count) = 1/mean(mA);
%     l_used(count) = opts.lambda;
%     
%     disp([l_used(count) err(count) def(count)]);
%     count = count + 1;
% end
% 
% disp([l_used(:) err(:) def(:)]);
% 
% plot(log10(l_used), log10(err), 'o-', log10(l_used), log10(def), 'k-');

%% [8] insert beautified slab into full volume


% [resp] = fuse_collections_insert_slab(rcsource, rcfixed, rcmoving, overlap);































