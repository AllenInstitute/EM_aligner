function [obj, h] = show_tile_state(obj, option, style, fz)
% show map of all tiles within the layer
% Usage: obj = show_map(obj, option, style, font_size)
%           option (default: 'all')  'all', 'registered only', 'marked for removal'
%           style (default: 'filled')
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% configure
default_option = 'all';
default_style  = 'filled';

% handle input
if nargin<2, 
    option = default_option; 
    style = default_style;
    fz = 0;
end
if nargin<3, 
    if isempty(option), option = default_option;end
    style = default_style;
    fz = 0;
end
if nargin==3, 
    if isempty(option), option = default_option;end
    if isempty(style), style = default_style;end
    fz = 0;
end
if nargin==4, 
    if isempty(option), option = default_option;end
    if isempty(style), style = default_style;end
    if isempty(style), fz = 0;end
end

% specify color for each tile based on its state and plot a rectangle
% representing the tile
obj = update_tile_info(obj);		% we don't need adjacency information in this file
for ix = 1:numel(obj.tiles)
    if strcmp(style,'filled')
        if obj.tiles(ix).state, c = [0 0 1];        % default is blue
        else c = [1 0 0];
        end
    else
        c = [1 1 1];
    end
    if strcmp(option, 'all') || strcmp(option,'registered only')
        if obj.tiles(ix).state == 1,
            rectangle('Position', ...
                [obj.tiles(ix).tform.T(3,1) obj.tiles(ix).tform.T(3,2) ...
                obj.tiles(ix).W/obj.map_display_fac obj.tiles(ix).H/obj.map_display_fac], ...
                'Curvature', [0.8, 0.4], 'LineWidth', 2, 'LineStyle', '--', ...
                'FaceColor', c);
        end
    end
    if strcmp(option, 'all') || strcmp(option,'marked for removal')
        if (obj.tiles(ix).state) == 0,
            x = obj.tiles(ix).tform.T(3,1);
            y = obj.tiles(ix).tform.T(3,2);
           
            rectangle('Position', ...
                [ x y ...
                obj.tiles(ix).W/obj.map_display_fac obj.tiles(ix).H/obj.map_display_fac], ...
                'Curvature', [0.8, 0.4], 'LineWidth', 2, 'LineStyle', '--', ...
                'FaceColor', c);
        end
    end
end


%%% add text
if fz
    for ix = 1:numel(obj.tiles)
        X = obj.tiles(ix).tform.T(3,1) + obj.tiles(ix).W/2;
        Y = obj.tiles(ix).tform.T(3,2) + obj.tiles(ix).H/2;
        %disp([X Y]);
        text(X,Y, num2str(ix), 'BackgroundColor', 'y', 'FontSize', 18);
    end
end
axis tight;
daspect([1 1 1]);
h = gcf;


