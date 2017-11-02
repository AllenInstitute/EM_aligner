function [ S, G, clusters] = calculate_connectivity_from_pm_stuct(PM, number_of_tiles)
number_of_pairs = size(PM.M,1);
tiles_1 = zeros(1, number_of_pairs);
tiles_2 = zeros(1, number_of_pairs);
number_of_matches = zeros(1, number_of_pairs);
parfor i=1:number_of_pairs
    tiles_1(i) = PM.adj(i,1);
    tiles_2(i) = PM.adj(i,2);
    number_of_matches(i) = PM.np(i);
end
S = sparse(tiles_1, tiles_2, number_of_matches, number_of_tiles, number_of_tiles);
G = graph(S,'upper');
clusters = conncomp(G);
% [counts,cluster_number] = histcounts(clusters,unique(clusters));
% small_clusters = cluster_number(counts<min_cluster_size);
end

