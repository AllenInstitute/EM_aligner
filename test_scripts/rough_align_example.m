
% configure montage
clc;
%% configure

nfirst = 1;   % first section in collection. z value
nlast = 10;    % last section in collection. z value

% configure montage collection
rcmontage.stack          = ['my_montage_collection_base_name'];
rcmontage.owner          ='owner';   % for example 'flyTEM'
rcmontage.project        = 'my_project';  % for example 'test'
rcmontage.service_host   = '10.40.3.162:8080';  % how to reach the Renderer service
rcmontage.baseURL        = ['http://' rcmontage.service_host '/render-ws/v1'];
rcmontage.verbose        = 1;


% configure rough
rcrough.stack          = ['my_rough_collection'];  % roughly 
rcrough.owner          ='flyTEM';
rcrough.project        = 'spc';
rcrough.service_host   = '10.40.3.162:8080';
rcrough.baseURL        = ['http://' rcrough.service_host '/render-ws/v1'];
rcrough.verbose        = 1;
rcrough.versionNotes   = 'Enter version Notes here. ';

% define temporary work directories here for intermediate storage of files
dir_rough_intermediate_store = ['/myscratch/montage_scape_pms'];
dir_store_rough_slab = [ '/myscratch/matlab_slab_rough_aligned'];

scale = 0.1;  % montage scape scale relative to full section. Values between 0.1 and 0.02 are common. 
              % Note: Montage-scape should still contain enough detail for feature detectors to work

% configure montage-scape point-match generation
ms.service_host                 = rcmontage.service_host;
ms.owner                        = rcmontage.owner;
ms.project                      = rcmontage.project;
ms.stack                        = rcmontage.stack;
ms.fd_size                      = '10'; % '8'
ms.min_sift_scale               = '0.2';%'0.55';
ms.max_sift_scale               = '1.0';
ms.steps                        = '3';
ms.similarity_range             = '3';
ms.skip_similarity_matrix       = 'y';
ms.skip_aligned_image_generation= 'y';
ms.base_output_dir              = ['/myscratch/temp_rough_base_output']; % scratch work directory for spark process


% which script to use
% Option [1]: enables filter, but limits point-matches between montage scapes to a central box of width 0.3 of total width
%             (found useful for data with regions of neighboring tiles included in periphery on
%             "main" section)
%ms.script                       = [ EM_aligner_path '/renderer_api/generate_montage_scape_point_matches_box_0.3.sh']; 

% Option [2]: disables filter and limits point-matches between montage scapes to a central box of width 0.3 of total width
%              (found useful for array tomography data)
%ms.script                       = [ EM_aligner_path '/renderer_api/generate_montage_scape_point_matches_box_filter_no.sh']; 
     
% Option [3]: enables filter and uses full montage scape -- this is the usual case, for example FAFB
% dataset
ms.script                       = [ EM_aligner_path '/renderer_api/generate_montage_scape_point_matches_box.sh'];                        
                           

ms.number_of_spark_nodes        = '2.0';  % not used yet
ms.first                        = num2str(nfirst);
ms.last                         = num2str(nlast);
ms.scale                        = num2str(scale);
ms.center_box                   = 1.0; % ms.center_box<1.0 means use SURF point-matches and activate "Allen hack".
ms.run_dir                      = ['Slab_' ms.first '_' ms.last '_scale_' ms.scale];
ms.FAFB                         = 1;  % set to one if FAFB dataset is used
ms.rough_solve                  = 'rigid';  % if set to 'affine' will do affine fitting of montage scapes after rigid.


run_now = 1;   % set to 1 to lauch spark process (needed in the first pass)
               % set to 0 if spark succeeded but for debugging purposes you need to re-run rough alignment

%% execution part
if ~exist(dir_store_rough_slab, 'dir')
    mkdir(dir_store_rough_slab);
end
kk_mkdir(dir_rough_intermediate_store);   % purge and make new empty
kk_mkdir(ms.base_output_dir);

[L2, needs_correction, pmfn, zsetd, zrange, t,dir_spark_work, cmd_str, fn_ids, ...
    target_solver_path, target_ids, target_matches, target_layer_images]= ...
    ...
    solve_rough_slab(dir_store_rough_slab, rcmontage, ...
    rcmontage, rcrough, ms, nfirst,...
    nlast, dir_rough_intermediate_store, ...
    run_now);
































