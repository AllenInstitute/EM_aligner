%%% generate set of rough alignment jobs and store data for later use.


%% general configuration

clc; %clear all;

% configure montage collection
rctarget_montage.stack          = ['EXP_dmesh_montage_P1_peg'];
rctarget_montage.owner          ='flyTEM';
rctarget_montage.project        = 'test';
rctarget_montage.service_host   = '10.40.3.162:8080';
rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
rctarget_montage.verbose        = 1;

% configure montage-scape point-match generation
ms.service_host                 = rctarget_montage.service_host;
ms.owner                        = rctarget_montage.owner;
ms.project                      = rctarget_montage.project;
ms.stack                        = rctarget_montage.stack;
ms.fd_size                      = '10'; % '8'
ms.min_sift_scale               = '0.2';%'0.55';
ms.max_sift_scale               = '1.0';
ms.steps                        = '3';
ms.similarity_range             = '15';
ms.skip_similarity_matrix       = 'y';
ms.skip_aligned_image_generation= 'y';
ms.base_output_dir              = '/nobackup/flyTEM/spark_montage';

ms.script                       = '/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%'../unit_tests/generate_montage_scape_point_matches_stub.sh'; %
ms.number_of_spark_nodes        = '2.0';


% intermediate storage of files
dir_rough_intermediate_store = '/nobackup/flyTEM/khairy/FAFB00v13/montage_scape_pms';

% slab definition
Slab_definition;   % run the script that defines slabs
    
%% %% calculate rough alignment, solve and generate renderer collection
failed = [];                 % list failures
for ix = 32:60 %nslabs
    kk_clock;
    % configure rough collection
    rctarget_rough = rough_collection{ix}; 
    
    ms.first                        = num2str(nfirstvec(ix));
    ms.last                         = num2str(nlastvec(ix));
    ms.scale = num2str(scalevec(ix));
    ms.run_dir                      = ['Slab_' num2str(ix) '_' ms.first '_' ms.last '_scale_' ms.scale];
    run_now = run_now_vec_rough(ix);
    disp(['-------------------- Processing slab: ' num2str(nfirstvec(ix)) ' to ' num2str(nlastvec(ix)) ' at scale ' num2str(scalevec(ix))]);

    
    % % do the actual slab solve
    diary on;
  try
    [L2, needs_correction, pmfn, zsetd, zrange, t, dir_spark_work, cmd_str, fn_ids, ...
        target_solver_path, target_ids, target_matches, target_layer_images] =  ...
        ...
        solve_rough_slab(dir_store_rough_slab, rcsource, ...
        rctarget_montage, rctarget_rough, ms, nfirstvec(ix), nlastvec(ix), dir_rough_intermediate_store, ...
        run_now);
   catch err_rough
       kk_disp_err(err_rough);
       failed = [failed ix];
       diary off;
  end
   
  kk_clock;
 
%     
end
diary off;























