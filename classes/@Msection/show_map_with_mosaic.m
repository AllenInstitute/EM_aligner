function [L, h, rh] = show_map_with_mosaic(L, scale, force, disp_option, fz)
% show map of all tiles within the layer
% Usage: obj = show_map(obj, option, style, font_size)
%           option (default: 'all')  'all', 'registered only', 'marked for removal'
%           style (default: 'filled')
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



if nargin<2, scale = 0.01;end
if nargin<3, force = 0;end
if nargin<4, disp_option = 'transparent';end;
if nargin<5, fz = 0;end

L = get_bounding_box(L);
if isempty(L.mosaic) || force
    disp('Generating mosaic image');
    L = mosaic_gen(L, scale);
end

if ~isempty((L.mosaic))
    
    im = L.mosaic;
    RI = imref2d(size(im));
    RI.XWorldLimits = [L.box(1) L.box(2)];
    RI.YWorldLimits = [L.box(3) L.box(4)];
    imh = imshow(im,RI);
    alpha_data = ones(size(im))*0.05;
    % set the y-axis back to normal.
    set(gca,'ydir','normal');
    hold on;
end

if strcmp(disp_option,'transparent')
     [L, h, rh] = show_map(L, 'registered only', disp_option, fz);
else
    [L, h, rh] = show_map(L);
end
hold off;

