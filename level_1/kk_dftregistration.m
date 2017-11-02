function [m1, m2, error_code, res, imt1] = kk_dftregistration(im1, im2)
% the function returns point-correspondences in m1 and m2
% input: im1 and im2 are same size: im1 and im2 are assumed to be roughly aligned
% output: point matches in m1 and m2, an error code, a list of residuals
% for fine alignment and the tissue image
% Error codes: 0 ---> no errors
%              1 ---> Failed at rough alignment
% Idea:
% [1] perform dftregistration on whole image to correct for translation and rotation
% [2] generate saliency point maps in im1 and im2 to determine generally where
% tissue is found. Use both SURF and HARRIS (or BRISK) to eliminate the
% mask edge points.
% [3] divide canvas into windows, and select only windows that coincide
% with large clusters of saliency points (from [1] above).
% [4] perform dftregistration for each window
% [5] generate point-correspondences from windows
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
m1 = [];
m2 = [];
res = [];
error_code = 0;
imt1 = [];
%% configuration
[imsz1, imsz2] = size(im1);

% rough alignment parameters
%max_shift = fac * imsz1;
max_residual = 0.70; % cutoff, any residual exceeding this leads to failure of initial rough alignment (error_code 1)

% tissue detection parameters
hsize = 50; % Gaussian low-pass filter size
sigma = 100;% Gaussian sigma
erode_dsize = 40;  % size of disc used for erosion

% windowing parameters
fac = 0.15; % larger equals larger block sizes. Typical values 0.05->0.15
blksz = ceil([size(im1,1)*fac size(im1,2)*fac]);%[250 250];   % window size

% filter point-matches
fac = 0.0014;  % larger values equal higher threshold and can lead to bad points being included typical: 0.0014
translation_threshold = fac * size(im1,1);%3.0; % radius of trust in x and y
quality_threshold = 0.35;
points_per_block = 5;



%% [0] generate white noise to eliminiate black (mask) borders
% thresh = 5;
% indx1 = find(im1<thresh);
% r = rand(size(indx1));
% im1(indx1) = r * double(max(im1(:)));
% indx2 = find(im2<thresh);
% r = rand(size(indx2));
% im2(indx2) = r * double(max(im2(:)));

%%%%%%%% sosi
% figure;imshowpair(im1,im2, 'montage');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% [1] Initial rigid registration
scale = 0.50;
fixed = imresize(im1,scale);
moving = imresize(im2,scale);
figure, imshowpair(fixed,moving,'montage');
%% %%% use cross correlation
tformEstimate = imregcorr(moving,fixed, 'Window', true);
disp(tformEstimate.T)
Rfixed = imref2d(size(fixed));
movingReg = imwarp(moving,tformEstimate,'OutputView',Rfixed);
figure, imshowpair(fixed,movingReg,'montage');
figure, imshowpair(fixed,movingReg,'falsecolor');


%% 
% % %%%% use SURF
% [T, movingReg] = register_image_pair(fixed, moving);
% % 
% % 
% % %%%%% sosi -----
% % % im1 is the fixed image and im2 is the moving image
% % [optimizer, metric] = imregconfig('multimodal');
% % 
% % 
% % %%%% use imregister
% % imout = imregister(moving, fixed, 'affine', optimizer, metric);
% % imshowpair(fixed, imout, 'montage');
% % tform = imregtform(moving, fixed, 'similarity', optimizer, metric);
% % 
% % imout = imwarp(moving,tform,'OutputView',imref2d(size(fixed)));
% % figure;imshowpair(fixed,imout, 'blend');figure;imshowpair(fixed,imout, 'montage');
% % 
% % 
% % % rescale the transform
% % tform.T([1 3 5 6]) = tform.T([1 3 5 6]) * 1/scale;
% % imout = imwarp(im2,tform,'OutputView',imref2d(size(im1)));
% % figure;imshowpair(im1,imout, 'blend');figure;imshowpair(im1,imout, 'montage');

[rough_shift movingReg] = dftregistration(fft2(fixed),fft2(moving),100); % imout takes im2(moving) to im1(fixed)
if rough_shift(1)>max_residual,
    error_code = 1;
    return;
end
%%%%%%%% sosi
% figure;imshowpair(fixed,movingReg, 'montage');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% [2] tissue-detection
imt1 = find_tissue(im1,indx1, hsize, sigma, erode_dsize);
%imt2 = find_tissue(im2,indx2, hsize, sigma, erode_dsize);

%%%%%%%% sosi
%figure;imshowpair(im1, imt1, 'montage');



%%%%%%%%%%%%%%% sosi ----  what would the solution be based on this
%%%%%%%%%%%%%%% rough_shift only?
% dx = [];
% dy = [];
% m1 = [];
% m2 = [];
% [c] = divide_into_blocks(imt1, blksz);
% for imix = 1:4:size(c,1)
%     dx = rough_shift(4) ;
%     dy = rough_shift(3) ;
%     x = c(imix,1) + (c(imix,2)-c(imix,1))/2;  % center of x coordinate
%     y = c(imix,3) + (c(imix,4)-c(imix,3))/2;  % center of y coordinate
%     m2(imix,:) =  [x y];
%     m1(imix,:) = [x+dx y+dy ];
% end
%
% %%%%%%%%% sosi
% figure; showMatchedFeatures(im1, im2, m1, m2, 'montage');
%%%%%%%%%%%%%

