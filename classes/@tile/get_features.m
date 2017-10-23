function obj = get_features(obj, filter, scale)

if nargin<2, filter='none';end
if nargin<3, scale = 1.0;end
% im1 = get_warped_image(obj, filter);

%disp(['Tile fetches local = ' num2str(obj.fetch_local)]);
im1 = get_image(obj, filter, scale);
if ~isempty(im1)
if strcmp(obj.featuresMethod,'MSER')
    regionsObj = detectMSERFeatures(im1, 'RegionAreaRange', [500 40000], 'MaxAreaVariation', 0.15);
    [f1, vp1] = extractFeatures(im1, regionsObj);
end

if strcmp(obj.featuresMethod,'FAST_SURF')
    hcornerdet = vision.CornerDetector('Method', 'Local intensity comparison (Rosten & Drummond)');
    ptsArray = step(hcornerdet, im1);
    ptsObj = SURFPoints;
    ptsObj = ptsObj.append(ptsArray, 'Scale', 2);
    [f1, vp1] = extractFeatures(im1, ptsObj);
end

if strcmp(obj.featuresMethod, 'SURF')
    % USE SURF
 %    p1  = detectSURFFeatures(im1, 'NumOctaves', 3, 'NumScaleLevels', 6);
    p1  = detectSURFFeatures(im1, 'NumOctaves', obj.SURF_NumOctaves,...
                                   'NumScaleLevels', obj.SURF_NumScaleLevels,...
                                   'MetricThreshold', obj.SURF_MetricThreshold);
                         
    [f1, vp1]  = extractFeatures(im1,  p1);
end
if strcmp(obj.featuresMethod, 'BRISK')
    % USE BRISK
    p1  = detectBRISKFeatures((im1));
    [f1   vp1]  = extractFeatures(im1,  p1);
end
if strcmp(obj.featuresMethod, 'FAST')
    % USE FAST
    p1  = detectFASTFeatures(im1);
    [f1   vp1]  = extractFeatures(im1,  p1);
end
if strcmp(obj.featuresMethod, 'HARRIS')
    % USE HARRIS (corner detection)
    corners  = detectHarrisFeatures(im1);
    [f1 vp1] = extractFeatures(im1, corners);
    vp1 = corners;
end

obj.features = f1;
obj.validPoints = vp1;
else
    warning('Empty image: skipping');
end