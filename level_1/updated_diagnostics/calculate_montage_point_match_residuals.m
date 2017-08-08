function [ output_struct ] = calculate_montage_point_match_residuals(...
    rc, point_matches, varargin)
%% Generate statistics about tile montage residuals
% Calculates tile residuals per section for renderer collection rc using
% point_matches point matches and varargin. varargin should contain either the
% unique_z to be analyzed, or zstart and zend required to obtain unique_z.
% varargin should contain 1-3 arguments:
%    1:                       The input should be unique_z
%    2:                       The input should be zstart and zend, or unique_z and options
%    3:                       The input should be zstart, zend, and options
% options fields and their defaults:
%    outlier_deviation_for_residuals : 10 Max point match residual for tile
%                                         before being considered an outlier
%    min_points      : 10     Minimum number of points for input to load_point_matches
%    output_data_per_tile : true  Output values and ratios for each tile
%    dir_scratch : /scratch/ackermand Scratch directory
%    filter_point_matches: true
%    verbose     : true               Output status

% Output:
%    output_struct:           Contains all tile-tile mean residuals, median
%                             of mean tile residuals (averaged over all tile-tile pairs), number of
%                             outliers of the median of mean residuals, outlier tile ids, number of
%                             unconnected tiles and the ids of unconnected tiles median and max of mean tile
%                             residuals.
% Author: Khaled Khairy, David Ackerman
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check the input arguments
options = [];
if isempty(varargin)
    error('Not enough input arguments: need either unique_z, or zstart and zend.');
elseif length(varargin)==1
    if isstruct(varargin{1})
        error('Not enough input arguments: need either unique_z, or zstart and zend.');
    else
        unique_z = varargin{1};
    end
elseif length(varargin)==2
    if isstruct(varargin{2})
        unique_z = varargin{1};
        options = varargin{2};
    else
        zstart = varargin{1};
        zend = varargin{2};
        [unique_z, ~, ~, ~, ~] = get_section_ids(rc, zstart, zend+1);
        z_too_large = (unique_z>=zend+1);
        unique_z(z_too_large) = [];
    end
elseif length(varargin)==3
    if isstruct(varargin{3})
        zstart = varargin{1};
        zend = varargin{2};
        options = varargin{3};
        [unique_z, ~, ~, ~, ~] = get_section_ids(rc, zstart, zend+1);
        z_too_large = (unique_z>=zend+1);
        unique_z(z_too_large) = [];
    end
end

floor_unique_z = floor(unique_z);
unique_merged_z = unique(floor_unique_z);

new_dir_scratch=false;
if ~isfield(options, 'outlier_deviation_for_residuals'), options.outlier_deviation_for_residuals = 10; end
if ~isfield(options, 'min_points'), options.min_points = 10; end
if ~isfield(options,'output_data_per_tile'), options.output_data_per_tile = true; end
if ~isfield(options, 'dir_scratch')
    new_dir_scratch=true;
    options.dir_scratch = [pwd '/scratch_' num2str(randi(10000)) '_' datestr(datetime('now'),'yyyymmdd_HHMMSS')];
    warning('Will create temporary scratch directory %s which will be cleaned after', options.dir_scratch);
end
if ~isfield(options,'filter_point_matches'), options.filter_point_matches = true; end
if ~isfield(options, 'verbose'), options.verbose = true; end

dir_current = pwd;
dir_scratch = [options.dir_scratch '/temp_' num2str(randi(3000000))];
kk_mkdir(dir_scratch);
cd(dir_scratch);

num_el = length(unique_merged_z);
if options.output_data_per_tile, all_residuals_vector = cell(num_el,1); end

all_residuals_median = zeros(num_el,1);
all_residuals_mean = zeros(num_el,1);
all_residuals_max = zeros(num_el,1);
all_residuals_variance = zeros(num_el,1);
all_tile_ids = cell(num_el,1);
all_residuals_outlier_count = zeros(num_el,1);
all_residuals_outlier_percent = zeros(num_el,1);
all_residuals_outlier_tile_indices = cell(num_el,1);
all_residuals_outlier_tile_ids = cell(num_el,1);
all_unconnected_count = zeros(num_el,1);
all_unconnected_tile_indices = cell(num_el,1);
all_unconnected_tile_ids = cell(num_el,1);

% Loop over all unique z and print out progress
if options.verbose
    fprintf('Montage Residuals Progress:');
    fprintf(['\n' repmat('.',1,num_el) '\n\n']);
