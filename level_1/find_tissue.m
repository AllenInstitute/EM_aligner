function [imc1] = find_tissue(im1,indx1, hsize, sigma, erode_dsize)
% uses saliency point detections to find areas in the image that might
% contain tissue
% indx1 contains coordinates to be excluded (orginally from the mask)

p1  = detectSURFFeatures(im1, 'NumOctaves', 2,'NumScaleLevels', 8,'MetricThreshold', 500);

%corners  = detectHarrisFeatures(im1);
%%%%%%% sosi
% figure(1);imshow(im1); hold on;plot(p1.selectStrongest(10000));
% figure(2);imshow(im2); hold on;plot(p2.selectStrongest(100));
% figure; imshow(im1);hold on;plot(corners.Location(:,1), corners.Location(:,2),'*');
%%%%%%%%%%%%%


% here is a hack to generate a tissue probablity image
sp1 = ceil(p1.Location);                        % round off locations of features
[r,c] = ind2sub(size(im1), indx1);              % coordinates into im1 corresponding to mask areas
[~, ia, ~] = intersect(sp1, [c r],'rows');      % which points in sp1 coincide with the mask area
sp1 = sp1;sp1(ia,:) = [];                       % limit sp1 to points that are in the image proper
sp1 = unique(sp1, 'rows');

% generate a diffuse image with higher intensity where there is tissue (i.e. there are more saliency points)
tissueix = sub2ind(size(im1), sp1(:,2), sp1(:,1));   % get the linear indices of surviving points
imc1 = zeros(size(im1));
imc1(tissueix(:)) = 255;    % mark presence of tissue by setting the value to 255;



% diffuse the image using gausian filter
h = fspecial('gaussian', hsize,sigma);
imc1 = mat2gray(imfilter(imc1, h));

% get rid of edges and fragments
se = strel('disk',erode_dsize);
imc1 = imopen(imc1,se);

% diffuse on more time
imc1 = mat2gray(imfilter(imc1, h));

%%%%%%%% sosi
% imshow(im1); hold on; plot(c(:), r(:),'*');
% imshow(im1); hold on; plot(sp1(:,1), sp1(:,2),'*');
% imshow(imc1);
%%%%%%%%%%%%%%