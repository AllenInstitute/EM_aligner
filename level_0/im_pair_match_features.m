function [m1, m2, tform_matrix] = im_pair_match_features(f1, vp1, f2, vp2)
%
%%%% m1 and m2 are corresponding point group objects that were generated
%%%% without any assumption about the transformation, but were selected
%%%% based on the assumption of a specific transformation

tform_matrix = [];
index_pairs = matchFeatures(f1, f2, 'MatchThreshold', 10,'Method', 'NearestNeighborRatio');        % no assumption about transformation is made here

if size(index_pairs,1)<3
    m1 = [];%SURFPoints();
    m2 = [];%SURFPoints();
    tform_matrix = [];
else
m1  = vp1(index_pairs(:,1));
m2  = vp2(index_pairs(:,2));


% disp('Estimating geometric transform');tic
% [tform,m2,m1] = estimateGeometricTransform(m2.Location,m1.Location, 'affine');
% tform_matrix = tform.T;
% disp('Done');toc

warning off;
% %%% constructing the geoTransformEst object requires providing a 
% %%% transformation
geoTransformEst = vision.GeometricTransformEstimator; % defaults to RANSAC
geoTransformEst.Method = 'Random Sample Consensus (RANSAC)';%'Least Median of Squares';
geoTransformEst.Transform = 'Affine';%'Nonreflective similarity';%'Affine';%
geoTransformEst.NumRandomSamplingsMethod = 'Desired confidence';
geoTransformEst.MaximumRandomSamples = 1000;
geoTransformEst.DesiredConfidence = 99.95;


% Invoke the step() method on the geoTransformEst object to compute the
% transformation from the |distorted| to the |original| image. You
% may see varying results of the transformation matrix computation because
% of the random sampling employed by the RANSAC algorithm.
[tform_matrix, inlierIdx] = step(geoTransformEst, m2.Location, m1.Location);
m1 = m1(inlierIdx).Location;
m2 = m2(inlierIdx).Location;
%%%%%%%%%%%%%%%%%%%%
warning on;

end



