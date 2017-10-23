function [output_struct, varargout] = calculate_area_and_perimeter_ratios( rcsource, rc, zstart, zend, options )
%% Generate statistics about tile deformations
% Calculates tile deformation per section, using source renderer collection
% rcsource, renderer collection rc, zstart and zend.
% options fields and their defaults:
%    outlier_deviation_for_ratios     : 0.04 , Deviation of tile area or perimeter beyond 
%                                              which it is considered an outlier (eg., the tile can
%                                              vary by +/- 4% when outlier_deviation_for_ratios = 0.04)
%    output_data_per_tile             : true , Output values and ratios for each tile
% Output:
%    output_struct:           Contains, for both area and perimeter: 
%                             all tile values, all tile ratios, median ratios per section, number of
%                             outliers per section based on outlier_deviation_for_ratios and outlier
%                             tile ids
%    varargout    :           Can optionally output counts (histogram count
%                             of area ratios by section), all_rc_section_map (transformed tile
%                             positions), unique_z, section_ids_grouped_by_z
% Author: Khaled Khairy, David Ackerman
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check and initialize options if necessary
if nargin<5
    options.outlier_deviation_for_ratios = 0.04;
    options.output_data_per_tile = true;
end

if ~isfield(options, 'outlier_deviation_for_ratios'), options.outlier_deviation_for_ratios = 0.04; end
if ~isfield(options,'output_data_per_tile'), options.output_data_per_tile = true; end

% Get the unique_z values and the section ids grouped by their z
[unique_z, section_ids_grouped_by_z, ~, ~, ~] = get_section_ids(rc, zstart, zend);
% Initialize variables to store deformation for all sections
numel_unique_z = numel(unique_z);
all_rc_section_map  = cell(numel_unique_z,1);

if options.output_data_per_tile
    all_rc_areas = cell(numel_unique_z,1);
    all_rc_area_ratios = cell(numel_unique_z,1);
    all_rc_perimeters = cell(numel_unique_z,1);
    all_rc_perimeter_ratios = cell(numel_unique_z,1);
end

all_rc_area_ratio_median = zeros(numel_unique_z,1);
all_rc_area_ratio_mean = zeros(numel_unique_z,1);
all_rc_area_ratio_variance = zeros(numel_unique_z,1);
all_rc_area_ratio_outliers_count = zeros(numel_unique_z,1);
all_rc_area_ratio_outliers_percent = zeros(numel_unique_z,1);
all_rc_area_ratio_outliers_indices = cell(numel_unique_z,1);
all_rc_area_ratio_outliers_tile_ids = cell(numel_unique_z,1);

all_rc_perimeter_ratio_median = zeros(numel_unique_z,1);
all_rc_perimeter_ratio_mean = zeros(numel_unique_z,1);
all_rc_perimeter_ratio_variance = zeros(numel_unique_z,1);
all_rc_perimeter_ratio_outliers_count = zeros(numel_unique_z,1);
all_rc_perimeter_ratio_outliers_percent = zeros(numel_unique_z,1);
all_rc_perimeter_ratio_outliers_indices = cell(numel_unique_z,1);
all_rc_perimeter_ratio_outliers_tile_ids = cell(numel_unique_z,1);
% to generate histogram counts we need to define bin edges
edges = [0:.02:10];
counts = zeros(numel(unique_z), numel(edges));
webopts = weboptions('Timeout', 60);

