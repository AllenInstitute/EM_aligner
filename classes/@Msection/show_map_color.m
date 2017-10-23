function [obj, h, rh, A, minconf, maxconf] = show_map_color(obj, parm,conf,  minconf, maxconf)
% show map of all tiles within the layer
% Usage: obj = show_map(obj, option, style, font_size)
%           option (default: 'all')  'all', 'registered only', 'marked for removal'
%           style (default: 'filled')
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%system('export LIBGL_ALWAYS_INDIRECT=y');       % make sure matlab is happy with open gl
set(gcf, 'Renderer','openGL');
% set(gcf, 'Renderer','painters');
rh = [];
A = [];
% configure
default_option ='registered only';% 'all';
default_style  = 'filled';
dc = [0 0 1;1 0 0;0 1 0];
%dc = [0.5 0.5 0.5;1 1 1;0 1 0];
fa = 0.0;
% method = 'rectangles'; % 'patches'  'transformed patches'
%method = 'patches';
method = 'transformed patches';

% handle input

option = default_option;
style = default_style;
fz = 0;

% specify color for each tile based on its state and plot a rectangle
% representing the tile
obj = update_tile_info(obj);		% we don't need adjacency information in this file
%obj = update_adjacency(obj);
%% determine the edge tiles
etix = get_edge_tiles(obj);
map = colormap('jet');

if nargin<3 || isempty(minconf)
maxconf = max(conf);
minconf = min(conf);
end


conf = ceil(mat2gray(conf, [minconf maxconf])*size(map,1));
conf(conf==0) = 1;
%conf = [conf(:) conf(:) conf(:)];


