function [L_vec,a] = reduce_to_connected_components(obj, mintiles)
% obj can be a collection of tiles that are not in one section (i.e. with or without same z-value).
% Outputs an array of Msection objects (also not necessarily limited to one
% z-value) that are contiguous (connected -- in 2 or 3 dimensions) by point-matches in a "graph"
% sense.
% obj is an Msection object that already has a complete pm struct
% The idea is that each connected component can be solved using the matrix
% solver separately. Note: These connected components need to be assembled
% afterwards.
%
%
% Author: Khaled Khairy. Copyright 2016. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin<2, mintiles = 1;end

% generate a graph object, based on point-matches
if isempty(obj.pm.adj)
    error('Point-match set appears to be empty: check point-match collection or try reducing "min_points"?');
else
    obj.G = graph(obj.pm.adj(:,1), obj.pm.adj(:,2), obj.pm.np, {obj.tiles(:).renderer_id});
    b = conncomp(obj.G, 'OutputForm', 'vector');  % generate logical clusters (connected components)
    bins = unique(b);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % %%% sosi --- expand on below to generate some form of report about components found
    % for bix = 1:numel(bins)
    %     occur(bix) = sum(b==bins(bix));
    % end
    % indx = find(occur>3);
    % bar(occur(indx));
    % disp(bins(indx));
    % disp(occur(indx));
    % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %%
    if numel(bins)>1
        for bix = 1:numel(bins)
            indx = b==bins(bix);
            if sum(indx)>mintiles
                L_vec(bix) = reduce_to_tile_subset(obj, find(indx));
            else
                L_vec(bix) = Msection(obj.tiles(indx));
            end
            ntiles(bix) = sum(indx);
            
        end
        [a, c] = sort(ntiles, 'descend');
        L_vec = L_vec(c);
    else
        L_vec = obj;
        a = numel(obj.tiles);
    end
end
