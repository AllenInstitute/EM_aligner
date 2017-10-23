function register_fine_SURF_slab(rcrough, rcfine, pm, nfirst, nlast, nbrs)
% based on a rcrough collection, calculates crosslayer point-matches
% assumes montage point-matches already exist in pm
%%% needs to be tested


%% assumes following has happened
% % configure source
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.40.3.162:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% % rcsource.verbose        = 1;
% 
% 
% % configure montage
% fnsource = '/groups/flyTEM/home/khairyk/EM_aligner/matlab_compiled/sample_montage_input.json';
% sl = loadjson(fileread(fnsource));
% fn = 'temp.json';
% nfirst= 1185;
% nlast = 1204;
% montage_collection.stack = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_montage'];
%     
% % configure rough
% rcrough.stack          = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_rough'];
% rcrough.owner          ='flyTEM';
% rcrough.project        = 'test';
% rcrough.service_host   = '10.40.3.162:8080';
% rcrough.baseURL        = ['http://' rcrough.service_host '/render-ws/v1'];
% rcrough.verbose        = 1;
% 
% dir_rough_intermediate_store = '/nobackup/flyTEM/khairy/FAFB00v13/montage_scape_pms';% intermediate storage of files
% dir_store_rough_slab = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_slab_rough_aligned';
% scale  = 0.05;  
% 
% % configure fine alignment
% rcfine.stack          = ['Revised_slab_' num2str(nfirst) '_' num2str(nlast) '_fine'];
% rcfine.owner          ='flyTEM';
% rcfine.project        = 'test';
% rcfine.service_host   = '10.40.3.162:8080';
% rcfine.baseURL        = ['http://' rcrough.service_host '/render-ws/v1'];
% rcfine.verbose        = 1;
% 
% finescale = 0.3;
% nbrs = 2;
% point_pair_thresh    = 5;
% 
% pm.server = 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner = 'flyTEM';
% pm.match_collection = 'v12_SURF';
% 
% %% %% generate montages   
% % sosi --- do qsub's in the futute to distribute
% for ix = nfirst:nlast
%     sl.section_number = ix;
%     sl.target_collection.stack = montage_collection.stack;
%     jstr = savejson('', sl);
%     fid = fopen(fn, 'w');
%     fprintf(fid, jstr);
%     fclose(fid);
%     montage_section_SL_prll(fn);
%     delete(fn);
% end
% 
% %% generate rough alignment
% rcmontage = sl.target_collection;
% % configure montage-scape point-match generation
% ms.service_host                 = rcmontage.service_host;
% ms.owner                        = rcmontage.owner;
% ms.project                      = rcmontage.project;
% ms.stack                        = rcmontage.stack;
% ms.fd_size                      = '10'; % '8'
% ms.min_sift_scale               = '0.2';%'0.55';
% ms.max_sift_scale               = '1.0';
% ms.steps                        = '3';
% ms.similarity_range             = '15';
% ms.skip_similarity_matrix       = 'y';
% ms.skip_aligned_image_generation= 'y';
% ms.base_output_dir              = '/gpfs1/scratch/flyTEM/khairy/FAFB00v13/experiments/temp_rough_base_output';
% ms.script                       = '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%'../unit_tests/generate_montage_scape_point_matches_stub.sh'; %
% ms.number_of_spark_nodes        = '2.0';
% ms.first                        = num2str(nfirst);
% ms.last                         = num2str(nlast);
% ms.scale                        = num2str(scale);
% ms.run_dir                      = ['Slab_' ms.first '_' ms.last '_scale_' ms.scale];
% 
% [L2, needs_correction, pmfn, zsetd, zrange, t, dir_spark_work, cmd_str, fn_ids, ...
%     target_solver_path, target_ids, target_matches, target_layer_images] =  ...
%     ...
%     solve_rough_slab(dir_store_rough_slab, rcmontage, ...
%     rcmontage, rcrough, ms, nfirst,...
%     nlast, dir_rough_intermediate_store, ...
%     1);
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Generate cross-layer point-matches
% obtain rough-aligned tiles
%rcrough.stack = 'Test_llm_04_prll_rough';
[Lrough, tiles_rough] = get_slab_tiles(rcrough, nfirst, nlast);
Lrough.dthresh_factor = 1.2;
Lrough = update_adjacency(Lrough);
%aa = Lrough.A;nnz(aa);spy(aa);

% update tile information
for tix = 1:numel(Lrough.tiles)
    Lrough.tiles(tix).stack = rcrough.stack;
    Lrough.tiles(tix).owner = rcrough.owner;
    Lrough.tiles(tix).project = rcrough.project;
    Lrough.tiles(tix).server = rcrough.baseURL;
end

[r, c] = ind2sub(size(Lrough.A), find(Lrough.A));  % neighbors are determined by the adjacency matrix
mt = Lrough.tiles;

%% generate list of potential tile pairs
% chunck it up into pieces
tp = {};
tile_pairs = tile;
chnk = 320;
tpcount = 1;
count = 1;
for pix = 1: numel(r)
    %disp(['Point matching: ' num2str(pix) ' of ' num2str(numel(r))]);
        % check whether the pair is a cross-section pair and within limits 
        % of nbrs
        new_pair = abs(mt(r(pix)).z-mt(c(pix)).z)>0;
        within_z_distance = abs(mt(r(pix)).z-mt(c(pix)).z)<(nbrs+1);
        if  new_pair && within_z_distance
                
        disp(['Matching tile ' num2str(r(pix)) ' zval: ' num2str(mt(r(pix)).z) ...
           ' with tile ' num2str(c(pix)) ' zval: ' num2str(mt(c(pix)).z)]);
       
       
            tile_pairs(count,1) = mt(r(pix));
            tile_pairs(count,2) = mt(c(pix));
            count = count + 1;
        end
        
        if count>chnk || pix==numel(r)
            disp('--------------- starting new chunck');
            count = 1;
            tp{tpcount} = tile_pairs;
            tile_pairs = tile;
            tpcount = tpcount + 1;
        end
end
%% 
fnjson = '/groups/flyTEM/home/khairyk/EM_aligner/matlab_compiled/sample_point_match_gen_pairs_input.json';
% read json input
sl = loadjson(fileread(fnjson));
for tpix = 1:numel(tp)
    disp(['**** processing tile set: ' num2str(tpix) ' of ' num2str(numel(tp))]);
    tic
    tset = tp{tpix};
    point_match_gen(sl, tset);
    toc
end


%% solve
% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';%'pastix';%%'gmres';%'backslash';'pastix';



opts.pastix.ncpus = 8;
opts.pastix.parms_fn = '/nobackup/flyTEM/khairy/FAFB00v13/matlab_production_scripts/params_file.txt';
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