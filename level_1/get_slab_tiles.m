function [L, tiles12] = get_slab_tiles(rc, z1, z2)
% fast access to tiles between z1 and z2 (inclusive)
[zu1] = get_section_ids(rc, z1, z2);
tiles12 = {};
parfor ix = 1:numel(zu1)
    [~, ~, tids, til] = get_tile_centers(rc, zu1(ix));
    tiles12{ix} = til.tiles;
end
tiles12 = [tiles12{:}]';
L = Msection(tiles12);  % part that overlaps from fixed
