function L = mosaic_gen(L, scale)
% generate a montage scape image and store it in the "mosaic" field of L

if nargin<2, scale = 0.05;end

L = update_tile_info(L);
L = get_bounding_box(L);
Wbox = [L.box(1) L.box(3) L.box(2)-L.box(1) L.box(4)-L.box(3)];

L.mosaic = render_poly_06(L.tiles, 0.05, Wbox, 0, L.tiles(1).stack);

% 
% if nargin<2, scale = 0.02;cutoff = 0;end
% if nargin<3, cutoff = 0;end
% disp('Mosaic_gen: Using box:');disp(num2str(Wbox));
%L.mosaic = render_poly_04(L.tiles(:), scale, Wbox, 0,L.tiles(1).stack);