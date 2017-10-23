function mask = get_mask_image(obj)
% returns the mask image for the tile object obj
% returns empty in case of error
try
    url = sprintf('%s/owner/%s/project/%s/stack/%s/tile/%s/',...
        obj.server, obj.owner, obj.project, obj.stack, obj.renderer_id);
    
    options = weboptions('Timeout', 60);
    tile_info = webread(url, options);
    
    mask = imread(tile_info.mipmapLevels.x0.maskUrl(6:end));
    
catch err_mask_read
    mask = [];
end