function [ntiles_o, ntiles_aff, toc_load_z, time_pm_load, time_gen_A,...
    time_Axb, median_error_affine, sz_A, nnzA, nnzK, xout, tile_err, err, precision] ...
    = timing_loading_solving(sl, z)
nparms = (sl.solver_options.degree + 1) * (sl.solver_options.degree + 2); % twice number of coefficients for a particular polynomial

%% time to load section from Renderer
L = Msection(sl.source_collection, z);
ntiles_o = numel(L.tiles);
tic_load_z = tic;
L = Msection(sl.source_collection, z);
toc_load_z = toc(tic_load_z);
disp(' Time to load tiles and create section object: ');
disp(toc_load_z);
%% time to load point-matches
% [L, tIds, PM, pm_mx, sectionId_load, z_load]  = ...
%     load_point_matches(...
%     sl.z_value,...
%     sl.z_value,...
%     sl.source_collection, ...
%     sl.source_point_match_collection,...
%     0,...
%     sl.solver_options.min_points,...
%     sl.solver_options.xs_weight,...
%     sl.solver_options.max_points);

tic_load_pm = tic;

[L, tIds, PM, pm_mx, sectionId_load, z_load, time_pm_load]  = ...
    load_point_matches(...
    sl.z_value,...
    sl.z_value,...
    sl.source_collection, ...
    sl.source_point_match_collection,...
    0,...
    sl.solver_options.min_points,...
    sl.solver_options.xs_weight,...
    sl.solver_options.max_points);

toc_load_pm = toc(tic_load_pm);
disp(' Time to load tiles and create section object: ');
disp(toc_load_pm);

L = add_translation_peggs(L, sl.solver_options.peg_npoints, sl.solver_options.peg_weight);
[L, ntiles] = reduce_to_connected_components(L, sl.solver_options.min_tiles);
L = L(1);
%% solve rigid approximation
sl.solver_options.distributed = 0;
[Lr, errR, mL, is, it, Res, ...
    A, b, B, d, W, K, Lm, xout, L2, U2, tB, td,...
    At, bt, Bt, dt, Wt, Kt, Lmt, xoutt, L2t, U2t, tBt, tdt]  =...
    get_rigid_approximation(L, 'backslash', sl.solver_options);


%%% remove peggs and last tile
last_tile = numel(Lr.tiles);
del_ix = find(Lr.pm.adj(:,2)==last_tile);
Lr.pm.M(del_ix,:)  = [];
Lr.pm.adj(del_ix,:) = [];
Lr.pm.W(del_ix) = [];
Lr.pm.np(del_ix) = [];
Lr.tiles(end) = [];
Lr = update_adjacency(Lr);

%%%%% if calling external C++ solver (using rigid approximation as regularizer)
if strcmp(sl.solver_options.solver, 'jdr')
    % % call cpp solver program
    % clc;
    disp('-------------------- Invoking cpp solver --------------');
    dir_scratch = '/groups/flyTEM/home/khairyk/solver_paper_work/scratch';
    delete([dir_scratch '/*.json']);
    disp('calling jdr solver');
    debugjdr = 0;
    lambda = sl.solver_options.lambda;
    degree = sl.solver_options.degree;
    
    if sl.solver_options.jdr_options.stvec==0  % calculate rigid_approximation followed by affine
                                               % works!
        disp('JDR: calculating both rigid and affine');
        L_jdr = L;
        stvec = 0;
        fn_canvas_input = '';
    else                                      % calcualte affine based on pre-calcualted rigid
                                              % DOES NOT WORK YET --- DEBUG PLEASE
        L_jdr = Lr;
        stvec = 1;   % use fn_canvas_input as input for regularization
        %%% generate json rotation approximation tile-spec file
        fn_canvas_input = ...
            [dir_scratch '/tmp_rap_canvases.json'];
        disp('Generating json rotation approximation tile-spec file ...');
        tic;jstr_rap = export_json(L_jdr, fn_canvas_input);toc;
        if debugjdr
            type(fn_canvas_input);
        end
    end
    
    fnpmjson = ...
        [dir_scratch '/tmp_pm.json'];
    disp('Generating json point-match file ...');
    tic;jstr = PM_json(L_jdr, fnpmjson);toc;
    
    %%% sosi
    %fnpmjson ='/groups/flyTEM/home/khairyk/downloads/JDR/example01_pm.json';
    
    time_Axb = -999;
    time_gen_A = -999;

    kk_clock;
    fn_canvas_json_output = ...
        [dir_scratch '/canvases_out.json'];
    solv_cmd = '/groups/flyTEM/home/khairyk/downloads/jdr/joint-image-registration-solver/jdr_solver';
    
    
    cmd = [solv_cmd ' ' fnpmjson ' ' fn_canvas_json_output ' ' num2str(degree) ...
        ' ' num2str(lambda) ' ' num2str(stvec) ' ' fn_canvas_input];
    
    delete('/groups/flyTEM/home/khairyk/solver_paper_work/A.mm');
    delete('/groups/flyTEM/home/khairyk/solver_paper_work/xout.mm');  
    
    
    %%% issue system command directly (runs locally)
    tic;[a,resp_str] = system(cmd);toc
    
    %%% qsub
    
    if debugjdr
        disp(resp_str);
        disp(fn_canvas_json_output);
        type(fn_canvas_json_output);
    end
    
    
    
    %%% diagnostic and profiling information
    C = strsplit(resp_str, 'TIME_');
    c = strsplit(C{2}, ' ');
    time_gen_A = str2double(c{2});
    disp('Generate A:');disp(c{2});
    c = strsplit(C{3}, ' ');
    time_Axb = str2double(c{2});
    disp('Solve:');disp(c{2});
    disp('finished cpp solution');
    kk_clock;
    %disp(resp_str);
    if sl.solver_options.jdr_options.stvec==0
        mLjdr = update_transformation_from_json(L,fn_canvas_json_output);
        
        %%% remove peggs and last tile
        last_tile = numel(mLjdr.tiles);
        del_ix = find(mLjdr.pm.adj(:,2)==last_tile);
        mLjdr.pm.M(del_ix,:)  = [];
        mLjdr.pm.adj(del_ix,:) = [];
        mLjdr.pm.W(del_ix) = [];
        mLjdr.pm.np(del_ix) = [];
        mLjdr.tiles(end) = [];
        mLjdr = update_adjacency(mLjdr);
    else
        
        mLjdr = update_transformation_from_json(Lr,fn_canvas_json_output);
    end
    %%% to continue diagnostics we need to get A and xout for jdr solution
