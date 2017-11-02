function [obj, errAb, mL, invalid_similarity, invalid_translation, R,...
    Ar, br, Br, d, W, K, Lm, xout, L2, U2, tB, td,...
    At, bt, Bt, dt, Wt, Kt, Lmt, xoutt, L2t, U2t, tBt, tdt] = ...
    get_rigid_approximation(obj, solver, opts)
%% calculates an approximation to a rigid transformation using the combination
% [1] Similarity constained
% [2] Rescaling
% [3] Translation only
% This function depends on "solver" utility functions
% Author: Khaled Khairy Janelia Research Campus (HHMI) 2015
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lsq_options.L2              = [];
lsq_options.U2              = [];
lsq_options.A               = [];
lsq_options.b               = [];
lsq_options.B               = [];
lsq_options.d               = [];
lsq_options.tB              = [];
lsq_options.td              = [];
lsq_options.W               = [];
lsq_options.dw              = [];


lsq_options.solver          = 'backslash';%'gmres';%'cgs';%'backslash';%;%'tfqmr';%'pcg';%'bicgstab';%''symmlq';%minres';%'lsqlin';% ;%'lsqr';%'bicgstab' bicg tfqmr backslash
lsq_options.constraint      = 'similarity';%'explicit';% 'trivial';%
lsq_options.constraint_only = 1;
lsq_options.pdegree         = 1;
lsq_options.lidfix          = 1;
lsq_options.tfix            = 1;%numel(obj.tiles);

lsq_options.verbose         = 0;
lsq_options.debug           = 0;

lsq_options.ilu_droptol     = 1e-16;
lsq_options.use_ilu         = 0;
lsq_options.ilu_type        = 'ilutp';%'crout'; %'nofill';%%;
lsq_options.ilu_udiag       = 1;
lsq_options.restart         = 10;
lsq_options.tol             = 1e-16;
lsq_options.maxit           = 10000;
lsq_options.apply_scaling   = 1;

if nargin>1
    lsq_options.solver       = solver;
end
translation_only = 0;  % default
if nargin<3
    translation_only = 0;
end
if nargin>2 && isfield(opts, 'translation_only')
    translation_only = opts.translation_only;
end
% if ~isempty(gcp('nocreate'))
%     lsq_options.distributed = 1;
% else
lsq_options.distributed = 0;
if isfield(opts, 'distributed'), lsq_options.distributed = opts.distributed;end
% end

if ~translation_only
    if isdeployed
        disp('Rigid solution using configuration:')
        disp(lsq_options);
        disp('-----------------------------------');
    end
    % perform similarity solution
    [mL,err, R, Ar, br, Br, d, W, K, Lm, xout, L2, U2, tB, td, invalid_similarity] = ...
        alignTEM_solver(obj, [], lsq_options);
    
    
    %% %% adjust scale--- mL
    scale_faco = 1.0;
    if nargin>2
        if isfield(opts, 'apply_scaling'), lsq_options.apply_scaling = opts.apply_scaling;end
        if isfield(opts, 'scale_fac'), scale_faco = opts.scale_fac;end
    end
    scale_fac = ones(numel(mL.tiles),1);
    scale_fac = scale_fac * scale_faco(1);
    if lsq_options.apply_scaling
        mtiles = mL.tiles;
        disp('Applying re-scaling');
       for ix = 1:numel(mL.tiles)
            
            %disp([ix mL.tiles(ix).tform.T(1) mL.tiles(ix).tform.T(5)]);
            %imshow(get_warped_image(mL.tiles(ix)));
            t = mL.tiles(ix);
            [U S V] = svd(t.tform.T(1:2, 1:2));
            T = U * [scale_fac(ix) 0; 0 scale_fac(ix)] * V';
            t.tform.T(1:2,1:2) = T;
            %t.tform.T([3 6]) = t.tform.T([3 6]) * 1/S;
            mtiles(ix) = t;
            %imshow(get_warped_image(t));title(num2str(ix));
            %pause(1);
        end
        mL.tiles = mtiles;
    else
        disp('skipping re-scaling');
    end
