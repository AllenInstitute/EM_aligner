function [f1, vp1, im1] = im_get_features(im1, fd, obj)

thresh = 5;indx = find(im1<thresh);r = rand(size(indx));im1(indx) = r * double(max(im1(:)));

 
if strcmp(fd,'MSER')
    regionsObj = detectMSERFeatures(im1, 'RegionAreaRange', [500 40000], 'MaxAreaVariation', 0.15);
    [f1, vp1] = extractFeatures(im1, regionsObj);
end

if strcmp(fd,'FAST_SURF')
    hcornerdet = vision.CornerDetector('Method', 'Local intensity comparison (Rosten & Drummond)');
    ptsArray = step(hcornerdet, im1);
    ptsObj = SURFPoints;
    ptsObj = ptsObj.append(ptsArray, 'Scale', 2);
    [f1, vp1] = extractFeatures(im1, ptsObj);
end

if strcmp(fd, 'SURF')
    % USE SURF
 %    p1  = detectSURFFeatures(im1, 'NumOctaves', 3, 'NumScaleLevels', 6);
 
    p1  = detectSURFFeatures(im1, 'NumOctaves', obj.SURF_NumOctaves,...
                                   'NumScaleLevels', obj.SURF_NumScaleLevels,...
                                   'MetricThreshold', obj.SURF_MetricThreshold);
                               
    [f1, vp1]  = extractFeatures(im1,  p1, 'Method', 'SURF', 'SURFSize', 128);
end
if strcmp(fd, 'BRISK')
    % USE BRISK
    p1  = detectBRISKFeatures((im1));
    [f1   vp1]  = extractFeatures(im1,  p1);
end
if strcmp(fd, 'FAST')
    % USE FAST
    p1  = detectFASTFeatures(im1);
    [f1   vp1]  = extractFeatures(im1,  p1);
end
if strcmp(fd, 'HARRIS')
    % USE HARRIS (corner detection)
    corners  = detectHarrisFeatures(im1);
    [f1 vp1] = extractFeatures(im1, corners);
    vp1 = corners;
end

