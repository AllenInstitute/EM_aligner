function [obj, im, Wbox, imlabel] = show_tile_by_id(obj, tile_id, fz, scale, box_only,t, mask_info)
% Return and show image of tile 'tile_show' together with adjacent tiles accordign to current transformation matrix
% Usage: [obj im] = show_tile(obj, tile_show, font_size)
%       tile_show is an integer index into the obj.tiles array (not z, id,
%       col or row)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
tile_show = find([obj.tiles(:).id]==tile_id,1);
[obj, im, Wbox, imlabel] = show_tile(obj, tile_show, fz, scale, box_only,t, mask_info);