for ix = 1:numel(obj.tiles)
    if strcmp(style,'filled')
        if obj.tiles(ix).state ==1, c = dc(1,:);%[0.5 0.5 1];        % default color
        elseif obj.tiles(ix).state==0, c = dc(2,:);%[1 0 0];
        elseif obj.tiles(ix).state==-1, c = dc(3,:);
        end
    else
        c = [1 1 1];
    end
    if strcmp(option, 'all') || strcmp(option,'registered only')
        if obj.tiles(ix).state == 1,
            if strcmp(class(obj.tiles(ix).tform), 'affine2d')
                x = obj.tiles(ix).tform.T(3,1);
                y = obj.tiles(ix).tform.T(3,2);
            else
                x = 0;
                y = 0;
            end
            
            if strcmp(method, 'rectangles')
                if strcmp(class(obj.tiles(ix).tform), 'affine2d')
                    trh = rectangle('Position', ...
                        [obj.tiles(ix).tform.T(3,1) obj.tiles(ix).tform.T(3,2) ...
                        obj.tiles(ix).W/obj.map_display_fac obj.tiles(ix).H/obj.map_display_fac], ...
                        'Curvature', [0.8, 0.4], 'FaceColor', c);
                    %                     'Curvature', [0.8, 0.4], 'LineWidth', .1, 'LineStyle', '-', 'FaceColor', c);
                    %                     'EdgeColor', 'g','FaceColor', c);
                    rh = [rh trh];
                end
            elseif strcmp(method, 'patches')
                if strcmp(class(obj.tiles(ix).tform), 'affine2d')
                    Px = [x; x + obj.tiles(ix).W/obj.map_display_fac; x + obj.tiles(ix).W/obj.map_display_fac; x];
                    Py = [y; y; y + obj.tiles(ix).H/obj.map_display_fac; y+obj.tiles(ix).H/obj.map_display_fac];
                    patch( Px, Py, c, 'FaceAlpha', fa);
                else
                    error('not implemented for polynomials yet');
                end
            elseif strcmp(method,'transformed patches')
                x = 0;
                y = 0;
                Px = [x; x + obj.tiles(ix).W/obj.map_display_fac; x + obj.tiles(ix).W/obj.map_display_fac; x];
                Py = [y; y; y + obj.tiles(ix).H/obj.map_display_fac; y+obj.tiles(ix).H/obj.map_display_fac];
                %P = [Px(:) Py(:)];
                %%% transform the points and then plot the patch
                if strcmp(class(obj.tiles(ix).tform), 'affine2d')
                    P = [Px(:) Py(:) [1 1 1 1]']*obj.tiles(ix).tform.T;
                else
                    P = transformPointsInverse(obj.tiles(ix).tform,[Px Py]);
                end
                %T(3) = 0;T(6:8) = 0;T(9) = 1;
                %tf = maketform('affine', T);
                %P = tformfwd(tf,[Px(:) Py(:)]);
                
                % check polygon area
                A(ix) = polyarea(P(:,1), P(:,2));
                if strcmp(style,'transparent')
                    patch( P(:,1), P(:,2),c,  'EdgeColor', 'w', 'FaceColor', 'none');
                elseif strcmp(style, 'filled')
                    if etix(ix)
                        %patch( P(:,1), P(:,2),c,  'EdgeColor', 'k', 'FaceColor', 'g', 'FaceAlpha', 0.1);
                        patch( P(:,1), P(:,2),c,  'EdgeColor', 'k' , 'FaceColor', map(conf(ix),:), 'Facealpha', 0.8);
                        %                     else
                        %                         patch( P(:,1), P(:,2),c,  'EdgeColor', 'k', 'FaceColor', 'b');
                        
                    else
                        %patch( P(:,1), P(:,2),c,  'EdgeColor', 'k' , 'FaceColor', 'b', 'Facealpha', 0.1);
                        patch( P(:,1), P(:,2),c,  'EdgeColor', 'k' , 'FaceColor', map(conf(ix),:), 'Facealpha', 0.8);
                    end
                end
            end
            
        end
    end
    if strcmp(option, 'all') || strcmp(option,'marked for removal')
        if (obj.tiles(ix).state)<1,
            x = obj.tiles(ix).tform.T(3,1);
            y = obj.tiles(ix).tform.T(3,2);
            
            if strcmp(method, 'rectangles')
                trh = rectangle('Position', ...
                    [obj.tiles(ix).tform.T(3,1) obj.tiles(ix).tform.T(3,2) ...
                    obj.tiles(ix).W/obj.map_display_fac obj.tiles(ix).H/obj.map_display_fac], ...
                    'Curvature', [0.8, 0.4], 'LineWidth', 0.1, 'LineStyle', '-','FaceColor', c);
                %                     'EdgeColor', 'g','FaceColor', c);
                rh = [rh trh];
            elseif strcmp(method, 'patches')
                
                Px = [x; x + obj.tiles(ix).W/obj.map_display_fac; x + obj.tiles(ix).W/obj.map_display_fac; x];
                Py = [y; y; y + obj.tiles(ix).H/obj.map_display_fac; y+obj.tiles(ix).H/obj.map_display_fac];
                patch( Px, Py, c, 'FaceColor', fa);
                
            elseif strcmp(method,'transformed patches')
                
                Px = [x; x + obj.tiles(ix).W/obj.map_display_fac; x + obj.tiles(ix).W/obj.map_display_fac; x];
                Py = [y; y; y + obj.tiles(ix).H/obj.map_display_fac; y+obj.tiles(ix).H/obj.map_display_fac];
                P = [Px(:) Py(:)];
                %%% transform the points and then plot the patch
                %                 T = obj.tiles(ix).tform.T;
                %                 T(3) = 0;T(6:8) = 0;T(9) = 1;
                %                 tf = maketform('affine', T);
                %                 P = tformfwd(tf,[Px(:) Py(:)]);
                
                %%% transform the points and then plot the patch
                if strcmp(class(obj.tiles(ix).tform), 'affine2d')
                    P = [Px(:) Py(:) [1 1 1 1]']*obj.tiles(ix).tform.T;
                else
                    P = transformPointsInverse(obj.tiles(ix).tform,[Px Py]);
                end
                
                if strcmp(style,'transparent')
                    patch( P(:,1), P(:,2),c,  'EdgeColor', 'w', 'FaceColor', 'none');
                elseif strcmp(style, 'filled')
                    patch( P(:,1), P(:,2),c,  'EdgeColor', 'k', 'FaceColor', 'b');
                else
                    patch( P(:,1), P(:,2),c,  'EdgeColor', c , 'FaceColor', 'none');
                end
            end
        end
    end
end


% %%%
% if fz
%     [obj] = update_XY(obj);
%     for ix = 1:numel(obj.tiles)
%         %         X = obj.tiles(ix).tform.T(3,1) + obj.tiles(ix).W/2;
%         %         Y = obj.tiles(ix).tform.T(3,2) + obj.tiles(ix).H/2;
%         %disp([X Y]);
%         text(obj.X,obj.Y, num2str(ix), 'BackgroundColor', 'y', 'FontSize', fz);
%     end
% end
daspect([1 1 1]);
axis ij;
% view(90,90);
%view(-90,90);
 caxis([minconf maxconf]);
 colorbar;
h = gcf;
