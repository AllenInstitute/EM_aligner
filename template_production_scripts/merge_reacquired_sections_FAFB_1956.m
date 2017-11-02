%%% configure --------
%%% Purpose: - separate section into acquisitions
%%%          - montage each separately
%%%          - rough align pieces to one or more full neighbor sections
%%%          - generate point-matches based on this rough alignment
%%%          - merge pieces into one roug-aligned (merged) collection
%%%          - montage everything
%%%          - replace section in source (montage collection)

%%%% select subset of tiles of a section
clc
%% configure

% section mapping
zmap = [1949   102019;...
        1950.0 102020;...
        1950.1 102021;...
        1951   102022;...
        1952   102023;...
        1953   102024;...
        1954   102025;...
        1955   102026;...
        1956.0 102027;...
        1956.1 102028;...
        1956.2 102029;...
        1957   102030];

sIdix = [9 10 11];
refIdix = [8 12];

scale                     = 0.035; % scale used for generating montage-scapes for rough alignment


% source stack --- identity transformations
rc.stack          = 'z_1949_1957_acquire';
rc.owner          ='flyTEM';
rc.project        = 'khairyk_stage';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 0;

%%% source point-match collection for "sandwitch" (reference) sections
clear pm_o;
pm_o.server = 'http://10.40.3.162:8080/render-ws/v1';
pm_o.owner = 'flyTEM';
pm_o.match_collection = 'FAFB_pm_2'; %'Beautification_khairyk_merge_work';%'v12_dmesh';%

%%% target point-match collection for fragment montages
clear pm;
pm.server = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner = 'flyTEM';
pm.match_collection = 'Beautification_khairyk_merge_work';%'v12_dmesh';%'FAFB_pm_2';

%%%%%%%%%%%%%%% YOU SHOULD NOT NEED TO MODIFY BELOW %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% montage stack for sections both fragments and reference
rcmontage.stack          = ['temp_reacquire_montages_' num2str(zmap(sIdix(1),1))];
rcmontage.owner          = 'flyTEM';
rcmontage.project        = 'test';
rcmontage.service_host   = '10.40.3.162:8080';
rcmontage.baseURL        = ['http://' rcmontage.service_host '/render-ws/v1'];
rcmontage.verbose        = 0;




% temporary output stack for rough aligned slab (non-merged and then merged --- same collection used)
rcrough.stack          = ['temp_rough_slab_' num2str(zmap(sIdix(1),1))];
rcrough.owner          = 'flyTEM';
rcrough.project        = 'test';
rcrough.service_host   = '10.40.3.162:8080';
rcrough.baseURL        = ['http://' rcrough.service_host '/render-ws/v1'];
rcrough.verbose        = 0;


% 
% final destination of newly montaged pieces [Revision slab montage collection]
% this needs to be ingested into the final full-volume montage collection
rcmontage_final.stack          = ['montage_final_' num2str(zmap(sIdix(1),1))];
rcmontage_final.owner          ='flyTEM';
rcmontage_final.project        = 'test';
rcmontage_final.service_host   = '10.40.3.162:8080';
rcmontage_final.baseURL        = ['http://' rcmontage_final.service_host '/render-ws/v1'];
rcmontage_final.verbose        = 0;

% final destination of newly montaged pieces [Revision slab montage collection]
% this needs to be interpolated (fused) into the final full-volume "aligned" collection
rcfine.stack          = ['Fine_final_' num2str(zmap(sIdix(1),1))];
rcfine.owner          ='flyTEM';
rcfine.project        = 'test';
rcfine.service_host   = '10.40.3.162:8080';
rcfine.baseURL        = ['http://' rcfine.service_host '/render-ws/v1'];
rcfine.verbose        = 0;

mz = zmap(sIdix,2);
mref = zmap(refIdix,2); 

%% perform full montaging of fragments (re-acquires)
% fnsm = '/groups/flyTEM/home/khairyk/EM_aligner/configurations/template_solve_montage.json';
fnsm = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/config/template_full_montage.json';
sl = loadjson(fileread(fnsm));
sl.source_collection = rc;
sl.target_collection = rcmontage;
sl.target_point_match_collection = pm;
fn = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/config/temp_solve_montage.json';
% disp('Section solve-only montage process started');
for ix = 1:numel(mz)
    disp(ix);
    delete_renderer_section(sl.target_collection, ix);
    sl.section_number = mz(ix);
    sl.z_value = mz(ix);
    sl.target_collection.initialize = 0;
    sl.target_collection.complete = 1;
    jstr = savejson('', sl);
    fid = fopen(fn, 'w');
    fprintf(fid, jstr);
    fclose(fid);
    montage_section_SL_prll(fn);
    %solve_montage_SL(fn)
    delete(fn);
end
%set_renderer_stack_state_complete(sl.target_collection);

