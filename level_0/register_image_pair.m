function [T, B] = register_image_pair(fixed,moving)

B = [];
T = [];
method = 'SURF';%'MSER_SURF';%'SURF';%'SURF'; %'BRISK' 'HARRIS' 'FAST''FAST_SURF';%
opt.SURF_NumOctaves = 1;
opt.SURF_NumScaleLevels = 10;
opt.SURF_MetricThreshold = 100;

[f1, vp1] = im_get_features(moving,method, opt);
[f2, vp2] = im_get_features(fixed,method, opt);

[m12_1, m12_2, tf12] = im_pair_match_features_local(f1, vp1, f2, vp2);
warning off;
thresh = 2;
maxIm = 255;
if ~isempty(m12_1) && ~isempty(m12_2)
    T = fitgeotrans([m12_1.Location],[m12_2.Location],'similarity');
    B = imwarp(moving, T,'FillValues', maxIm, 'OutputView',  imref2d(size(fixed)));
    %B = imwarp(im2, T,'FillValues', maxIm);
    
    %%%%%%%%% sosi
    figure; showMatchedFeatures(fixed, moving, m12_2, m12_1, 'montage');
else
    disp('No transformation found: possibly no features matched');

end

function [m1, m2, tform_matrix] = im_pair_match_features_local(f1, vp1, f2, vp2)
%
%%%% m1 and m2 are corresponding point group objects that were generated
%%%% without any assumption about the transformation, but were selected
%%%% based on the assumption of a specific transformation

tform_matrix = [];
index_pairs = matchFeatures(f1, f2,...
    'MatchThreshold', 99,...
    'Unique', true, ...
    'Method', 'Exhaustive', ...
    'Metric', 'SAD');

if isempty(index_pairs),
    error('No matches found');
end


m1  = vp1(index_pairs(:,1));
m2  = vp2(index_pairs(:,2));


% %%% constructing the geoTransformEst object requires providing a
% %%% transformation
geoTransformEst = vision.GeometricTransformEstimator; % defaults to RANSAC
geoTransformEst.Method = 'Random Sample Consensus (RANSAC)';%'Least Median of Squares';
geoTransformEst.Transform = 'Affine';%'Nonreflective similarity';%'Affine';%
geoTransformEst.NumRandomSamplingsMethod = 'Desired confidence';
geoTransformEst.MaximumRandomSamples = 5000;
geoTransformEst.DesiredConfidence = 99.95;


% Invoke the step() method on the geoTransformEst object to compute the
% transformation from the |distorted| to the |original| image. You
% may see varying results of the transformation matrix computation because
% of the random sampling employed by the RANSAC algorithm.
[tform_matrix, inlierIdx] = step(geoTransformEst, m2.Location, m1.Location);
m1 = m1(inlierIdx);
m2 = m2(inlierIdx);
%%%%%%%%%%%%%%%%%%%%
