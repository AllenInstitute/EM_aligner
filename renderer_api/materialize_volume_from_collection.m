function I = materialize_volume_from_collection(rc, zstart, zfinish, scale, dir_out)
% generates a set of images for collection rc at scale "scale" outputting
% each section as a montage scape
% uses bounds of full stack
% Author: Khaled Khairy / Using Renderer API by Eric T. and Stephan Saalfeld
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[Wbox, bbox, url] = get_slab_bounds_renderer(rc); %
parfor ix = zstart:zfinish
    %disp(['materializing section: ' num2str(ix)]);
    try
        [im, v, url] = get_image_box_renderer(rc, ix, Wbox, scale, 'kk');
        fn = [dir_out '/kk_' rc.stack '_' num2str(ix) '.tif'];
        imwrite(im, fn);
        %I(:,:,ix) = im;
    catch err_generating_image
        kk_disp_err(err_generating_image);
    end
end



% scale_read = 0.25;      
I = [];
% for ix = zstart:zfinish
%     disp(['reading section: ' num2str(ix)]);
%     try
%         fn = [dir_out '/kk_' rc.stack '_' num2str(ix) '.tif'];
%         im = imread(fn);
%         I(:,:,ix) = mat2gray(imresize(im, scale_read));
%     catch err_generating_image
%         kk_disp_err(err_generating_image);
%     end
% end