%% perform montag solve-only of reference sections (solve only using pm_o)
fnsm = '/groups/flyTEM/home/khairyk/EM_aligner/configurations/template_solve_montage.json';
%fnsm = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/config/template_full_montage.json';
sl = loadjson(fileread(fnsm));
sl.source_collection = rc;
sl.target_collection = rcmontage;
sl.source_point_match_collection = pm_o;
fn = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/config/temp_solve_montage.json';
% disp('Section solve-only montage process started');
for ix = 1:numel(mref)
    disp(ix);
    %delete_renderer_section(sl.target_collection, ix);
    sl.section_number = mref(ix);
    sl.z_value = mref(ix);
    sl.target_collection.initialize = 0;
    sl.target_collection.complete = 1;
    jstr = savejson('', sl);
    fid = fopen(fn, 'w');
    fprintf(fid, jstr);
    fclose(fid);
    %montage_section_SL_prll(fn);
    solve_montage_SL(fn)
    delete(fn);
end
set_renderer_stack_state_complete(sl.target_collection);


%% rough align
%%% general configuration for rough alignment
nfirst = mref(1);
nlast  = mref(2);

dir_rough_intermediate_store = '/nrs/flyTEM/khairy/FAFB00v13/montage_scape_pms';% intermediate storage of files
dir_store_rough_slab = '/nrs/flyTEM/khairy/FAFB00v13/matlab_slab_rough_aligned';
dir_scratch = '/scratch/khairyk';
ms.fd_size                      = '10'; % '8'
ms.min_sift_scale               = '0.2';%'0.55';
ms.max_sift_scale               = '1.0';
ms.steps                        = '3';
ms.skip_similarity_matrix       = 'y';
ms.skip_aligned_image_generation= 'y';
ms.base_output_dir              = '/nrs/flyTEM/khairy/FAFB00v13/experiments/temp_rough_base_output';
ms.script                       = '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%'../unit_tests/generate_montage_scape_point_matches_stub.sh'; %
ms.number_of_spark_nodes        = '2.0';  % not currently used
% configure montage-scape point-match generation
ms.service_host                 = rcmontage.service_host;
ms.owner                        = rcmontage.owner;
ms.project                      = rcmontage.project;
ms.stack                        = rcmontage.stack;
ms.similarity_range             = '4';
ms.first                        = num2str(nfirst);
ms.last                         = num2str(nlast);
ms.scale                        = num2str(scale);
ms.run_dir                      = ['Slab_' ms.first '_' ms.last '_scale_' ms.scale];
ms.FAFB                         = 1;
ms.rough_solve                  = 'rigid';
runnow = 1;
%%% submit rough alignment command
[L2, needs_correction, pmfn, zsetd, zrange, t, dir_spark_work, cmd_str, fn_ids, ...
    target_solver_path, target_ids, target_matches, target_layer_images] =  ...
    ...
    solve_rough_slab(dir_store_rough_slab, rcmontage, ...
    rcmontage, rcrough, ms, nfirst,...
    nlast, dir_rough_intermediate_store, ...
    runnow);
%% STOP --- run external script for generation of (montage and) cross-layer point-matches
%  for the slab. This is the point-match set that will be used to solve 
%  in the future. Use this point-match set below



%% set sections in rcrough to original z value (this also merges reacquisitions) 
for ix = 1:numel(sIdix)
    zid = num2str(zmap(sIdix(ix), 1), '%.1f' );
    zval = floor(zmap(sIdix(ix),1));
    disp(['Setting id: ' zid ' to z value of ' num2str(zval)]);
    resp = set_section_z_by_section_id(rcrough, zid, zval);
end

for ix = 1:numel(refIdix)
    zid = num2str(zmap(refIdix(ix), 1), '%.1f' );
    zval = floor(zmap(refIdix(ix),1));
    disp(['Setting id: ' zid ' to z value of ' num2str(zval)]);
    resp = set_section_z_by_section_id(rcrough, zid, zval);
end
%% solve montage for everyone again and ingest into rcmontage_final
%%% target point-match collection for montages
clear pm;
pm.server = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner = 'khairyk';
pm.match_collection = 'merge_work';%'v12_dmesh';%'FAFB_pm_2';

fnsm = '/groups/flyTEM/home/khairyk/EM_aligner/configurations/template_solve_montage.json';
sl = loadjson(fileread(fnsm));
sl.source_collection = rcrough;
sl.target_collection = rcmontage_final;
sl.source_point_match_collection = pm;
fn = '/nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/config/temp_solve_montage.json';


msections = [floor(zmap(sIdix(1),1)) zmap(refIdix,1)'];
for ix = 1:numel(msections)
    sl.section_number = msections(ix);
    sl.z_value = msections(ix);
    sl.target_collection.initialize = 0;
    sl.target_collection.complete = 1;
    jstr = savejson('', sl);
    fid = fopen(fn, 'w');
    fprintf(fid, jstr);
    fclose(fid);
    solve_montage_SL(fn)
    delete(fn);
end
set_renderer_stack_state_complete(sl.target_collection);

%% solve slab

nfirst = min(msections);
nlast  = max(msections);

% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 5e-1;  % large numbers result in fewer tiles excluded
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



