%% experiment with intensity correction
rco.stack          = 'four_tile_acquire';
rco.owner          ='flyTEM';
rco.project        = 'test_warp_field';
rco.service_host   = '10.40.3.162:8080';
rco.baseURL        = ['http://' rco.service_host '/render-ws/v1'];
rco.verbose        = 0;

rc.stack          = 'four_tile_montage';
rc.owner          ='flyTEM';
rc.project        = 'test_warp_field';
rc.service_host   = '10.40.3.162:8080';
rc.baseURL        = ['http://' rc.service_host '/render-ws/v1'];
rc.verbose        = 0;

clear pm;
ix = 1;
pm(ix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(ix).owner = 'flyTEM';
pm(ix).match_collection = 'FAFB_pm_7';%'v12_dmesh';% %'FAFB_pm_4'; % %'v12_dmesh';%'v12_dmesh';%'v12_dmesh';%

dir_scratch = '/scratch/khairyk/';

%% configure point match fetching
opts.nbrs = 2;
opts.min_points = 3;
opts.max_points = inf;
opts.filter_point_matches = 1;
% configure point-match filter
opts.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
opts.pmopts.MaximumRandomSamples = 5000;
opts.pmopts.DesiredConfidence = 99.9;
opts.pmopts.PixelDistanceThreshold = 1;

z = 1;
Lo = get_section_point_matches(rco, z, dir_scratch, opts, pm);
L  = get_section_point_matches(rc, z, dir_scratch, opts, pm);


%% generate images from Lwo and calculate gray-scale ranges
im =  get_image(Lo.tiles(1));
IMo = zeros(size(im,1), size(im,2), numel(Lo.tiles));
parfor ix = 1:numel(Lo.tiles)
    IMo(:,:,ix) = get_image(Lo.tiles(ix));
end
mn = min(IMo(:));
mx = max(IMo(:));
IMo = mat2gray(IMo);

%% sosi
% figure;showMatchedFeatures(IMo(:,:,1), IMo(:,:,2),Lo.pm.M{2,1}, Lo.pm.M{2,2}, 'montage');
%% obtain gray values at generated point-match locations (after scaling-gray values)
range = [mn mx];
[Logs, GS] = get_gray_values(Lo, range);
%% solve: generates solution vector xsol


experiment_intensity_correction_linear_system_gen;




%% Render transformed Lo
[Wbox, bbox, url] = get_section_bounds_renderer(rc, z);
sb1 = Wbox(4)+1;
sb2 = Wbox(3)+1;
IM = {};
for ix = 1:numel(Logs.tiles)
    I = zeros( sb1, sb2);
    im = get_image(Logs.tiles(ix));
%     indx_zeros = im<0.0001;
    im = imwarp(im, L.tiles(ix).tform);
    im = mat2gray(im, [mn mx]);
    
    %% apply background correction
    y = [1:size(im,1)]';
    imy = y(:,ones(1,size(im,2)));
    x = [1:size(im,2)]';
    imx = [x(:,ones(1,size(im,1)))]';
    vec = xsol((ix-1)*tdim+1:(ix-1)*tdim+tdim);
    if tdim == 3
            imb = vec(1) + vec(2).*imx + vec(3).*imy ;
    end
    if tdim ==6
    imb = vec(1) + vec(2).*imx + vec(3).*imy + ...
         vec(4) .* imx.*imx + vec(5).*imx.*imy + vec(6).*imy.*imy;
    end
    
    im = imb;%imsubtract(im,imb);
    %im(indx_zeros) = 0;
    %%%%
    
    r1 = L.tiles(ix).minX-Wbox(2)+1;
    r2 = r1+size(im,2)+1;%L.tiles(ix).minX + L.tiles(ix).maxX-Wbox(1);
    c1 = L.tiles(ix).minY-Wbox(1)+1;
    c2 = c1 + size(im,1)+1;%L.tiles(ix).minY + L.tiles(ix).maxY-Wbox(2);
    I(c1+1:c2-1,r1+1:r2-1) = im;
    I = I(1:sb1, 1:sb2);
    IM{ix} = I;
end

I = zeros(sb1, sb2);
for ix = 1:numel(IM)
    im = IM{ix}; 
    indx = im>0.0;
   I(indx) = im(indx);
end
figure;imshow((I));

%%
%% Render L ---> reference
[Wbox, bbox, url] = get_section_bounds_renderer(rc, z);
sb1 = Wbox(4)+1;
sb2 = Wbox(3)+1;
IM = {};
parfor ix = 1:numel(L.tiles)
    I = zeros( sb1, sb2);
    im = get_image(L.tiles(ix));
    r1 = L.tiles(ix).minX-Wbox(2)+1;
    r2 = r1+size(im,2)+1;%L.tiles(ix).minX + L.tiles(ix).maxX-Wbox(1);
    c1 = L.tiles(ix).minY-Wbox(1)+1;
    c2 = c1 + size(im,1)+1;%L.tiles(ix).minY + L.tiles(ix).maxY-Wbox(2);
    I(c1+1:c2-1,r1+1:r2-1) = mat2gray(im);
    I = I(1:sb1, 1:sb2);
    IM{ix} = I;
    
end

Ir = zeros(sb1, sb2);
for ix = 1:numel(IM)
    im = IM{ix}; 
    indx = im>0.0;
   Ir(indx) = im(indx);
end
figure(2);clf;imshow(Ir);

% 
% 
% 
% 
% 



