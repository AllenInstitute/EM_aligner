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
rendered_stack.type = 'disk';
rendered_stack.pth = '/tier2/flyTEM/nobackup/rendered_boxes/FAFB00/v12_align_tps/2048x2048';
rendered_stack.dim = 2048;
rendered_stack.ext = 'jpg';


%% configure cutout
dir_temp_render = '/scratch/khairyk';
nz = 1000;
zstart = 2946;
x = 115774;
y = 60136;

w = 400;
h = 400;
scale = 1;
scale_level = 3;
debug = 1;
sm = 2.0;  % smoothness factor for imdemons
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
% n = 1;
% im = im_cell{n};
% fig = figure(n);
% 
% for imix = 1:size(im,3)
%     clf;imshow(im(:,:,imix));
%     hold on;
%     plot(w/2*scale, h/2 * scale, '*y'); % seed point should always be in the center
%     title(num2str(imix));
%     drawnow;
%     F(:,:,imix) = getframe;
%     pause(0.1);
% end


% %%
% fnout = '/groups/flyTEM/home/khairyk/EM_aligner/test_data/video/videoframes';
% numberOfFrames = size(im,3);
% for frame = 1 : numberOfFrames
%     fn = [fnout '/image_' num2str(frame) '.jpg'];
%     image = rgb2gray(F(:,:,frame).cdata);
%     imwrite(image(1:w, 1:h), fn);
% end
% % 
% 
% 
% 










































