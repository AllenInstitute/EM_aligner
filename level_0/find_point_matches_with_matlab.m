function [m12_2, m12_1, fh] = find_point_matches_with_matlab(im1,im2, method, visible, suppressError, opt)
if nargin<4, visible = true; end
if nargin<5, suppressError = false; end
if nargin<6, opt = []; end
if ~isfield(opt, 'verbose'), opt.verbose = 0; end
B = [];
T = [];
if ~isfield(opt, 'SURF_NumOctaves'), opt.SURF_NumOctaves = 1; end
if ~isfield(opt, 'SURF_NumScaleLevels'), opt.SURF_NumScaleLevels = 10; end
if ~isfield(opt, 'SURF_MetricThreshold'), opt.SURF_MetricThreshold = 100; end

if ~isfield(opt, 'MatchThreshold'), opt.MatchThreshold = 100; end
if ~isfield(opt, 'Unique'), opt.Unique = true; end
if ~isfield(opt, 'Method'), opt.Method = 'Exhaustive'; end
if ~isfield(opt, 'MaxRatio'), opt.MaxRatio = 0.65; end
if ~isfield(opt, 'Metric'), opt.Metric = 'SAD'; end

if opt.verbose
    disp('SURF parameters:');
    disp(['NumOctaves: ' num2str(opt.SURF_NumOctaves)]);
    disp(['NumScaleLevels: ' num2str(opt.SURF_NumScaleLevels)]);
    disp(['MetricThreshold: ' num2str(opt.SURF_MetricThreshold)]);
    disp('---------------------');
    disp('Match parameters (for SURF):');
    disp(['MatchThreshold: ' num2str(opt.MatchThreshold)]);
    disp(['Unique: ' num2str(opt.Unique)]);
    disp(['Method: ' num2str(opt.Method)]);
    disp(['MaxRatio: ' num2str(opt.MaxRatio)]);
    disp(['Metric: ' num2str(opt.Metric)]);
    
end

[f1, vp1] = im_get_features(im2,method, opt);
[f2, vp2] = im_get_features(im1,method, opt);

[m12_1, m12_2] = im_pair_match_features_local(f1, vp1, f2, vp2, suppressError, opt);
warning off;
thresh = 2;
maxIm = 255;

fh = figure('visible', visible);
if ~isempty(m12_1) % matching features found
    showMatchedFeatures(im1, im2, m12_2, m12_1, 'montage');
else
    imshow(imfuse(im1, im2, 'montage'));
end
end

function [m1, m2] = im_pair_match_features_local(f1, vp1, f2, vp2, suppressError, opt)
%
%%%% m1 and m2 are corresponding point group objects that were generated
%%%% without any assumption about the transformation, but were selected
%%%% based on the assumption of a specific transformation

index_pairs = matchFeatures(f1, f2,...
    'MatchThreshold', opt.MatchThreshold,...
    'Unique', opt.Unique, ...
    'Method', opt.Method, ...
    'MaxRatio', opt.MaxRatio,...
    'Metric', opt.Metric);

if isempty(index_pairs)
    if suppressError
        warning on;
        warning('No matches found');
        warning off;
    else
        error('No matches found');
    end
end

m1  = vp1(index_pairs(:,1));
m2  = vp2(index_pairs(:,2));

if opt.filter_pm
    %%%%%% filter point matches using RANSAC
    warning off;
    % %%% constructing the geoTransformEst object requires providing a
    % %%% transformation
    geoTransformEst = vision.GeometricTransformEstimator; % defaults to RANSAC
    geoTransformEst.Method = opt.pmoptsMethod; %'Random Sample Consensus (RANSAC)';%'Least Median of Squares';
    geoTransformEst.Transform = opt.pmoptsTransform ;%'Affine';%'Nonreflective similarity';%'Affine';%
    geoTransformEst.NumRandomSamplingsMethod = opt.pmoptsNumRandomSamplingsMethod; %'Desired confidence';
    geoTransformEst.MaximumRandomSamples = opt.pmoptsMaximumRandomSamples;%1000;
    geoTransformEst.DesiredConfidence = opt.pmoptsDesiredConfidence; %99.95;
    geoTransformEst.PixelDistanceThreshold = opt.pmoptsPixelDistanceThreshold; % 1.0
    
    
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

%%%%%%%%%%%%%%%%%%%%%%%%%
end