end
[zu, sID, ~, ~, ns] = get_section_ids(rc, zstart, zend);
parfor z_index = 1:numel(unique_merged_z)
    %% Determine point-matches and residuals for this section
    % First: load point-matches and section into "L" (point-matches are in L's pm struct field)
    matching_indices = find(floor_unique_z==unique_merged_z(z_index));
    valid_zs = unique_z(matching_indices);
    section_information = [];
    section_information.zu = zu(matching_indices);
    section_information.sID = sID(matching_indices);
    section_information.ns = ns(matching_indices);

    [L]  = ...
        load_point_matches(valid_zs(1), valid_zs(end), rc, point_matches, 0, ...
        options.min_points, 0,inf, section_information);
    
    if options.filter_point_matches
        if isfield(options, 'pmopts')
            L.pm = filter_pm(L.pm, options.pmopts);
        else
            L.pm = filter_pm(L.pm);
        end
    end
    
    % Second: generate point-match residuals from L.pm by looping through
    % all point matches, transforming them and calculating the mean residual
    % for each tile pair
    tile_residuals = cell(numel(L.tiles),1);
    tile_ids = {L.tiles.renderer_id};
    for point_match_index = 1:size(L.pm.M,1)
        adjacent_tile_1 = L.pm.adj(point_match_index,1);
        adjacent_tile_2 = L.pm.adj(point_match_index,2);
        point_matches_tile_1 = L.pm.M{point_match_index,1};
        point_matches_tile_2 = L.pm.M{point_match_index,2};
        point_matches_tile_1 = [point_matches_tile_1 ones(size(point_matches_tile_1,1),1)]*L.tiles(adjacent_tile_1).tform.T;  % Apply transformation
        point_matches_tile_2 = [point_matches_tile_2 ones(size(point_matches_tile_2,1),1)]*L.tiles(adjacent_tile_2).tform.T;  % Apply transformation
        residual = mean(sqrt((point_matches_tile_1(:,1)-point_matches_tile_2(:,1)).*(point_matches_tile_1(:,1)-point_matches_tile_2(:,1))  + (point_matches_tile_1(:,2)-point_matches_tile_2(:,2)).* (point_matches_tile_1(:,2)-point_matches_tile_2(:,2))));    %%%% sum of squared residuals
        tile_residuals{adjacent_tile_1} = [tile_residuals{adjacent_tile_1} residual];  % Aggregate residuals for adjacent tile 1
        tile_residuals{adjacent_tile_2} = [tile_residuals{adjacent_tile_2} residual];  % Aggregate residuals for adjacent tile 2
    end
    %% Determine residual outliers
    % Separate connected and unconnected tiles
    [~, do_tiles_appear_in_adj] =ismember((1:numel(L.tiles)),unique(L.pm.adj(:)));
    if numel(L.tiles)>1 % Make sure that there should be any connected tiles
        unconnected_tiles = (do_tiles_appear_in_adj == 0);
    else
        unconnected_tiles = []; %Then just a single tile
    end
    all_tile_ids{z_index} = tile_ids;
    all_unconnected_count(z_index) = sum(unconnected_tiles);
    all_unconnected_tile_ids{z_index} = tile_ids(unconnected_tiles);
    all_unconnected_tile_indices{z_index} = find(unconnected_tiles);
    if options.output_data_per_tile, all_residuals_vector{z_index} = tile_residuals; end  % Store tile residuals for this section
    % Calculate median of mean tile residuals, and outliers
    only_greater_than = true;
    [all_residuals_median(z_index), all_residuals_mean(z_index), all_residuals_max(z_index), all_residuals_variance(z_index), all_residuals_outlier_count(z_index), all_residuals_outlier_percent(z_index), all_residuals_outlier_tile_indices{z_index}, all_residuals_outlier_tile_ids{z_index}] = ...
        calculate_statistics_and_outliers(cellfun(@mean,tile_residuals), options.outlier_deviation_for_residuals, tile_ids, 'fixed_cutoff', only_greater_than);
    if options.verbose, fprintf('\b|\n'); end
end
% Create output struct
if options.output_data_per_tile
    output_struct.values = all_residuals_vector;
    output_struct.median_of_means = all_residuals_median;
    output_struct.mean_of_means = all_residuals_mean;
    output_struct.max_of_means = all_residuals_max;
    output_struct.variance_of_means = all_residuals_variance;
    output_struct.all_tile_ids = all_tile_ids;
    output_struct.outlier_count = all_residuals_outlier_count;
    output_struct.outlier_percent = all_residuals_outlier_percent;
    output_struct.outlier_tile_indices =all_residuals_outlier_tile_indices;
    output_struct.outlier_tile_ids = all_residuals_outlier_tile_ids;
    output_struct.unconnected_count = all_unconnected_count;
    output_struct.unconnected_tile_indices =all_unconnected_tile_indices;
    output_struct.unconnected_tile_ids = all_unconnected_tile_ids;
else
    output_struct.median_of_means = all_residuals_median;
    output_struct.mean_of_means = all_residuals_mean;
    output_struct.max_of_means = all_residuals_max;
    output_struct.variance_of_means = all_residuals_variance;
    output_struct.outlier_count = all_residuals_outlier_count;
    output_struct.outlier_percent = all_residuals_outlier_percent;
    output_struct.outlier_tile_ids = all_residuals_outlier_tile_ids;
    output_struct.unconnected_count = all_unconnected_count;
    output_struct.unconnected_tile_ids = all_unconnected_tile_ids;
end
cd(dir_current);
if new_dir_scratch
    system(sprintf('rm -rf %s', options.dir_scratch));
end
end

