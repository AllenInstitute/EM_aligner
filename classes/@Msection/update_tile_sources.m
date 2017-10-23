function obj = update_tile_sources(obj, rc)
% updates information source (renderer database) for the tile
% example fields of rc:
% rc.stack = 'v7_acquire_LC';
% rc.owner='flyTEM';
% rc.project='FAFB00';
% rc.baseURL='http://tem-services.int.janelia.org:8080/render-ws/v1';
% L = update_tile_sources(L, rc);
%%%%%%%%%%%%%%%%%%%%%


tiles = obj.tiles;
parfor tix = 1:numel(tiles)
    tiles(tix).owner        = rc.owner;
    tiles(tix).project      = rc.project;
    tiles(tix).stack        = rc.stack;
    tiles(tix).server       = rc.baseURL;
end
obj.tiles = tiles;