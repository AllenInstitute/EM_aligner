function L = merge_layers(L, L2)
% merge sections by concatenating the tiles array and
% updating the section information (and row and column information?)
% sosi -- needs to also merge rprt information in future

if numel(L2)==1 
    L2 = set_z(L2, L.z);
    % assumes just merging tiles in L and L2
    L.tiles = [L.tiles L2.tiles];
else % we assume L will be concatenating all tiles in all layers in the L2 array
     % and that this will replace the tiles in L
    for ix = 1:numel(L2)
        L2(ix) = set_z(L2(ix), L.z);
        L.tiles = [L.tiles L2(ix).tiles];
    end
end
L.update_adjacency_switch = 1;
L.update_tile_info_switch = -1;
L = update_adjacency(L);
L = update_XY(L);
L = update_tile_info(L);
L = get_bounding_box(L);
L = generate_hash_tables(L);
L.rprt = [];