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
fac = 0.5;
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
thresh = 5;
indx1 = find(im1<thresh);r = rand(size(indx1));im1(indx1) = r * double(max(im1(:)));
indx2 = find(im2<thresh);r = rand(size(indx2));im2(indx2) = r * double(max(im2(:)));

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
 [T, movingReg] = register_image_pair(fixed, moving);
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


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [output Greg] = dftregistration(buf1ft,buf2ft,usfac)
% function [output Greg] = dftregistration(buf1ft,buf2ft,usfac);
% Efficient subpixel image registration by crosscorrelation. This code
% gives the same precision as the FFT upsampled cross correlation in a
% small fraction of the computation time and with reduced memory
% requirements. It obtains an initial estimate of the crosscorrelation peak
% by an FFT and then refines the shift estimation by upsampling the DFT
% only in a small neighborhood of that estimate by means of a
% matrix-multiply DFT. With this procedure all the image points are used to
% compute the upsampled crosscorrelation.
% Manuel Guizar - Dec 13, 2007

% Portions of this code were taken from code written by Ann M. Kowalczyk
% and James R. Fienup.
% J.R. Fienup and A.M. Kowalczyk, "Phase retrieval for a complex-valued
% object by using a low-resolution image," J. Opt. Soc. Am. A 7, 450-458
% (1990).

% Citation for this algorithm:
% Manuel Guizar-Sicairos, Samuel T. Thurman, and James R. Fienup,
% "Efficient subpixel image registration algorithms," Opt. Lett. 33,
% 156-158 (2008).

% Inputs
% buf1ft    Fourier transform of reference image,
%           DC in (1,1)   [DO NOT FFTSHIFT]
% buf2ft    Fourier transform of image to register,
%           DC in (1,1) [DO NOT FFTSHIFT]
% usfac     Upsampling factor (integer). Images will be registered to
%           within 1/usfac of a pixel. For example usfac = 20 means the
%           images will be registered within 1/20 of a pixel. (default = 1)

% Outputs
% output =  [error,diffphase,net_row_shift,net_col_shift]
% error     Translation invariant normalized RMS error between f and g
% diffphase     Global phase difference between the two images (should be
%               zero if images are non-negative).
% net_row_shift net_col_shift   Pixel shifts between images
% Greg      (Optional) Fourier transform of registered version of buf2ft,
%           the global phase difference is compensated for.

% Default usfac to 1
if exist('usfac')~=1, usfac=1; end

% Compute error for no pixel shift
if usfac == 0,
    CCmax = sum(sum(buf1ft.*conj(buf2ft)));
    rfzero = sum(abs(buf1ft(:)).^2);
    rgzero = sum(abs(buf2ft(:)).^2);
    error = 1.0 - CCmax.*conj(CCmax)/(rgzero*rfzero);
    error = sqrt(abs(error));
    diffphase=atan2(imag(CCmax),real(CCmax));
    output=[error,diffphase];
    
    % Whole-pixel shift - Compute crosscorrelation by an IFFT and locate the
    % peak
elseif usfac == 1,
    [m,n]=size(buf1ft);
    CC = ifft2(buf1ft.*conj(buf2ft));
    [max1,loc1] = max(CC);
    [max2,loc2] = max(max1);
    rloc=loc1(loc2);
    cloc=loc2;
    CCmax=CC(rloc,cloc);
    rfzero = sum(abs(buf1ft(:)).^2)/(m*n);
    rgzero = sum(abs(buf2ft(:)).^2)/(m*n);
    error = 1.0 - CCmax.*conj(CCmax)/(rgzero(1,1)*rfzero(1,1));
    error = sqrt(abs(error));
    diffphase=atan2(imag(CCmax),real(CCmax));
    md2 = fix(m/2);
    nd2 = fix(n/2);
    if rloc > md2
        row_shift = rloc - m - 1;
    else
        row_shift = rloc - 1;
    end
    
    if cloc > nd2
        col_shift = cloc - n - 1;
    else
        col_shift = cloc - 1;
    end
    output=[error,diffphase,row_shift,col_shift];
    
    % Partial-pixel shift
