function [obj, im, Wbox, imlabel, show_vec] = show_tile(obj, tile_show, fz, scale, box_only,t, stack)
% Return and show image of tile 'tile_show' together with adjacent tiles 
% i.e. the tile in context of neighbors, so that we can judge stitching
% Usage: [obj im] = show_tile(obj, tile_show, font_size)
%       tile_show is an integer index into the obj.tiles array (it is not z, id, col or row)
%
% Author: Khaled Khairy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imlabel = [];
if nargin<7, stack = obj.tiles(1).stack;end

if nargin<3, fz = 0;end
if nargin<4, scale = 0.5;end
if nargin<5, box_only = 0;end
if nargin<6, t = 1;end
if tile_show<=numel(obj.tiles) && tile_show>0
    obj = update_adjacency(obj);
    
    % get all connections and neighbors of tile_show
    [rows, cols] = ind2sub(size(obj.A), find(obj.A));
    neighbors = [[rows(cols==tile_show)]' [cols(rows==tile_show)]'];    % get neighbors of tiles_show
    show_vec = [tile_show(:)' neighbors(:)'];
    disp(show_vec);
    if numel(show_vec)>obj.tile_show_limit,
        warning('Too many tiles to show. Showing maximum only.');
        show_vec = show_vec(1:obj.tile_show_limit);
    end
    
    %%%% only include tiles that have state>=1
    delt = ones(numel(show_vec),1);
    for tix = 1:numel(show_vec)
        if obj.tiles(show_vec(tix)).state<1,
            delt(tix)=0;
        end
    end
    format shortG;
    disp([show_vec(:) delt(:)]);
    show_vec = show_vec(find(delt));
    %disp(['Box calculated for ' num2str(numel(show_vec)) ' tiles']);
    %disp(num2str(show_vec));
    if ~isempty(show_vec)
    L = Msection(obj.tiles(show_vec));
    %L = update_tile_info(L);
    L = update_XY(L);
    L = get_bounding_box(L);
    
    else
        error('no tiles to show');
    end
    
    %     view(L, 0.5, 'renderer');
    %%
    
        Wbox = [L.box(1) L.box(3) L.box(2)-L.box(1) L.box(4)-L.box(3)];
    %disp(num2str(Wbox));
    if box_only
        im = [];
        return;
    else
%         t = obj.tiles(tile_show);
%         rc.baseURL = t.server;
%         rc.owner   = t.owner;
%         rc.project = t.project;
%         rc.stack   = t.stack;
%         im = get_image_box_renderer(rc, t.z, Wbox, scale, t.dir_temp_render, t.renderer_id);
%         

        
        %%% use Renderer client for getting individual tiles, and let matlab assemble them
        [im, Wbox, imlabel] = render_poly_06(L.tiles, scale, Wbox, 0, stack);
%         
        warning off;imshow(im);warning on;
        %     %% optionally show the text labels overlaid onto the tile images
        if fz
            for ix = 1:numel(show_vec)
                str = sprintf('%d\nRow: %d\nCol: %d\nId: %d',...
                    show_vec(ix), obj.tiles(show_vec(ix)).row, obj.tiles(show_vec(ix)).col, obj.tiles(show_vec(ix)).id);
                if obj.tiles(show_vec(ix)).state == 1, c = 'y';
                else c = 'r';end
                text(L.X((ix)),L.Y((ix)),...
                    str, 'BackgroundColor', c, 'FontSize', fz);
            end
        end
    end
    
else
    disp('Tile number out of range');
end
