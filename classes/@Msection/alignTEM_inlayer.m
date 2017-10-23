function [obj, js, err, L2] = alignTEM_inlayer(obj, opts)
%% Solves the montage problem for a given section
%%% [1] generate features for tiles
%%% [2] estimates point matches
%%% [3] solves using rigid transform as regularizer

if nargin<2
    disp('Using defaults options for registration/solution:');
opts.scale  = 0.5;  %scale at which SURF features are calculated
opts.degree = 1;
opts.solver = 'backslash';
opts.stvec_flag = 0;   % i.e. do not assume rcsource providing the starting values.
opts.distributed = 1;
opts.base_collection = [];
opts.conn_comp = 1;
opts.use_peg = 1;
opts.peg_weight = 1e-4;
opts.peg_npoints = 5;
opts.lambda = 10^(-1);
opts.edge_lambda = 10^(-1);
disp(opts);
end


%% make sure the object is up-to-date
%obj  = update_XY(obj);
obj  = update_adjacency(obj);
%% generate point matches
min_pm = 10;
if isdeployed
    kk_clock();
    disp('Calculating image features and point-matches....');
    tic
end
[L2] = generate_point_matches(obj, min_pm, opts.filter, opts.scale); % also makes sure features are calculated
if isdeployed
    disp('Finished calculating image features and point-matches!');
    toc
    kk_clock();
end

%disp(L2.pm.M);



disp('Options struct:');
disp(opts);

if opts.use_peg
    if isdeployed
        disp('Added translation pegs.');
    end
    L = add_translation_peggs(L2, opts.peg_npoints, opts.peg_weight);
end

[L, ntiles] = reduce_to_connected_components(L);
L = L(1);

if isdeployed
    disp('Reduced to one connected component.');
    tic
end

[Lr, errR, mL, is, it, Res]  = get_rigid_approximation(L, opts.solver, opts);
if isdeployed
    disp('Calculated rigid approximation.');
    toc
end
%%% remove peggs and last tile
last_tile = numel(Lr.tiles);
del_ix = find(Lr.pm.adj(:,2)==last_tile);
Lr.pm.M(del_ix,:)  = [];
Lr.pm.adj(del_ix,:) = [];
Lr.pm.W(del_ix) = [];
Lr.pm.np(del_ix) = [];
Lr.tiles(end) = [];
Lr = update_adjacency(Lr);

if isdeployed
    disp('Removed pegs.');
    tic
end

if opts.degree==1
[mL, err1, Res1, A] = solve_affine_explicit_region(Lr, opts);
else
    disp('----------------- Solving using polynomial degree:');
    disp(opts.degree);
    [mL, err1, Res1, A] =...
                solve_polynomial_explicit_region(Lr,opts.degree, opts);
end        
            

if isdeployed
    disp('Error in pixels per tile:');
    disp(err1/numel(mL.tiles));
    disp('Error in percent pixels per point-match:');
    disp(err1/size(A,1) * 100);
    disp('Finished full affine solve.');
    toc
end



% %% decompose into connected components
% [L_vec, a] = reduce_to_connected_components(L2);
% %% solve components and collect
% opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
% opts.degree = 1;    % 0 = rigid approximation, 1 = affine, 2 = second order polynomial, maximum is 3= third order polynomial
% opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
% opts.lambda = 1e0;
% opts.edge_lambda = 1e1;
% opts.solver = 'backslash';
% [mL, err] = solve_clusters(L_vec, opts);   % solves individual clusters and reassembles them into one
% 
% 
% 
% 
% 






%% translate to origin to be Renderer friendly
if isdeployed
    disp('Translating to positive space.');
    tic
end
obj = translate_to_origin(mL);

if isdeployed
    toc
    disp('Done!');
end

%% if output js is requested, then generate json point-match data
if nargout>1
    counter = 1;
    M = L2.pm.M;
    adj = L2.pm.adj;
    %sectionID = L2.sectionID;
    for mix = 1:size(M,1)
        indx1 = adj(mix,1);
        indx2 = adj(mix,2);
        tid1 = [L2.tiles(indx1).renderer_id];
        tid2 = [L2.tiles(indx2).renderer_id];
        
        MP{counter}.pz = L2.tiles(indx1).sectionId;
        MP{counter}.pId= tid1;
        MP{counter}.p  = M{mix,1};
        
        MP{counter}.qz = L2.tiles(indx2).sectionId;
        MP{counter}.qId= tid2;
        MP{counter}.q  = M{mix,2};
        counter = counter + 1;
    end
    js = pairs2json(MP); % generate json blob to be ingested into point-match database
end
