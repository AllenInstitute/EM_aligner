%%% configure --------
%%% Purpose: - separate section into acquisitions
%%%          - montage each separately
%%%          - rough align pieces to one or more full neighbor sections
%%%          - merge pieces into one section again
%%%          - montage that section
%%%          - replace section in source (montage collection)

%%%% select subset of tiles of a section
clear all;clc
% % configure

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

sIdix = [2 3];
refIdix = [1 4];
mz = zmap(sIdix,2);
mref = zmap(refIdix,2); 

% source stack --- identity transformations
rc.stack          = 'z_1949_1957_acquire';
rc.owner          ='flyTEM';
rc.project        = 'khairyk_stage';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 0;


% montage stack for sections both fragments and reference
rcmontage.stack          = ['temp_reacquire_montages'];
rcmontage.owner          = 'flyTEM';
rcmontage.project        = 'test';
rcmontage.service_host   = '10.40.3.162:8080';
rcmontage.baseURL        = ['http://' rcmontage.service_host '/render-ws/v1'];
rcmontage.verbose        = 0;

%%% source point-match collection for sandwitch section
clear pm_o;
pm_o.server = 'http://10.40.3.162:8080/render-ws/v1';
pm_o.owner = 'flyTEM';
pm_o.match_collection = 'FAFB_pm_2'; %'Beautification_khairyk_merge_work';%'v12_dmesh';%


%%% target point-match collection for montages
clear pm;
pm.server = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner = 'flyTEM';
pm.match_collection = 'Beautification_khairyk_merge_work';%'v12_dmesh';%'FAFB_pm_2';


% temporary output stack for  rough aligned slab
rcout_temp.stack          = 'temp_rough_slab';
rcout_temp.owner          = 'flyTEM';
rcout_temp.project        = 'test';
rcout_temp.service_host   = '10.40.3.162:8080';
rcout_temp.baseURL        = ['http://' rcout_temp.service_host '/render-ws/v1'];
rcout_temp.verbose        = 0;

% 
% final destination of newly montaged pieces [Revision slab montage collection]
rcfine.stack          = 'temp_fine_slab';
rcfine.owner          ='flyTEM';
rcfine.project        = 'test';
rcfine.service_host   = '10.40.3.162:8080';
rcfine.baseURL        = ['http://' rcfine.service_host '/render-ws/v1'];
rcfine.verbose        = 0;

% 
% % configure rough alignment
% dir_rough_intermediate_store = '/nrs/flyTEM/khairy/FAFB00v13/montage_scape_pms';% intermediate storage of files
% dir_store_rough_slab = '/nrs/flyTEM/khairy/FAFB00v13/matlab_slab_rough_aligned';
% %scale  = 0.02;  

%% perform montaging of fragments (re-acquires)
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

%% perform montag solving of reference sections (solve only using pm_o)
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


%% rough align and merge
%%% general configuration for rough alignment
dir_rough_intermediate_store = '/nrs/flyTEM/khairy/FAFB00v13/montage_scape_pms';% intermediate storage of files
dir_store_rough_slab = '/nrs/flyTEM/khairy/FAFB00v13/matlab_slab_rough_aligned';
dir_scratch = '/scratch/khairyk';

rcrough = rcout_temp;
scale = 0.035;
ms.fd_size                      = '10'; % '8'
ms.min_sift_scale               = '0.2';%'0.55';
ms.max_sift_scale               = '1.0';
ms.steps                        = '3';
ms.skip_similarity_matrix       = 'y';
ms.skip_aligned_image_generation= 'y';
ms.base_output_dir              = '/nrs/flyTEM/khairy/FAFB00v13/experiments/temp_rough_base_output';
ms.script                       = '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%'../unit_tests/generate_montage_scape_point_matches_stub.sh'; %
ms.number_of_spark_nodes        = '2.0';  % not currently used


nfirst = mref(1);
nlast  = mref(2);

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
%% solve montage of merged section
%%% target point-match collection for montages
clear pm;
pm.server = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner = 'khairyk';
pm.match_collection = 'merge_work';%'v12_dmesh';%'FAFB_pm_2';

fnsm = '/groups/flyTEM/home/khairyk/EM_aligner/configurations/template_solve_montage.json';
sl = loadjson(fileread(fnsm));
sl.source_collection = rcrough;
sl.target_collection = rcfine;
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