%%%%%% sosi
% disp(rough_shift);
% figure(3); imshowpair(im2, im1, 'blend');title('blend: original pair');
% figure(4); imshowpair(imout, im1, 'blend');title('blend: after initial dftregistration');
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% [3] Divide into windows and select only windows overlaping (roughly) with tissue

[c] = divide_into_blocks(imt1, blksz);
if isempty(c), warning('No tissue content found');return;end
%%%%%%%%%% sosi
% figure;imshow(imt1);hold on;
% for imix = 1:size(c,1)
%     rectangle('Position', [c(imix,1) c(imix,3) c(imix,2)-c(imix,1) c(imix,4)-c(imix,3)], ...
%         'EdgeColor','y', 'LineWidth', 3);
% end
%%%%%%%%%%%%%%%%%%%%%%%

%% [4] register every block separately
fs = [];
for imix = 1:size(c,1)
    cols = c(imix,1):c(imix,2);
    rows = c(imix,3):c(imix,4);
    blk1 = im1(rows, cols); %imcell{imix};   % original image blocks that are
    blk2 = imout(rows, cols);
    
    %%%%%% sosi
    %     figure;imshow((blk1));
    %     figure;imshow((blk2));
    %%%%%%%%%%%%%%
    
    [fs(imix,:), blkout] = dftregistration(fft2(blk1),fft2(blk2),100); % blk2(moving) to blk1(fixed)
    %[~, ~, ~, blkout] = register_image_pair(blk1,blk2);
    
    %%%%% sosi
%     str = num2str(fs);
%         if ~isempty(blkout)
%             imshow([ mat2gray([blk1;blk1]) mat2gray([blk2;blkout]) ]);%title(str);
%     
%             truesize(gcf, [800 800]);drawnow;
%             pause(5);
%         end
    %%%%%%%%%%%%%%%%%%%%%
end

%%%reduce to a high quality subset
indx = find(abs(fs(:,3))<translation_threshold & abs(fs(:,4))<translation_threshold & abs(fs(:,1))<quality_threshold);
c = c(indx,:);
fs = fs(indx,:);

%%%%%% sosi
% for imix = 1:size(c,1)
%     disp(imix);
%     cols = c(imix,1):c(imix,2);
%     rows = c(imix,3):c(imix,4);
%     blk1 = im1(rows, cols); %imcell{imix};   % original image blocks that are
%     blk2 = imout(rows, cols);
%     [fine_shift, blkout] = dftregistration(fft2(blk1),fft2(blk2),100);
%     str = num2str(fine_shift);
%     imshow([ mat2gray([blk1;blk1]) mat2gray([blk2;blkout]) ]);title(str);
%     truesize(gcf, [800 800]);drawnow;
%     pause(3);
% end
%%%%%%%%%%%%%%%%

%% [5] generate point-matches and point-match weights
dx = [];
dy = [];
m1 = [];
m2 = [];
res  = [];
counter = 1;
for imix = 1:size(c,1)
    dx = rough_shift(4) + fs(imix,3);
    dy = rough_shift(3) + fs(imix,4);
    
    x = c(imix,1) + (c(imix,2)-c(imix,1))/2;  % center of x coordinate
    y = c(imix,3) + (c(imix,4)-c(imix,3))/2;  % center of y coordinate
    m2(imix,:) =  [x y];
    m1(imix,:) = [x+dx y+dy ];
    res(imix) = fs(imix,1);
end


%%%%%%%%% sosi
% T = fitgeotrans([m12_1.Location],[m12_2.Location],'affine');
% B = imwarp(im1, T,'FillValues', maxIm, 'OutputView',  imref2d(size(im2)));
% figure; showMatchedFeatures(im1, im2, m1, m2, 'montage');
%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [c] = divide_into_blocks(imt, blksz)
% returns blocks of the original image, and the row/column each block
%%%%%%%%%%%%%%%%%%%%%%%%%%%
fac = 0.2; % large is harder
maxim = max(imt(:));
[rows, columns] = size(imt);
blockSizeR = blksz(1); % Rows in block.
blockSizeC = blksz(2); % Columns in block.
% Preallocate
%imcell = {};
c = [];
xsum = [];
counter = 1;
%Get each block and put it into imcell
sliceNumber = 1;
for row = 1 : blockSizeR : rows
    for col = 1 : blockSizeC : columns
        row1 = row;
        row2 = row1 + blockSizeR - 1;
        col1 = col;
        col2 = col1 + blockSizeC - 1;
        if row2>rows, row2 = rows;end
        if col2>columns, col2 = columns;end
        % Extract the block into an image.
        imtBlock = imt(row1:row2, col1:col2);
        xsum(counter) = sum(imtBlock(:))/numel(imtBlock(:)) * maxim;
        %disp(xsum(counter));
        %thresh(counter) = (numel(imtBlock) * maxim);
        if xsum(counter)>maxim*fac   % then we have enough tissue
            c(sliceNumber,:) = [col1 col2 row1 row2];%[(row2-row1)/2 (col2-col1)/2];
            sliceNumber = sliceNumber + 1;
        end
        counter = counter + 1;
    end
    
end
%%%%%%%%%%% sosi
%figure; hist(xsum(:));

