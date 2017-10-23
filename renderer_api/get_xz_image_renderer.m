function [I, Io] = get_xz_image_renderer(rc, x, y, width, dy, scale, zstart, zfinish, res)
%% Generate an xz-slice through an existing Renderer collection
% specify x and y coordinates, extent of box and range of z
% Input:
%* rc: a renderer collection struct
%* dy = 5;
%* x = 21554;
%* y = 23864;
%* width = 1000;
%* scale = 0.5;
%* res = [4 4 50]; % voxel resolution in nm
% Author: Khaled Khairy. Janelia Research Campus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



xres = res(1);
yres = res(2);
zres = res(3);

Wbox = [x y width dy];
zrange = zstart:zfinish;
I = zeros(floor(width * scale), floor(dy * scale), numel(zrange));
parfor_progress(numel(zrange));
parfor ix = 1:numel(zrange)
    try
   % disp(ix);
   [im, v, url] = get_image_box_renderer(rc, zrange(ix), Wbox, scale, 'kk');
   I(:,:,ix) = im';
    catch err_image_request
        kk_disp_err(err_image_request);
    end
   parfor_progress;
end
parfor_progress(0);
Io = I;
I = mat2gray(I);
I = sum(I,2)/dy;
I = squeeze(I);
%I = imresize(I,[width numel(zrange)*(zres/xres)]);
warning('off', 'Images:initSize:adjustingMag');I = imadjust(I');
%imshow(mat2gray(I));

%daspect([1 1/50 1]);