%     %%% sosi
%     disp('----------> SOSI get _rigid_approximation: saving mLs');
%     mLs = mL;
%     save mLs mLs Ar br Br d;
    
    %% transform point matches in order to translate
    M = mL.pm.M;
    adj = mL.pm.adj;
    for pix = 1:size(M,1) % loop over point matches
        %%%%%transform points for the first of the two tiles
        pm = M{pix,1};
        T = mL.tiles(adj(pix,1)).tform.T;
        pmt = pm*T(1:2,1:2);
        M{pix,1}(:) = pmt;
        %%%%%%%%%%%transform points for the second of the two tiles
        pm = M{pix,2};
        T = mL.tiles(adj(pix,2)).tform.T;
        pmt = pm*T(1:2,1:2);
        M{pix,2} = pmt;
    end
    mL.pm.M = M;
    mL.pm.adj = adj;
    %% fit for translation
    % Important: To do translation only we need to specify "no constraints", we
    % need to specify the tiles to fix and the polynomial degree should be zero
    %%%%%%%%%%%%%%%%%%%%%
    mL = update_adjacency(mL);
    mL = update_XY(mL);
    lsq_options.solver          = 'backslash';%
    lsq_options.constraint      = 'none';%'explicit';%'similarity';% 'trivial';%
    lsq_options.pdegree         = 0;  %
    lsq_options.constraint_only = 0;
    lsq_options.lidfix          = 1;
    lsq_options.tfix            = 1;%numel(obj.tiles);
    
    lsq_options.constrain_edges = 0;
    lsq_options.edge_lambda         = 0;
    lsq_options.lambda              = 0;
    
    if isdeployed
        disp('Translation-only solution using configuration:')
        disp(lsq_options);
        disp('-----------------------------------');
    end
    
    
    [mL2,errAb,R, At, bt, Bt, dt, Wt, Kt, Lmt, xoutt, L2t, U2t, tBt, tdt, invalid_translation] =...
        alignTEM_solver(mL, [], lsq_options);
    
    
else
    disp('---------------------------- TRANSLATION ONLY ----------------------');
    err = [];
    R = [];
    Ar = [];
    br= [];
    Br= [];
    d = [];
    W = [];
    K = [];
    Lm = [];
    xout = [];
    L2 = [];
    U2 = [];
    tB=[];
    td= [];
    invalid_similarity = [];
    %% fit for translation only
    % Important: To do translation only we need to specify "no constraints", we
    % need to specify the tiles to fix and the polynomial degree should be zero
    %%%%%%%%%%%%%%%%%%%%%
    mL = update_adjacency(obj);
    mL = update_XY(mL);
    lsq_options.solver          = 'backslash';%
    lsq_options.constraint      = 'none';%'explicit';%'similarity';% 'trivial';%
    lsq_options.pdegree         = 0;  %
    lsq_options.constraint_only = 0;
    lsq_options.lidfix          = 1;
    lsq_options.tfix            = numel(obj.tiles);
    
    lsq_options.constrain_edges = 0;
    lsq_options.edge_lambda         = 0;
    lsq_options.lambda              = 0;
    
    if isdeployed
        disp('Translation-only solution using configuration:')
        disp(lsq_options);
        disp('-----------------------------------');
    end
    
    
    [mL2,errAb,R, At, bt, Bt, dt, Wt, Kt, Lmt, xoutt, L2t, U2t, tBt, tdt, invalid_translation] =...
        alignTEM_solver(mL, [], lsq_options);
    
    
    
end

%%% sosi ---
%%%
% [obj.tiles(1).tform.T mL2.tiles(1).tform.T]
% mL3 = mL2;mL3.tiles(end) = [];
% for tix = 1:numel(mL3.tiles), mL3.tiles(tix).state = 1;end;
% layer_explorer(mL3);
% mL4 = obj;mL4.tiles(end) = [];
% show_map(mL3);figure;show_map(mL4);
%%%%
for tix = 1:numel(mL2.tiles), mL2.tiles(tix).state = 1;end;
errAb = norm(At*xoutt-bt);
obj.tiles = mL2.tiles;  % only tile transformations are changed (not point-match information)












