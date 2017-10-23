% compare tps and align
nfirst = 1000;
nlast  = 1200;
% configure align collection
rctarget_align.stack          = ['EXP_dmesh_fine_P1_1000_1200'];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;



%% render 

Wbox = [107460-1000 59070-1000 2000 2000];
scale = 1.0;
% [im, v, url] = get_image_box_renderer(rctarget_align, 1000, Wbox, scale);
% imshow(im);


im1 = zeros(Wbox(3)*scale, Wbox(4) * scale, numel([nfirst:nlast]));
vec = [nfirst:nlast];
vec = vec(:);
parfor ix = 1:numel(vec)
    disp(ix);
%     try
        im1(:,:, ix)= get_image_box_renderer(rctarget_align, vec(ix), Wbox, scale);
           
%     catch err
%         disp(['Err: ' num2str(ix)']);
%     end
end
im1 = mat2gray(im1);
%implay(im1);



%%
% compare tps and align
% configure align collection
rctarget_align.stack          = ['EXP_dmesh_tps_P1_1000_1200'];
rctarget_align.owner          = 'flyTEM';
rctarget_align.project        = 'test';
rctarget_align.service_host   = '10.37.5.60:8080';
rctarget_align.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rctarget_align.verbose        = 1;



%% render 

Wbox = [102559-1000 54038-1000 2000 2000];
scale = 1.0;
% [im, v, url] = get_image_box_renderer(rctarget_align, 1000, Wbox, scale);
%  imshow(im);


im2 = zeros(Wbox(3)*scale, Wbox(4) * scale, numel([nfirst:nlast]));
vec = [nfirst:nlast];
vec = vec(:);
parfor ix = 1:numel(vec)
    disp(ix);
%     try
        im2(:,:, ix)= get_image_box_renderer(rctarget_align, vec(ix), Wbox, scale);
           
%     catch err
%         disp(['Err: ' num2str(ix)']);
%     end
end
im2 = mat2gray(im2);
%implay(im2);



