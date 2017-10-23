function [I, Io] = get_yz_image_renderer(rc, x, y, dx, height, scale, zstart, zfinish, res)
%% Generate an xz-slice through an existing Renderer collection
% specify x and y coordinates, extent of box and range of z
% Input:
%* rc: a renderer collection struct
%* dx = 5;
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

Wbox = [x y dx height];
zrange = zstart:zfinish;
I = zeros(floor(dx * scale), floor(height * scale), numel(zrange));



% for ix = 1:numel(zrange)
%     disp(ix);
%    [im, v, url, resp_str] = get_image_box_renderer(rc, zrange(ix), Wbox, scale, 'kk');
%    I(:,:,ix) = im';
% end


parfor_progress(numel(zrange));
parfor ix = 1:numel(zrange)
    %disp(ix);
   [im, v, url, resp_str] = get_image_box_renderer(rc, zrange(ix), Wbox, scale, 'kk');
   I(:,:,ix) = im';
   parfor_progress;
end
parfor_progress(0);



Io = I;
I = mat2gray(I);
I = sum(I,1)/dx;
I = squeeze(I);
%I = imresize(I,[height numel(zrange)*(zres/yres)]);
warning('off', 'Images:initSize:adjustingMag');I = imadjust(I');
%imshow(mat2gray(I));

%daspect([1 1/50 1]);