else
    
    % First upsample by a factor of 2 to obtain initial estimate
    % Embed Fourier data in a 2x larger array
    [m,n]=size(buf1ft);
    mlarge=m*2;
    nlarge=n*2;
    CC=zeros(mlarge,nlarge);
    CC(m+1-fix(m/2):m+1+fix((m-1)/2),n+1-fix(n/2):n+1+fix((n-1)/2)) = ...
        fftshift(buf1ft).*conj(fftshift(buf2ft));
    
    % Compute crosscorrelation and locate the peak
    CC = ifft2(ifftshift(CC)); % Calculate cross-correlation
    [max1,loc1] = max(CC);
    [max2,loc2] = max(max1);
    rloc=loc1(loc2);cloc=loc2;
    CCmax=CC(rloc,cloc);
    
    % Obtain shift in original pixel grid from the position of the
    % crosscorrelation peak
    [m,n] = size(CC); md2 = fix(m/2); nd2 = fix(n/2);
    if rloc > md2
        row_shift = rloc - m - 1;
    else
        row_shift = rloc - 1;
    end
    if cloc > nd2
        col_shift = cloc - n - 1;
    else
        col_shift = cloc - 1;
    end
    row_shift=row_shift/2;
    col_shift=col_shift/2;
    
    % If upsampling > 2, then refine estimate with matrix multiply DFT
    if usfac > 2,
        %%% DFT computation %%%
        % Initial shift estimate in upsampled grid
        row_shift = round(row_shift*usfac)/usfac;
        col_shift = round(col_shift*usfac)/usfac;
        dftshift = fix(ceil(usfac*1.5)/2); %% Center of output array at dftshift+1
        % Matrix multiply DFT around the current shift estimate
        CC = conj(dftups(buf2ft.*conj(buf1ft),ceil(usfac*1.5),ceil(usfac*1.5),usfac,...
            dftshift-row_shift*usfac,dftshift-col_shift*usfac))/(md2*nd2*usfac^2);
        % Locate maximum and map back to original pixel grid
        [max1,loc1] = max(CC);
        [max2,loc2] = max(max1);
        rloc = loc1(loc2); cloc = loc2;
        CCmax = CC(rloc,cloc);
        rg00 = dftups(buf1ft.*conj(buf1ft),1,1,usfac)/(md2*nd2*usfac^2);
        rf00 = dftups(buf2ft.*conj(buf2ft),1,1,usfac)/(md2*nd2*usfac^2);
        rloc = rloc - dftshift - 1;
        cloc = cloc - dftshift - 1;
        row_shift = row_shift + rloc/usfac;
        col_shift = col_shift + cloc/usfac;
        
        % If upsampling = 2, no additional pixel shift refinement
    else
        rg00 = sum(sum( buf1ft.*conj(buf1ft) ))/m/n;
        rf00 = sum(sum( buf2ft.*conj(buf2ft) ))/m/n;
    end
    error = 1.0 - CCmax.*conj(CCmax)/(rg00*rf00);
    error = sqrt(abs(error));
    diffphase=atan2(imag(CCmax),real(CCmax));
    % If its only one row or column the shift along that dimension has no
    % effect. We set to zero.
    if md2 == 1,
        row_shift = 0;
    end
    if nd2 == 1,
        col_shift = 0;
    end
    output=[error,diffphase,row_shift,col_shift];
end

% Compute registered version of buf2ft
if (nargout > 1)&&(usfac > 0),
    [nr,nc]=size(buf2ft);
    Nr = ifftshift([-fix(nr/2):ceil(nr/2)-1]);
    Nc = ifftshift([-fix(nc/2):ceil(nc/2)-1]);
    [Nc,Nr] = meshgrid(Nc,Nr);
    Greg = buf2ft.*exp(i*2*pi*(-row_shift*Nr/nr-col_shift*Nc/nc));
    Greg = Greg*exp(i*diffphase);
elseif (nargout > 1)&&(usfac == 0)
    Greg = buf2ft*exp(i*diffphase);
end
Greg = mat2gray(abs(real(ifft2(Greg))));
return

function out=dftups(in,nor,noc,usfac,roff,coff)
% function out=dftups(in,nor,noc,usfac,roff,coff);
% Upsampled DFT by matrix multiplies, can compute an upsampled DFT in just
% a small region.
% usfac         Upsampling factor (default usfac = 1)
% [nor,noc]     Number of pixels in the output upsampled DFT, in
%               units of upsampled pixels (default = size(in))
% roff, coff    Row and column offsets, allow to shift the output array to
%               a region of interest on the DFT (default = 0)
% Recieves DC in upper left corner, image center must be in (1,1)
% Manuel Guizar - Dec 13, 2007
% Modified from dftus, by J.R. Fienup 7/31/06

% This code is intended to provide the same result as if the following
% operations were performed
%   - Embed the array "in" in an array that is usfac times larger in each
%     dimension. ifftshift to bring the center of the image to (1,1).
%   - Take the FFT of the larger array
%   - Extract an [nor, noc] region of the result. Starting with the
%     [roff+1 coff+1] element.

% It achieves this result by computing the DFT in the output array without
% the need to zeropad. Much faster and memory efficient than the
% zero-padded FFT approach if [nor noc] are much smaller than [nr*usfac nc*usfac]

[nr,nc]=size(in);
% Set defaults
if exist('roff')~=1, roff=0; end
if exist('coff')~=1, coff=0; end
if exist('usfac')~=1, usfac=1; end
if exist('noc')~=1, noc=nc; end
if exist('nor')~=1, nor=nr; end
% Compute kernels and obtain DFT by matrix products
kernc=exp((-i*2*pi/(nc*usfac))*( ifftshift([0:nc-1]).' - floor(nc/2) )*( [0:noc-1] - coff ));
kernr=exp((-i*2*pi/(nr*usfac))*( [0:nor-1].' - roff )*( ifftshift([0:nr-1]) - floor(nr/2)  ));
out=kernr*in*kernc;
return
