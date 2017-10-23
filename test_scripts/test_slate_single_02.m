% Experiment: skeletonize orthogonal fibers 
clc
% configure source collection
rcsource.stack          = 'v12_align_tps';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure rendered stack
rendered_stack.type = 'bock';
rendered_stack.pth = 'https://neuropil.janelia.org/tracing/tiles/special/fafb_v12_align_tps_jpg85/';
rendered_stack.dim = 1024;
rendered_stack.ext = 'jpg';

%% configure cutout
dir_temp_render = '/scratch/khairyk';
nz = 200;
zstart = 2946;
% x = 115774;
% y = 60136;

x = 93953;
y = 48459;

w = 200;
h = 200;
scale = 1;
scale_level = 0;
debug = 1;
sm = 1.0;  % smoothness factor for imdemons
warning off;

im_cell = cell(numel(x),1);
sk_cell = cell(numel(x),1);
disp('With dgvf');
tic
rr = 1;
[sk_cell{rr}, im_cell{rr}] = generate_skeleton(rcsource, rendered_stack, dir_temp_render,...
                                                   nz, zstart, x(rr), y(rr), ...
                                                   w, h, scale, sm, 1, scale_level, debug);
toc


%% look at seed point progression
n = 1;
im = im_cell{n};
fig = figure(n);

for imix = 1:size(im,3)
    clf;imshow(im(:,:,imix));
    hold on;
    plot(w/2*scale, h/2 * scale, 'ob'); % seed point should always be in the center
    title(num2str(imix));
    drawnow;
    F(:,:,imix) = getframe;
    pause(0.2);
end


% %%
fnout = '/groups/flyTEM/home/khairyk/EM_aligner/test_data/video/videoframes';
numberOfFrames = size(im,3);
for frame = 1 : numberOfFrames
    fn = [fnout '/image_' num2str(frame) '.jpg'];
    image = rgb2gray(F(:,:,frame).cdata);
    imwrite(image(1:w, 1:h), fn);
end
% % 
% 
% 
% 










































