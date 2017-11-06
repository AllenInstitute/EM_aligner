%% tile information
clc;
% render collection
rc.baseURL = 'http://tem-services:8080/render-ws/v1';
rc.owner = 'hessh';
rc.project = 'fly_em_pre_iso';
rc.stack = 'column_30_acquire';

%tile ids
tile_1_id = '17-02-11_014625_0-0-0.23279.0';
tile_2_id = '17-02-11_014625_0-0-1.23279.0';

figure_visibility = 'on';
result_output_directory = [pwd '/point_match_parameterization_result_output'];
%% url parameters used for rendering tiles, and the defaults that will be used if not provided
url_options = [];
% DEFAULT VALUES:

%   fullScaleWidth          : unset (null)
%   fullScaleHeight         : unset (null)
url_options.renderWithFilter = 'false';
url_options.renderWithoutMask = 'true';
url_options.normalizeForMatching = 'true';
%% SIFT options struct. To test multiple values for a single parameter, set it using an array
% if SIFT_options or SURF_options is empty, then it is skipped.
SIFT_options = [];

SIFT_options.renderScale = 0.6;
SIFT_options.fillWithNoise = 'false';         %       Fill each canvas image with noise before rendering to improve point match
SIFT_options.outputDirectory = [pwd '/SIFT_output/'];

%%% SIFT feature generation parameters
SIFT_options.SIFTfdSize = 8;                  %       SIFT feature descriptor size: how many samples per row and column
SIFT_options.SIFTsteps = 6;                   %       SIFT steps per scale octave
SIFT_options.SIFTminScale = 0.1;             %       SIFT minimum scale: minSize * minScale < size < maxSize * maxScale
SIFT_options.SIFTmaxScale = 1.0;              %       SIFT maximum scale: minSize * minScale < size < maxSize * maxScale

%%% point-match filtering
SIFT_options.matchModelType = 'TRANSLATION';  %        Type of model for match filtering   Default: AFFINE  Possible Values: [TRANSLATION, RIGID, SIMILARITY, AFFINE]
SIFT_options.matchMaxEpsilon = 20;
SIFT_options.matchMinNumInliers = 4;
SIFT_options.matchMaxNumInliers = 300;
SIFT_options.matchMaxTrust = 30.0;             %        Reject match candidates with a cost larger than maxTrust * median cost
SIFT_options.matchIterations = 1000;          %        Match filter iterations
SIFT_options.matchMinInlierRatio = 0.0;       %        Minimal ratio of inliers to candidates for match filtering
SIFT_options.matchRod = 0.95;%0.92;                 %        Ratio of distances for matches


%% SURF parameters, currently only renderScale is used
SURF_options = [];
% SURF_options.verbose = 1;
% SURF_options.renderScale = 1.0;
% SURF_options.numPixels = 550;   % cut off window size for tiles to be compared -- larger means more of both images will be considered
% 
% %%%% SURF-specific parameters
% SURF_options.SURF_NumOctaves = 2;
% SURF_options.SURF_NumScaleLevels = 6;
% SURF_options.MetricThreshold = 5;    % decrease to return more features (potentially leading to more matches)
% 
% %%%% match parameters
% SURF_options.MatchThreshold = [15];   % increase to return more matches (max value is 100)
% SURF_options.Unique = true;
% SURF_options.Method = 'Exhaustive';
% SURF_options.MaxRatio = [0.8];        % increase to return more matches (max 1.0)
% SURF_options.Metric = 'SAD';        % other option is SSD --- switching to SSD changes effect of other parameters and leads to less matches generally
% 
% %%%% point-match filter options ---> make sure to use same (or stricter) filters when solving
% SURF_options.filter_pm = 1;      % if zero, then don't apply filter
% SURF_options.pmoptsMethod = 'Random Sample Consensus (RANSAC)';% other options are 'Least Median of Squares';
% SURF_options.pmoptsTransform = 'Affine';
% SURF_options.pmoptsNumRandomSamplingsMethod = 'Desired confidence';
% SURF_options.pmoptsMaximumRandomSamples = 3000;
% SURF_options.pmoptsDesiredConfidence = 99.5;
% SURF_options.pmoptsPixelDistanceThreshold = 50;

%% Set the output directory for storing the final images, as well as the desired visibility of the figures, and run the code
tic
point_match_optimization(rc, tile_1_id, tile_2_id, SIFT_options, SURF_options, url_options, result_output_directory, figure_visibility);
toc
%%


















































