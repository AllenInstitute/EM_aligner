% Experiment: skeletonize orthogonal fibers using SIFT
clc
% configure source collection
rcsource.stack          = 'v12_align_tps';
rcsource.owner          ='flyTEM';
rcsource.project        = 'FAFB00';
rcsource.service_host   = '10.37.5.60:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;
% configure rendered stack
rendered_stack.pth = '/tier2/flyTEM/nobackup/rendered_boxes/FAFB00/v12_align_tps/2048x2048';
rendered_stack.dim = 2048;
rendered_stack.ext = 'jpg';
%% configure cutout
dir_temp_render = '/scratch/khairyk';
nz = 300;
zstart = 2899;
xo = 93953;
yo = 48459;
npoints = 32;
span = 6000;
x = [xo; (randi(span, npoints-1,1) + xo)];
y = [yo; (randi(span, npoints-1,1) + yo)];
w = 200;
h = 200;
scale = 1;
scale_level = 0;
dbg = 0;
sm = 2.0;
warning off;

im_cell1 = cell(numel(x),1);
sk_cell1 = cell(numel(x),1);
disp('With dgvf');
tic
parfor rr = 1:numel(x);
    %disp(rr);
    [sk_cell{rr}, im_cell1{rr}] = generate_skeleton(rcsource, rendered_stack, dir_temp_render,...
                                                   nz, zstart, x(rr), y(rr),...
                                                   w, h, scale, sm, 1, scale_level, dbg);
end
toc

im_cell2 = cell(numel(x),1);
sk_cell2 = cell(numel(x),1);
disp('Without dgvf');
tic
parfor rr = 1:numel(x);
    %disp(rr);
    [sk_cell{rr}, im_cell2{rr}] = generate_skeleton(rcsource, rendered_stack, dir_temp_render,...
                                                   nz, zstart, x(rr), y(rr), w, h, scale, sm, 0, scale_level, dbg);
end
toc
%% look at seed point progression
n = 1;
im = im_cell{n};
fig = figure(n);

for imix = 1:size(im,3)
    clf;imshow(im(:,:,imix));
    hold on;
    plot(w/2*scale, h/2 * scale, '*y'); % seed point should always be in the center
    title(num2str(imix));
    drawnow;
    F(:,:,imix) = getframe;
    pause(0.1);
end


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










































