function [tform, show_pair_image, varargout] = ...
    register_image_pair_intensity_based(...
    im1, im2, npoints_per_pair, flag, method, pyramid_levels)
%% register two images
if nargin<5, method = 'all';end
if nargin<6, pyramid_levels = 5; end

%% step 0: pad images to be same size
pad_x = 0;
pad_y = 0;
%disp([size(im1) size(im2)]);
if size(im1,1)<size(im2,1)
    dsize = size(im2,1)-size(im1,1);
    pad_x = floor(dsize/2);
    im1 = padarray(im1, [pad_x 0]);
    if mod(dsize,2)~=0
        im1 = padarray(im1, [1 0], 'post');
        pad_x = pad_x + 1;
    end
end
    
if size(im1,1)>size(im2,1)
    dsize = size(im1,1)-size(im2,1);
    pad_x = floor(dsize/2);
    im2 = padarray(im2, [pad_x 0]);
    if mod(dsize,2)~=0
        im2 = padarray(im2, [1 0], 'post');
        pad_x = pad_x + 1;
    end
    pad_x = -pad_x;
end
    
if size(im1,2)<size(im2,2)
    dsize = size(im2,2)-size(im1,2);
    pad_y = floor(dsize/2);
    im1 = padarray(im1, [0 pad_y]);
    if mod(dsize,2)~=0
        im1 = padarray(im1, [0 1], 'post');
        pad_y = pad_y + 1;
    end
end
    
if size(im1,2)>size(im2,2)
    dsize = size(im1,2)-size(im2,2);
    pad_y = floor(dsize/2);
    im2 = padarray(im2, [0 pad_y]);
    if mod(dsize,2)~=0
        im2 = padarray(im2, [0 1], 'post');
        pad_y = pad_y + 1;
    end
    pad_y = -pad_y;

end


%% sosi:
%  whos im1 im2;

%% step 1: get them close using dft
%if pad_x||pad_y
%    disp('Performing dft regiatration first');
[rough_shift movingReg] = dftregistration(fft2(im1),fft2(im2),100); % imout takes im2(moving) to im1(fixed)
%else
%    rough_shift =  zeros(1,4);
%    movingReg = im2;
%end
%%%%%%%% sosi
% figure;imshowpair(im1,im2, 'blend');
% figure;imshowpair(im1,movingReg, 'blend');


%% step 2: refine using intensity based
if nargin<4, flag = 0;end

[optimizer,metric] = imregconfig('multimodal');
optimizer.InitialRadius = 1e-5;
optimizer.MaximumIterations = 1500;

% [optimizer,metric] = imregconfig('multimodal');
% optimizer.InitialRadius = 1e-7;
% optimizer.MaximumIterations = 2500;


% [optimizer,metric] = imregconfig('monomodal');
% optimizer.GradientMagnitudeTolerance = 1.000000e-04;
% optimizer.MinimumStepLength = 1e-6;%1.000000e-05;
% optimizer.MaximumStepLength = 0.001;%6.250000e-02;
% optimizer.MaximumIterations = 500;
% optimizer.RelaxationFactor = 0.5;%5.000000e-01;

% [optimizer,metric] = imregconfig('monomodal');
% optimizer.GradientMagnitudeTolerance = 1.000000e-04;
% optimizer.MinimumStepLength = 1e-6;%1.000000e-05;
% optimizer.MaximumStepLength = 0.001;%6.250000e-02;
% optimizer.MaximumIterations = 500;
% optimizer.RelaxationFactor = 0.5;%5.000000e-01;



if flag
    disp('Using optimizer:');disp(optimizer);
    disp('Using metric:'); disp(metric);
end

tform = imregtform(movingReg,im1,'affine',optimizer, metric,...
    'DisplayOptimization', false, 'PyramidLevels', pyramid_levels);

% % show result

movingRegistered = imwarp(movingReg,tform,'OutputView',imref2d(size(im1)));
h = figure('Visible', 'off');
imshowpair(im1, movingRegistered);%,'Scaling','joint');
show_pair_image = getframe(h);
show_pair_image = show_pair_image.cdata;
% show_pair_image = [];
close;
valid_indices = find(im1>0.02 | movingRegistered>0.02);
im1_mean = mean(im1(valid_indices));
movingRegistered_mean = mean(movingRegistered(valid_indices));
im1_diff = im1(valid_indices)-im1_mean;
movingRegistered_diff = movingRegistered(valid_indices)-movingRegistered_mean;
 valid_corr2 = NaN;% sum(im1_diff .* movingRegistered_diff)/...
    % sqrt(sum(im1_diff.^2) * sum(movingRegistered_diff.^2));
similarity = [NaN, corr2(im1,movingRegistered), valid_corr2];
%ssim(im1, movingRegistered)
%similarity = max(similarity(:));


%% optional: produce point matches
% should be used (after proper scaling of point matches) with "ingest_point_match_set.m"
% to ingest the point-match set generated here
if nargout>=4 
    if nargin>2
        % generate and ingest a point-match set using this intensity based data
        p = randperm(numel(im2), npoints_per_pair);
        [y, x] = ind2sub(size(im2), p);
        p2 = [x(:) y(:)];  % points in image 2 coordinate system (need rescaling)
        % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% uncomment to look at matches
        % % sosi ----for presentation we need real features in the image
        %     psurf  = detectSURFFeatures(im2, 'NumOctaves', 2,...
        %                                    'NumScaleLevels', 4,...
        %                                    'MetricThreshold', 1500);
        %
        %    [f1, vp1]  = extractFeatures(im2,  psurf);
        %    p2 = vp1.Location;
        %    p2 = p2(randi(size(p2,1), 20,1),:);
        %    [x, y] = transformPointsForward(tform, p2(:,1), p2(:,2)); % transform those points according to tform
        %    p1 = [x(:) y(:)];  % points in image 1 coordinate system (need scaling)
        %    showMatchedFeatures(im1,im2, p1, p2, 'montage');
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        dx = -pad_y + rough_shift(4);
        dy = -pad_x + rough_shift(3);
        
        disp('pad_x and pad_y -- rough_shift -- dx dy -- tform.T([3 6])');
        %     disp([pad_x pad_y rough_shift([3 4]) dx dy tform.T([3 6]) ]);
        
        tform.T([3 6]) = tform.T([3 6]) + [dx dy];
        %     tform.T([3 6]) = [dx dy];
        
        
        
        [x, y] = transformPointsForward(tform, p2(:,1), p2(:,2)); % transform those points according to tform
        p1 = [x(:) y(:)];  % points in image 1 coordinate system (need scaling)
    else
        p1 = [];
        p2 = [];
    end
    varargout{1} = p1;
    varargout{2} = p2;
end
if nargout == 3 || nargout==5 
    varargout{nargout-2} = similarity;
end



%%%%%%%%%%%%%%%%%
% optimizer = registration.metric.MattesMutualInformation;
% optimizer.NumberOfSpatialSamples = 500;
% optimizer.NumberOfHistogramBins = 5;
% optimizer.UseAllPixels = 1;

%metric = registration.metric.MattesMutualInformation;

% movingRegistered = imregister(im2,im1,'affine',optimizer, metric,...
%                            'DisplayOptimization', true, 'PyramidLevels', 5);
%
