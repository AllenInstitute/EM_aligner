clc; clear all;
kk_clock;
nfirst = 1;
nlast  = 50;


% configure source collection
rcsource.stack          = 'v12_acquire_merged';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% % configure source collection
% rc.stack          = 'v12_align';
% rc.owner          ='flyTEM';
% rc.project        = 'FAFB00';
% rc.service_host   = '10.37.5.60:8080';
% rc.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rc.verbose        = 1;

% configure montage collection
rctarget_montage.stack          = ['EXP_dmesh_montage_P1_' num2str(nfirst) '_' num2str(nlast)];
rctarget_montage.owner          ='flyTEM';
rctarget_montage.project        = 'test';
rctarget_montage.service_host   = '10.37.5.60:8080';
rctarget_montage.baseURL        = ['http://' rctarget_montage.service_host '/render-ws/v1'];
rctarget_montage.verbose        = 1;


% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';


% % configure solver
% opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
% opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
% opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
% opts.lambda = 1e-1;
% opts.edge_lambda = 1e-1;
% opts.solver = 'backslash';
% opts.min_points = 5;
% opts.nbrs = 0;
% opts.xs_weight = 1/100;
% opts.stvec_flag = 0;   % i.e. do not assume rcsource providing the starting values.
% opts.distributed = 0;


% configure solver
opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
opts.lambda = 10^(-1);
opts.edge_lambda = 10^(-1);
opts.solver = 'backslash';
opts.min_points = 5;
opts.nbrs = 0;
opts.xs_weight = 1/100;
opts.stvec_flag = 0;   % i.e. do not assume rcsource providing the starting values.
opts.distributed = 0;
opts.base_collection = []; % use rough collection to  place connected 
                           % components relative to each other



% solve montages and ingest into collection
err = {};
R = {};
failed_list = [];
count = 1;
for lix = nfirst:nlast
    disp(['Solving section: ' num2str(lix) ' of ' num2str(nlast)]);
    try
    [mL1, A, err{lix}, R{lix}]= solve_slab(rcsource, pm, lix, lix, [], opts);
     catch err_solving
         kk_disp_err(err_solving);
         failed_list = [failed_list lix];
    end
    try
        ingest_section_into_LOADING_collection(mL1, rctarget_montage, rcsource, pwd, 1);
    catch err_ingesting
         kk_disp_err(err_ingesting);
    end

end
resp = set_renderer_stack_state_complete(rctarget_montage);
