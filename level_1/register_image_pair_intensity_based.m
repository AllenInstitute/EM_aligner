%% register two images
function [tform, show_pair_image,  p1, p2] = register_image_pair_intensity_based(im1, im2, npoints_per_pair)
%%%

[optimizer,metric] = imregconfig('monomodal');

optimizer.GradientMagnitudeTolerance = 1.000000e-04;
optimizer.MinimumStepLength = 1e-6;%1.000000e-05;
optimizer.MaximumStepLength = 0.001;%6.250000e-02;
optimizer.MaximumIterations = 500;
optimizer.RelaxationFactor = 0.5;%5.000000e-01;



disp('Using optimizer:');disp(optimizer);
disp('Using metric:'); disp(metric);
tform = imregtform(im2,im1,'affine',optimizer, metric,...
    'DisplayOptimization', false, 'PyramidLevels', 5);

% % show result
movingRegistered = imwarp(im2,tform,'OutputView',imref2d(size(im1)));

if nargin>1
h = figure('Visible', 'off');
imshowpair(im1, movingRegistered,'Scaling','joint');
show_pair_image = getframe(h);
show_pair_image = show_pair_image.cdata;
close;
end


%% optional: produce point matches
% should be used (after proper scaling of point matches) with "ingest_point_match_set.m"
% to ingest the point-match set generated here

if nargout>2 && nargin>2
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
[x, y] = transformPointsForward(tform, p2(:,1), p2(:,2)); % transform those points according to tform
p1 = [x(:) y(:)];  % points in image 1 coordinate system (need scaling)
else
    p1 = [];
    p2 = [];
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