% Loop over all unique z and print out progress
fprintf('Area And Perimeter Ratio Progress:');
fprintf(['\n' repmat('.',1,numel(unique_z)) '\n\n']);
parfor z_index = 1:numel(unique_z)
    % call the Renderer API to fetch tile information from rc and rcsource
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
        rc.baseURL, rc.owner, rc.project, rc.stack,unique_z(z_index) );
    rc_data = webread(urlChar, webopts);
    
    urlChar = sprintf('%s/owner/%s/project/%s/stack/%s/z/%.1f/tile-specs', ...
        rcsource.baseURL, rcsource.owner, rcsource.project, rcsource.stack,unique_z(z_index) );
    rcsource_data = webread(urlChar, webopts);
    
    % Make sure the correct corresponding tiles are used in rc_data and rcsource_data
    [is_rc_tile_in_rcsource, rcsource_tile_indices] = ismember({rc_data(:).tileId}, {rcsource_data(:).tileId});
    rc_data(rcsource_tile_indices==0)=[];
    rcsource_tile_indices = rcsource_tile_indices(is_rc_tile_in_rcsource);
    
    % Initialize variables to store deformations for one section
    numel_rc_data = numel(rc_data);
    rc_areas = zeros(numel_rc_data,1);
    rc_perimeters = zeros(numel_rc_data,1);
    rc_area_ratios = zeros(numel_rc_data,1);
    rc_perimeter_ratios = zeros(numel_rc_data,1);
    rc_ids = cell(numel_rc_data,1);
    rc_positions_transformed = cell(numel_rc_data,1);
   
    % Loop over all rc tiles and calculate their areas, perimeters and their ratios to those of rcsource
    for rc_tile_index = 1:numel(rc_data)
        % Get correct corresponding tiles
        rc_tile = tile(rc_data(rc_tile_index));
        rcsource_tile_index = rcsource_tile_indices(rc_tile_index);
        rcsource_tile = tile(rcsource_data(rcsource_tile_index));
        rc_ids{rc_tile_index} = rc_tile.renderer_id;
        % make four corners for the tile
        x = 0;
        y = 0;
        rc_tile_position_x = [x; x + rc_tile.W; x + rc_tile.W; x];
        rc_tile_position_y = [y; y    ; y + rc_tile.H; y + rc_tile.H];
        %%% transform points
        if strcmp(class(rc_tile.tform), 'affine2d')
            rc_tile_position_transformed = [rc_tile_position_x(:) rc_tile_position_y(:) [1 1 1 1]']*rc_tile.tform.T;
        else
            rc_tile_position_transformed = transformPointsInverse(rc_tile.tform,[rc_tile_position_x Py]);
        end
        rc_positions_transformed{rc_tile_index} = {rc_tile_position_transformed};
        
        % Calculate area and ratio (assuming rcsource tile is rectangular)
        rc_areas(rc_tile_index) = polyarea(rc_tile_position_transformed(:,1), rc_tile_position_transformed(:,2));
        rc_area_ratios(rc_tile_index) = rc_areas(rc_tile_index)/(rcsource_tile.H * rcsource_tile.W);
        % Calculate perimeter and ratio (assuming rcsource tile is rectangular)
        rc_perimeters(rc_tile_index) = rc_perimeters(rc_tile_index) + sqrt((rc_tile_position_transformed(1,1)-rc_tile_position_transformed(2,1)).^2 + (rc_tile_position_transformed(1,2)-rc_tile_position_transformed(2,2)).^2);
        rc_perimeters(rc_tile_index) = rc_perimeters(rc_tile_index) + sqrt((rc_tile_position_transformed(2,1)-rc_tile_position_transformed(3,1)).^2 + (rc_tile_position_transformed(2,2)-rc_tile_position_transformed(3,2)).^2);
        rc_perimeters(rc_tile_index) = rc_perimeters(rc_tile_index) + sqrt((rc_tile_position_transformed(3,1)-rc_tile_position_transformed(4,1)).^2 + (rc_tile_position_transformed(3,2)-rc_tile_position_transformed(4,2)).^2);
        rc_perimeters(rc_tile_index) = rc_perimeters(rc_tile_index) + sqrt((rc_tile_position_transformed(1,1)-rc_tile_position_transformed(4,1)).^2 + (rc_tile_position_transformed(1,2)-rc_tile_position_transformed(4,2)).^2);
        rc_perimeter_ratios(rc_tile_index) = rc_perimeters(rc_tile_index)/(2 * rcsource_tile.H + 2* rcsource_tile.W);
    end
    % Calculate histogram and store section data in variable for all sections
    counts(z_index,:) = histc(rc_area_ratios, edges);
    if options.output_data_per_tile
        all_rc_areas{z_index} = rc_areas;
        all_rc_perimeters{z_index} = rc_perimeters;
        all_rc_area_ratios{z_index} = rc_area_ratios;
        all_rc_perimeter_ratios{z_index} = rc_perimeter_ratios;
    end
    [all_rc_area_ratio_median(z_index), all_rc_area_ratio_mean(z_index), all_rc_area_ratio_variance(z_index), all_rc_area_ratio_outliers_count(z_index), all_rc_area_ratio_outliers_percent(z_index), all_rc_area_ratio_outliers_indices{z_index}, all_rc_area_ratio_outliers_tile_ids{z_index}] = ...
        calculate_statistics_and_outliers( rc_area_ratios, options.outlier_deviation_for_ratios, rc_ids, 'fixed_cutoff');
    [all_rc_perimeter_ratio_median(z_index), all_rc_perimeter_ratio_mean(z_index), all_rc_perimeter_ratio_variance(z_index), all_rc_perimeter_ratio_outliers_count(z_index), all_rc_perimeter_ratio_outliers_percent(z_index), all_rc_perimeter_ratio_outliers_indices{z_index}, all_rc_perimeter_ratio_outliers_tile_ids{z_index}] = ...
        calculate_statistics_and_outliers( rc_perimeter_ratios, options.outlier_deviation_for_ratios, rc_ids, 'fixed_cutoff');
    all_rc_section_map{z_index} = rc_positions_transformed; 
    fprintf('\b|\n');
end

% Create the output struct and optional outputs
if options.output_data_per_tile
    output_struct.Area.values = all_rc_areas;
    output_struct.Area.ratios = all_rc_area_ratios;
    output_struct.Area.median = all_rc_area_ratio_median;
    output_struct.Area.mean = all_rc_area_ratio_mean;
    output_struct.Area.variance = all_rc_area_ratio_variance;
    output_struct.Area.outlier_count = all_rc_area_ratio_outliers_count;
    output_struct.Area.outlier_percent = all_rc_area_ratio_outliers_percent;
    output_struct.Area.outlier_tile_indices = all_rc_area_ratio_outliers_indices;
    output_struct.Area.outlier_tile_ids = all_rc_area_ratio_outliers_tile_ids;
    
    output_struct.Perimeter.values = all_rc_perimeters;
    output_struct.Perimeter.ratios = all_rc_perimeter_ratios;
    output_struct.Perimeter.median = all_rc_perimeter_ratio_median;
    output_struct.Perimeter.mean = all_rc_perimeter_ratio_mean;
    output_struct.Perimeter.variance = all_rc_perimeter_ratio_variance;
    output_struct.Perimeter.outlier_count = all_rc_perimeter_ratio_outliers_count;
    output_struct.Perimeter.outlier_percent = all_rc_perimeter_ratio_outliers_percent;
    output_struct.Perimeter.outlier_tile_indices = all_rc_perimeter_ratio_outliers_indices;
    output_struct.Perimeter.outlier_tile_ids = all_rc_perimeter_ratio_outliers_tile_ids;
else
    output_struct.Area.median = all_rc_area_ratio_median;
    output_struct.Area.mean = all_rc_area_ratio_mean;
    output_struct.Area.variance = all_rc_area_ratio_variance;
    output_struct.Area.outlier_count = all_rc_area_ratio_outliers_count;
    output_struct.Area.outlier_percent = all_rc_area_ratio_outliers_percent;
    output_struct.Area.outlier_tile_ids = all_rc_area_ratio_outliers_tile_ids;
    
    output_struct.Perimeter.median = all_rc_perimeter_ratio_median;
    output_struct.Perimeter.mean = all_rc_perimeter_ratio_mean;
    output_struct.Perimeter.variance = all_rc_perimeter_ratio_variance;
    output_struct.Perimeter.outlier_count = all_rc_perimeter_ratio_outliers_count;
    output_struct.Perimeter.outlier_percent = all_rc_perimeter_ratio_outliers_percent;
    output_struct.Perimeter.outlier_tile_ids = all_rc_perimeter_ratio_outliers_tile_ids;
end

if nargout > 1, varargout{1} = counts; end
if nargout > 2, varargout{2} = all_rc_section_map; end
if nargout > 3, varargout{3} = unique_z; end
if nargout > 4, varargout{4} = section_ids_grouped_by_z; end

end

