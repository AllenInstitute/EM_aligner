%%% solve using cpp solver

%% configure
clc;kk_clock;

nfirst = 1;
nlast  = 100;

% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure output "align" collection
rctarget_align.stack          = ['FAFB_v12_dmesh_cpp_align_test'];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;

% configure point-match source collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';

opts.min_tiles = 50; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.min_points = 8;
opts.nbrs = 4;      % how many neighboring sections to include in point-match loading
opts.xs_weight = 1/20;  % small numbers ==> less weight for cross-layer points relative to montage points
opts.stvec_flag = 0;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
                 
%% prepare point matches
% [L_vec, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
%                    load_point_matches(nfirst, nlast, rcsource,...
%                    pm, opts.nbrs, opts.min_points, opts.xs_weight);
% [L_vec, ntiles] = reduce_to_connected_components(L_vec);
% L = L_vec(1);
%jstr = PM_json(L);

%%% obtain jstr directly from Renderer service


%%%%
fnpmjson = ...
['/groups/flyTEM/home/khairyk/EM_aligner/test_data/solver_data/' ...
'example01_FAFB_' num2str(nfirst) '_' num2str(nlast) '_pm.json'];
fid = fopen(fnpmjson,'w');
fprintf(fid,'%s',jstr);
fclose(fid);
%% call cpp solver program
clc;
fn_canvas_json_output = ...
    ['/groups/flyTEM/home/khairyk/EM_aligner/test_data/solver_data/'... 
    'example01_FAFB_' num2str(nfirst) '_' num2str(nlast) '_canvases_rotation.json'];
      
solv_cmd = '/groups/flyTEM/home/khairyk/downloads/JDR/jdr_solver';
lambda = 0.1;
degree = 1;
stvec = 0;
fn_canvas_input = '';
cmd = [solv_cmd ' ' fnpmjson ' ' fn_canvas_json_output ' ' num2str(degree) ...
      ' ' num2str(lambda) ' ' num2str(stvec)];
tic;[a,resp_str] = system(cmd);toc
disp(resp_str);
Laff_cpp = update_transformation_from_json(L,fn_canvas_json_output);
%%
delete_renderer_stack(rctarget_align);  % delete existing collection if present
ingest_section_into_LOADING_collection(Laff_cpp, rctarget_align, rcsource, pwd, 1); % ingest
resp = set_renderer_stack_state_complete(rctarget_align);  % set to state COMPLETE





























