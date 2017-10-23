function obj = show_map_tile(obj, tile_show, fz)
% show cartoon of input tile and its adjacent neighbors
% Usage: obj = show_map_tile(obj, tile_show, font_size)
%       tile_show is the index into obj.tiles array (not z, not tile id, not col or row) of the
%       tile to show
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin <3, fz = 0;disp('--------To display text, specify font size. Example: >show_map_tile(obj, tile_number, font_size;---------');end
obj = update_adjacency(obj);
[rows cols] = ind2sub(size(obj.A), find(obj.A));        % get all connections
neighbors = [[rows(cols==tile_show)]' [cols(rows==tile_show)]'];    % get neighbors of tiles_show
show_vec = [tile_show(:)' neighbors(:)'];
disp(show_vec);
for ix = 1:numel(obj.tiles(show_vec))
    if obj.tiles(show_vec(ix)).state, c = [0 0 1];        % default is blue
        else c = [1 0 0];
        end
    rectangle('Position', ...
        [obj.tiles(show_vec(ix)).tform.T(3,1) obj.tiles(show_vec(ix)).tform.T(3,2) ...
        obj.tiles(show_vec(ix)).W/obj.map_display_fac obj.tiles(show_vec(ix)).H/obj.map_display_fac], ...
        'Curvature', [0.8, 0.4], 'LineWidth', 2, 'LineStyle', '--', ...
        'FaceColor', c);
end
if fz
    for ix = 1:numel(obj.tiles(show_vec))
        X = obj.tiles(show_vec(ix)).tform.T(3,1) + obj.tiles(show_vec(ix)).W/2;
        Y = obj.tiles(show_vec(ix)).tform.T(3,2) + obj.tiles(show_vec(ix)).H/2;
        %disp([X Y]);
        text(X,Y, num2str(show_vec(ix)), 'BackgroundColor', 'y', 'FontSize', fz);
    end
end
daspect([1 1 1]);
axis ij;
