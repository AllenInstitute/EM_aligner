function [L, L_vec, pm_mx, err, scl, h, toc_load_pm, toc_rigid] = ...
    solver_regularization_parameter_sweep(...
    nfirst, nlast, rcsource, pm, opts, regstart, regfinish, step)
% Performs a regularization parameter sweep between regstart and regfinish (inclusive)
% Test for best regularization parameter graphically
% This is the smallest parameter value that does not cause downscaling of tiles
% if nfirst==nlast, a rigid approximation is performed (with pegs) and regularization is performed
% relative to the rigid approximation
% Author: Khaled Khairy. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialize quantities
toc_rigid = 0;

%
tic_load_pm = tic;
[L, ~, ~, pm_mx] = load_point_matches(nfirst, nlast, rcsource, pm, opts.nbrs, opts.min_points, opts.xs_weight); % disp(pm_mx{ix});
toc_load_pm = toc(tic_load_pm);
disp('Loaded point matches and generated section in (s):');
disp(toc_load_pm);

if nlast-nfirst==0,
    disp('Section montage detected. Rigid approximation will be performed and parameter sweep performed based on it.');
    L = add_translation_peggs(L, sl.solver_options.peg_npoints, sl.solver_options.peg_weight);
end

[L_vec, ntiles] = reduce_to_connected_components(L);
L_vec(ntiles<10) = [];


if nlast-nfirst==0
    disp('-- Solving for rigid approximation');
    tic_rigid = tic;
    opts_rigid = opts;
    opts_rigid.distributed = 0;
    [L_vec, errR, mL, is, it, Res]  = get_rigid_approximation(L_vec, opts_rigid.solver, opts_rigid);
    %%% remove peggs and last tile
    last_tile = numel(L_vec.tiles);
    del_ix = find(L_vec.pm.adj(:,2)==last_tile);
    L_vec.pm.M(del_ix,:)  = [];
    L_vec.pm.adj(del_ix,:) = [];
    L_vec.pm.W(del_ix) = [];
    L_vec.pm.np(del_ix) = [];
    L_vec.tiles(end) = [];
    L_vec = update_adjacency(L_vec);
    toc_rigid = toc(tic_rigid);
    disp(toc_rigid);
    disp('-- done solving for rigid approximation');
end


solve_time = [];
err = [];
scl = [];
count = 1;
for explambda = [regstart:step: regfinish]
    disp(explambda);
    kkt = tic;
    opts.lambda = 10^explambda;
    opts.edge_lambda = 10^(explambda);
    %[mL2, A, err_res, R]= solve_slab(rcsource, pm, nfirst, nlast, [], opts); % uses Renderer collection to solve
    %[mL2, err_res, R] = solve_clusters(L_vec, opts, opts.stvec_flag);   % uses Msection object, and solves individual clusters and reassembles them into one
    
    %%% 
    if opts.degree==1
    [lsolved, err(cix), Res, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
                invalid, time_Axb] = solve_affine_explicit_region(L_vec, opts);
    elseif opts.degree>1
        [lsolved, err(cix), Res, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
                invalid, time_Axb] =...
                solve_polynomial_explicit_region(L_vec,opts.degree, opts);
    end
    
    
    
    err(count) = max(err_res);
    
    % measure deformation
    parfor ix = 1:numel(mL2.tiles)
        t = mL2.tiles(ix);
        tf = t.tform;
        if isa(tf,'images.geotrans.PolynomialTransformation2D')
            T = [t.tform.A([2 3])' t.tform.B([2 3])'];
            [U S V] = svd(T(1:2, 1:2));
        else
            [U S V] = svd(t.tform.T(1:2, 1:2));
        end
        detS(ix) = det(S);
    end
    %     states = [mL2.tiles(:).state]==1;
    %     detS = detS(states); % remove entries for discarded tiles
    scl(count) = sum((detS-1).^2);  % for affine
    
    %scl(count) = sum(([mL2.tiles(20).tform.A(2) mL2.tiles(20).tform.A(2)]-1).^2)/2;  % for higher order
    %polynomials
    solve_time(count) = toc(kkt);
    disp(['time: ' num2str(solve_time(count))]);
    count = count + 1;
end

% plot
explambda = [regstart:step: regfinish];
h = figure;
plot(explambda, mat2gray(err), 'LineWidth', 1.0, 'Color', [1 0 0]);
hold on;
plot(explambda, mat2gray(scl), 'LineWidth', 1.0,'Color', [0 0 1]);