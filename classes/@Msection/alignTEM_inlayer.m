function [obj, js] = alignTEM_inlayer(obj)
%% Solves the montage problem for a given section
%%% [1] generate features for tiles
%%% [2] estimates point matches
%%% [3] solves using rigid transform as regularizer


%% make sure the object is up-to-date
obj  =  update_XY(obj);
obj  = update_adjacency(obj);
%% generate features for all tiles
[obj] = calculate_tile_features(obj);
%% generate point matches
min_pm = 6;
[L2] = generate_point_matches(obj, min_pm);
%% generate json point-match data
counter = 1;
M = L2.pm.M;
adj = L2.pm.adj;
sectionID = L2.sectionID;
for mix = 1:size(M,1)
    indx1 = adj(mix,1);
    indx2 = adj(mix,2);
    tid1 = [L2.tiles(indx1).renderer_id];
    tid2 = [L2.tiles(indx2).renderer_id];

    MP{counter}.pz = sectionID;
    MP{counter}.pId= tid1;
    MP{counter}.p  = M{mix,1};
    
    MP{counter}.qz = sectionID;
    MP{counter}.qId= tid2;
    MP{counter}.q  = M{mix,2};
    counter = counter + 1;
end
js = pairs2json(MP); % generate json blob to be ingested into point-match database
%% decompose into connected components
[L_vec, a] = reduce_to_connected_components(L2);
%% solve components and collect
opts.min_tiles = 2; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 1;    % 0 = rigid approximation, 1 = affine, 2 = second order polynomial, maximum is 3= third order polynomial
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
opts.lambda = 1e3;
opts.edge_lambda = 1e6;
opts.solver = 'backslash';
mL = solve_clusters(L_vec, opts);   % solves individual clusters and reassembles them into one
%% translate to origin to be Renderer friendly
obj = translate_to_origin(mL);


