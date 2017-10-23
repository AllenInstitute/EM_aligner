% Example script to solve a FAFBv12 slab for an existing set of point matches
%
% Assumes that all the work for generating point-matches has been done
% at the tile level
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%% [0] configure collections and prepare quantities
clc;kk_clock;

nfirst = 1000;
nlast  = 1050;
%nlast  = 1200;

% % configure source collection
% rcsource.stack          = 'v12_acquire_merged';
% rcsource.owner          ='flyTEM';
% rcsource.project        = 'FAFB00';
% rcsource.service_host   = '10.37.5.60:8080';
% rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
% rcsource.verbose        = 1;


% configure source collection
rcsource.stack          = 'EXP_dmesh_rough_P1_1000_1200';
rcsource.owner          ='flyTEM';
rcsource.project        = 'test';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure align collection
rctarget_align.stack          = ['EXP_dmesh_fine_P2_' num2str(nfirst) '_' num2str(nlast)];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;

% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';

% configure solver
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';
opts.min_points = 5;
opts.nbrs = 4;
opts.xs_weight = 1;
opts.stvec_flag = 0;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 1;

%%
opts.lambda = 10^(-1);
opts.edge_lambda = 10^(-1);

opts.base_collection = [];
opts.conn_comp = 0;
opts.use_peg = 0;
opts.peg_weight = 1e-3;
opts.peg_npoints = 5;



% % % % test for best regularization parameter
% % % % This is the smallest that does not cause shrinkage of tiles
% % regstart = -2;
% % regfinish = 5;
% % step = 0.5;
% %
% % %[L, ~, ~, pm_mx] = load_point_matches(nfirst, nlast, rcsource, pm, opts.nbrs, opts.min_points, opts.xs_weight); % disp(pm_mx{ix});
% %
% %
% % [L, L_vec, pm_mx, err, scl, h] = ...
% %     solver_regularization_parameter_sweep(nfirst, nlast, rcsource, pm, ...
% %                                           opts, regstart, regfinish, step);

%% read point-matches and filter them
[L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
    load_point_matches(nfirst, nlast, rcsource, pm, opts.nbrs, ...
    opts.min_points, opts.xs_weight); % disp(pm_mx{ix});
L.pm = filter_pm(L.pm);



%% start actual solver process
if opts.degree==1
[mL, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
    invalid] = solve_affine_explicit_region(L, opts);
else
    disp('----------------- Solving using polynomial degree:');
    disp(opts.degree);
    [mL, err1, Res1] =...
                solve_polynomial_explicit_region(L,opts.degree, opts);
    
end
npoints = size(A,1);
nparms = size(A,2);
nttiles = nparms/6;
%%% determine residual per tile
R = mat2gray(Res1);
hist(Res1,1000);

disp('Error in pixels per tile:');
disp(err1/numel(mL.tiles));



%%
[mL, Af, Sf] = filter_based_on_tile_area(mL, opts.outlier_lambda);

%%%%% ingest affine solution
try
    ingest_section_into_renderer_database_overwrite(mL, rctarget_align, rcsource, pwd, 1);
    %resp = set_renderer_stack_state_complete(rctarget_montage);
catch err_ingesting
    
    disp(['Error ingesting affine: ' num2str(nfirst) ]);
    kk_disp_err(err_ingesting);
end
disp('Error in pixels per tile:');
disp(err1/numel(mL.tiles));


%% render optional
% Wbox = [103000 75000 1700 1700];
% scale = 1.0;
% % [im, v, url] = get_image_box_renderer(rctarget_align, 1000, Wbox, scale);
% % imshow(im);
% 
% 
% im = zeros(Wbox(3)*scale, Wbox(4) * scale, numel([nfirst:nlast]));
% vec = [nfirst:nlast];
% vec = vec(:);
% parfor ix = 1:numel(vec)
%     disp(ix);
% %     try
%         im(:,:, ix)= get_image_box_renderer(rctarget_align, vec(ix), Wbox, scale);
%            
% %     catch err
% %         disp(['Err: ' num2str(ix)']);
% %     end
% end
% im = mat2gray(im);
% implay(im);
















