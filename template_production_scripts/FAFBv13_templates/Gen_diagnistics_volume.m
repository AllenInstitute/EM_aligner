%% generate diagnostic information  --- do not use --- experimental
clear all;
Slab_definition;
dir_temp = '/nrs/flyTEM/khairy/FAFB00v13/matlab_slabs';
%%
opts.min_tiles = 20; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e2;  % large numbers result in fewer tiles excluded
opts.solver = 'backslash';
opts.min_points = 5;
opts.nbrs = 4;
opts.xs_weight = 1;
opts.stvec_flag = 1;   % 0 = regularization against rigid model (i.e.; starting value is not supplied by rc)
opts.distributed = 1;
opts.lambda = 10^(-2);
opts.edge_lambda = 10^(-2);


ns = 15;
tids = cell(ns,1);
z = cell(ns,1);
for six = 1:ns
    % load slab data
    fn = [dir_temp '/Solved_PRD_dmesh_fine_P1_' num2str(nfirstvec(six)) '_' num2str(nlastvec(six)) '_xs_2.mat'];
    if exist(fn, 'file')==2
        disp('Loading from existing file');
        mL = loadX(fn,{'mL', 'A', 'xout', 'L'});
    else
        disp('Reading slab from Renderer ... ');
        tic
        %[mL, tiles12] = get_slab_tiles(fine_collection{six}, nfirstvec(six), nlastvec(six));
        
        
        [mL]  = ...
            load_point_matches(nfirstvec(six), nlastvec(six), fine_collection{six}, pm, opts.nbrs, ...
            opts.min_points, opts.xs_weight); % disp(pm_mx{ix});
        toc
    end
    
    %%% -------------tile-based point-match errors
    % generate point-pair residual information
    if exist('A')==0
        diary off;
        diary on;
        disp('Generating A and xout by solving the system');
        [mL, err1, Res1, A, ~, ~, d, ~, ~, Lm, xout] = solve_affine_explicit_region(L, opts);
    end
    res = A*xout;
    resx = zeros(size(res,1)/2,1);
    resy = zeros(size(res,1)/2,1);
    tpr = cell(numel(mL.tiles),1);
    % initialize
    for tix = 1:numel(mL.tiles)
        tpr{tix} = [];
    end
    
    
    % aggregate absolute point-pair error for each tile
    count = 1;
    for pix = 1:size(mL.pm.M,1)
        indx1 = mL.pm.adj(pix,1);
        indx2 = mL.pm.adj(pix,2);
        
        vecx = count:count+mL.pm.np(pix)-1;
        vecy = count+mL.pm.np(pix):count+2*mL.pm.np(pix)-1;
        npoints = numel(vecx);
        rx = sum(abs(res(vecx)),1)/npoints;
        ry = sum(abs(res(vecy)),1)/npoints;
        tpr{indx1} = [tpr{indx1};rx ry];
        tpr{indx2} = [tpr{indx2};rx ry];
        count = count + 2* mL.pm.np(pix);
    end
    
    % average the error
    for pix = 1:numel(mL.tiles)
        if isempty(tpr{pix})
            confidence{six}(pix, :) = [nan nan];
        else
            confidence{six}(pix, :) = sum(tpr{pix},1)/size(tpr{pix},1);
        end
    end
    %%%%%%%%%%%%%%%%%%%%%
    [mL, deformation{six}, Ar{six}, S{six}] = tile_based_deformation(mL, 100);
    tids(six) = {{mL.tiles(:).renderer_id}'};
    z(six) = {[mL.tiles(:).z]'};
end
%% concatenate
a = [];
p = [];
d = [];
c1= [];
c2 = [];
zval = [];
ids = {};
for six = 1:ns
    a = [a Ar{six}'];
    p = [p S{six}'];
    d = [d deformation{six}'];
    zval = [zval; z{six}(:)];
    ids  = [ids; tids{six}];
    c1 = [c1; confidence{six}(:,1)];
    c2 = [c2; confidence{six}(:,2)];
end




%% identify histograms by z value for each  section


hist(c1(zval==35));

% for six = 1:1%ns
%     mp = [];
%     ma = [];
%     md = [];
%     zs = unique(z{six});
%     for zix = 1:numel(zs)
%         indx = find(z{six}==zix);
%         acurr = Ar{six}(indx);
%         pcurr = S{six}(indx);
%         dcurr = deformation{six}(indx);
%         
%         mp = [mp mean(pcurr)];
%         ma = [ma mean(acurr)];
%         md = [md mean(dcurr)];
%         
%         c1agg = c1{
%         
%         %         hist(Ar{six}(indx));
%     end
% end



















