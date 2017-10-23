
% configure montage
clc;
%% configure
nfirst = 3800;
nlast = 4563;
force_montage = 0;
ncpus = 8;   % how many cpus per job (overrides json input)
fnsource = '/nrs/spc/matlab_work/montage/EXP_spc_montage_section_kk00.json'; % template input json file
bin_fn = '/nrs/spc/matlab_work/montage/montage_section_SL_prll';   % where is the executable?


%% preparations and over-rides
sl = loadjson(fileread(fnsource));%
montage_collection.stack = ['v2_reduced_3800_4563'];
%montage_collection.stack = ['v2_SURF_' num2str(nfirst) '_' num2str(nlast) '_kk_montage'];

sl.target_collection.stack = montage_collection.stack;
dir_scratch = [sl.scratch '/temp_' num2str(randi(10000))];
kk_mkdir(dir_scratch);

cd(dir_scratch);

%% %% generate rough alignment
rcmontage = sl.target_collection;
%rcmontage.stack = 'v2_rough';
% 
% configure rough
rcrough.stack          = ['v2_rough_3800_4563'];
rcrough.owner          ='flyTEM';
rcrough.project        = 'spc';
rcrough.service_host   = '10.40.3.162:8080';
rcrough.baseURL        = ['http://' rcrough.service_host '/render-ws/v1'];
rcrough.verbose        = 1;
rcrough.versionNotes   = 'align  reduced slab rough alignment at scale 0.04';

dir_rough_intermediate_store = [sl.scratch '/montage_scape_pms'];% intermediate storage of files
dir_store_rough_slab = [sl.scratch '/matlab_slab_rough_aligned'];


if ~exist(dir_store_rough_slab, 'dir')
    mkdir(dir_store_rough_slab);
end

scale = 0.08;


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
ms.base_output_dir              = ['/nrs/spc/matlab_work/montage/scratch/temp_rough_base_output'];
ms.script                       = '/nrs/spc/matlab_work/EM_aligner/renderer_api/generate_montage_scape_point_matches_box_0.3.sh';%
%ms.script                       = '/nrs/spc/matlab_work/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh';%
ms.number_of_spark_nodes        = '12.0';   % not used yet in script (still hard-coded)
ms.first                        = num2str(nfirst);
ms.last                         = num2str(nlast);
ms.scale                        = num2str(scale);
ms.center_box                   = 1.0;
ms.run_dir                      = ['Slab_' ms.first '_' ms.last '_scale_' ms.scale];
ms.rough_solve                  = 'affine'; % also valid 'rigid'


% %
%kk_mkdir(dir_rough_intermediate_store);   % purge and make new empty
%kk_mkdir(ms.base_output_dir);
% %
run_now = 1;

% s_first = 1;
% s_last   = 2000;
% %solve_name = 'v2_rough_try_9_slab_test_1_25';
% solve_name = 'v2_rough_try_11_slab_1_1_1000';
% [zu, sID, sectionId, z, ns] = get_section_ids(rcmontage, nfirst, nlast);
% solve_first = zu(1);
% solve_last = zu(end);
% disp(solve_first);
% disp(solve_last);
% disp(solve_name);

[L2, needs_correction, pmfn, zsetd, zrange, t,dir_spark_work, cmd_str, fn_ids, ...
    target_solver_path, target_ids, target_matches, target_layer_images]= ...
    ...
    solve_rough_slab(dir_store_rough_slab, rcmontage, ...
    rcmontage, rcrough, ms, nfirst,...
    nlast, dir_rough_intermediate_store, ...
    run_now);

%% % generate montage scapes
%[zu, sID, sectionId, z, ns] = get_section_ids(rcmontage, nfirst, nlast);
%[Wbox, bbox, url] = get_slab_bounds_renderer(rcrough);
%dir_scratch_montage_scapes = ['/groups/spc/spc/scratch/montage_scapes/' rcrough.stack];
%kk_mkdir(dir_scratch_montage_scapes);
%cd(dir_scratch_montage_scapes);
%scale = 0.01;


%for ix = 1%numel(zu),
%    im = generate_montage_scape(rcrough, zu(ix) , scale, Wbox);
%    imwrite(im, ['ms_' num2str(ix) '.png']);
%end
















































