%%
rc.stack          = ['PROD_FINE_MP1_RR_P1_1_35_xs_2'];
rc.owner          ='flyTEM';
rc.project        = 'test2';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rctarget_rough.service_host '/render-ws/v1'];
rc.verbose        = 1;


%% configure point-match collection
pm.server           = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner            = 'flyTEM';
pm.match_collection = 'v12_dmesh';

% configure solver
opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e1;  % large numbers result in fewer tiles excluded

opts.lambda = 10^(-1);
opts.edge_lambda = 10^(-1);

opts.solver = 'backslash';
opts.min_points = 3;
opts.nbrs = 0;
opts.xs_weight = 1/100;
opts.stvec_flag = 0;   % i.e. do not assume rcsource providing the starting values.
opts.distributed = 0;
opts.base_collection = [];
opts.conn_comp = 1;
opts.use_peg = 1;
opts.peg_weight = 1e-4;
opts.peg_npoints = 5;

%%
[L, tIds, PM, pm_mx, sectionId, z] = load_point_matches(1, 1, rc, pm, opts.nbrs, opts.min_points, 1);
layer_explorer(L);
v1 = 18;
v2 = 23;
indx = find(L.pm.adj(:,1)==v1);
indx1 = L.pm.adj(indx(2),:);
%%
t1 = L.tiles(18);
t2 = L.tiles(23);
%% make the new two-tile section
Ls = Msection([t1 t2]);
Ls.pm.M = L.pm.M(23,:);
Ls.pm.adj = [1 2];
Ls.pm.W = L.pm.W(23,:);
Ls.pm.np = L.pm.np(23);
%% solve
[Lr, errR, mL, is, it, Res]  = get_rigid_approximation(Ls, opts.solver);
[mLra, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
            invalid] = solve_affine_explicit_region(Lr, opts);
        
disp(mLra.tiles(1).tform.T);
disp(mLra.tiles(2).tform.T);

save two_tile_matrix_system K Lm xout