function obj = update_tile_info(obj)
% Fill in tile-objects header information from files (slow), or from first
% (fast) if all tiles have same size
% Warning: This has not been updated to work with the Renderer service yet.
% In particular the method "tile.set_info" in tile.m needs updating.
% Therefore it could happen that it looks at the path with would point to a
% file that has not been lens corrected.
%
% Usage:  obj = update_tile_info(obj)
% Note: variable obj.update_tile_switch = 1 --> force slow update of individual tile information
%                obj.update_tile_switch = 0 --> no update required
%                obj.update_tile_switch = -1 --> use first tile info for all (default)
% After update obj.update_tile_switch is set to zero.
%
% Author: Khaled Khairy. Janelia Research Campus.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if obj.update_tile_info_switch == 1
    %disp('One-time updating of tile info from files! This can take time for large numbers of tiles');
    for ix = 1:numel(obj.tiles)
        obj.tiles(ix).H = 0;
        obj.tiles(ix) = set_info(obj.tiles(ix));
    end
    obj.update_tile_info_switch = 0;
    %disp('Done: Update tile info.');
elseif obj.update_tile_info_switch == -1
    % set all tile H and W fields to that of the first one
    %disp('One-time updating of tile info to first-tile info! (Fast)');
    obj.tiles(1) = set_info(obj.tiles(1));
    H = obj.tiles(1).H;
    W = obj.tiles(1).W;
    tiles = obj.tiles;
    parfor ix = 2:numel(obj.tiles)
        tiles(ix).H = H;
        tiles(ix).W = W;
    end
    obj.tiles = tiles;
    obj.update_tile_info_switch = 0;
    %disp('Done: Update tile info.');
end