%     sld = sl;
%     sld.solver_options.matrix_only = 1;
%     [mL, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
%         invalid] = solve_affine_explicit_region(mLjdr,...
%         sld.solver_options);


[A,rows,cols,entries,rep,field,symm] = mmread('/groups/flyTEM/home/khairyk/solver_paper_work/A.mm');
% [B,rows,cols,entries,rep,field,symm] = mmread('/groups/flyTEM/home/khairyk/solver_paper_work/B.mm');
% [W,rows,cols,entries,rep,field,symm] = mmread('/groups/flyTEM/home/khairyk/solver_paper_work/W.mm');
% [d,rows,cols,entries,rep,field,symm] = mmread('/groups/flyTEM/home/khairyk/solver_paper_work/d.mm');
% [K,rows,cols,entries,rep,field,symm] = mmread('/groups/flyTEM/home/khairyk/solver_paper_work/K.mm');
% [Lm,rows,cols,entries,rep,field,symm] = mmread('/groups/flyTEM/home/khairyk/solver_paper_work/Lm.mm');
[xout,rows,cols,entries,rep,field,symm] = mmread('/groups/flyTEM/home/khairyk/solver_paper_work/xout.mm');

mL = mLjdr;
    
else
    
    
    %% point-match erros and point-match tile-based errors
    % r_res = At * xoutt;
    % [Lrc, tpr] = tile_based_point_pair_errors(Lr, At, xoutt);
    %% solve affine
    disp('Solving affine using solve_affine_explicit_region.m ');
    disp(sl.solver_options);
    [mL, err1, Res1, A, b, B, d, W, K, Lm, xout, LL2, U2, tB, td,...
        invalid, time_Axb, time_gen_A] = solve_affine_explicit_region(Lr, sl.solver_options);
%     
end
    precision = norm(K*xout-Lm)/norm(Lm);
    disp(['Precision: ' num2str(precision)]);
    err = norm(A*xout-b);
    disp(['Error norm(Ax-b): ' num2str(err)]);  
    
    
nnzK = nnz(K);
nnzA = nnz(A);
disp('time constructing linear system');
disp(time_gen_A);
disp('time solving A x = b');
disp(time_Axb);
%% point-match erros and point-match tile-based errors
% a_res = A * xout;
[mLc, tpr, resout, tile_err] = tile_based_point_pair_errors(mL, A, xout);
figure; hist(resout, 10);
median_error_affine = median(resout);
ntiles_aff = numel(xout)/nparms; %numel(resout);%sum([mLc.tiles(:).state]);
disp(ntiles_aff);
disp(median_error_affine);
sz_A = size(A);
% figure(1);hist(a_res);
% figure(2); hist(resout);
%disp(resout);
%% regularization parameter sweep
% [L, L_vec, pm_mx, err, scl, h, toc_load_pm, toc_rigid] = ...
%     solver_regularization_parameter_sweep(...
%     nfirst, nlast,...
%     rcsource, pm, opts, regstart, regfinish, step);

end

