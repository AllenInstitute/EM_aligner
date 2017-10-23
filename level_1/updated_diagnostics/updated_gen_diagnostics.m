function [output_struct, all_section_maps] = updated_gen_diagnostics(rcsource, rc, zstart, zend, point_matches, options)
%% Generates information about tile deformation and residuals
% Summarizes tile deformation and point-match residuals per tile and
% section using rcsource, r, zstart, zend, point matches and options.
% Output is a struct that contains residuals, area ratios and perimeter
% ratios, as well as their outliers. The struct also contains the residuals
% matrix for all sections.
% options fields and their defaults:
%    outlier_deviation_for_ratios     : 0.04
%    outlier_deviation_for_residuals  : 10
%    show_table   : false
%    show_deformations: false 0 = don'e show
%                             1 = display visible figure
%                             2 = save image of invisible figure to disk (not implemented yet)
%                             3 = captures invisible figure to memory (not implemented yet)
%    show_residuals: false    0 = don't show
%                             1 = displays a visible figure
%                             2 = save image of invisiblle figure to disk (not implemented yet)
%                             3 = captures invisible figure to memory (not implemented yet)
%    output_data_per_tile: true   Store information like values and ratios on a per tile basis 
% Output:
%       output_struct
% Author: Khaled Khairy, David Ackerman
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin<6
    options=[];
end

if ~isfield(options, 'outlier_deviation_for_ratios'), options.outlier_deviation_for_ratios = 0.04; end
if ~isfield(options, 'outlier_deviation_for_residuals'), options.outlier_deviation_for_residuals = 10; end
if ~isfield(options, 'show_deformations'), options.show_deformations = false; end
if ~isfield(options, 'show_residuals'), options.show_residuals = false; end
if ~isfield(options, 'show_table'), options.show_table = false; end
if ~isfield(options, 'output_data_per_tile'), options.output_data_per_tile = true; end

do_area_and_perimeter_calculations = true;
if isempty(rcsource)
   do_area_and_perimeter_calculations = false;
   if options.show_deformations
      warning('No rcsource provided, setting show_deformations to false');
      options.show_deformations=false;
   end
end

if options.show_residuals || options.show_deformations
   options.output_data_per_tile = true; 
end
output_struct=[];
if do_area_and_perimeter_calculations
    [ output_struct, counts, all_section_maps, unique_z, section_ids_grouped_by_z] = calculate_area_and_perimeter_ratios(rcsource, rc, zstart, zend, options);
else
    [unique_z, section_ids_grouped_by_z, ~, ~, ~] = get_section_ids(rc, zstart, zend);
    if options.show_residuals || nargout==2
       all_section_maps = calculate_section_maps(rc, zstart, zend, unique_z); 
    end
end
%% Montage and Cross-section residuals
output_struct2  = calculate_montage_point_match_residuals(rc, point_matches,unique_z, options);
output_struct.MontageResiduals = output_struct2;
if zstart ~= zend
    residuals_matrix = calculate_cross_section_point_match_residuals(rc, zstart, zend, point_matches, unique_z, section_ids_grouped_by_z, options);
    residuals_matrix = residuals_matrix + diag(output_struct.MontageResiduals.median_of_means);
    output_struct.CrossSectionAndMontageResidualsMatrix = residuals_matrix;
end
%%
if options.output_data_per_tile && (options.show_deformations || options.show_residuals)
    figure;plot(unique_z, output_struct.MontageResiduals.median_of_means, '-o', 'LineWidth',2);title(['Point-match residuals: ' num2str(zstart) ' to ' num2str(zend)]);
    xlabel('Section number');
    ylabel('Point-match residual (median of mean distance per layer)');
    if do_area_and_perimeter_calculations
        figure;plot(unique_z, output_struct.Area.median, '-o', 'LineWidth',2);title(['Area ratio median per layer: ' num2str(zstart) ' to ' num2str(zend)]);
        xlabel('Section number');
        ylabel('Area ratio median (ideally one)');
        
        %% display section tile box figures
        areas = output_struct.Area.median;
        areas = abs(1-areas);  % measure area devisation from 1
        %%% display histogram of tile areas for full slab
        figure;hist(areas,100);title('Deformation histogram: (ideally zero) for whole slab');axis tight
        xlim([0 1]);
        area_bounds = [1-options.outlier_deviation_for_ratios,1+options.outlier_deviation_for_ratios];
    end
    for z_index = 1:numel(unique_z)  % loop over sections
        if options.show_deformations && do_area_and_perimeter_calculations
            areas = output_struct.Area.ratios{z_index};
            areas(areas<=area_bounds(1)) = -Inf;
            areas(areas>=area_bounds(2)) = Inf;
            outlier_count_small = sum(areas<=area_bounds(1));
            outlier_count_large = sum(areas>=area_bounds(2));
            draw_colored_boxes(rc, unique_z(z_index), all_section_maps{z_index}, areas, area_bounds, [{['Area Ratios for: ' num2str(unique_z(z_index))] }...
                {sprintf('\\color[rgb]{0 0 0} %d Outliers \\leq %.2f \\color[rgb]{1 0 0} %d Outliers \\geq %.2f',outlier_count_small, area_bounds(1), outlier_count_large, area_bounds(2)) }]);
        end
        
        if options.show_residuals
            residuals = cellfun(@mean,output_struct.MontageResiduals.values{z_index});  % all tile residuals for section zu1(z_index)
            residuals_bounds = [min(residuals), options.outlier_deviation_for_residuals];
            outlier_count_large = sum(residuals>=residuals_bounds(2));
            only_greater_than = true;                      
            draw_colored_boxes(rc, unique_z(z_index), all_section_maps{z_index}, residuals, residuals_bounds, [{['Residuals for: ' num2str(unique_z(z_index))]}...
                {sprintf('\\color[rgb]{0 0 0} %d Unconnected Tiles \\color[rgb]{1 0 0} %d Outliers \\geq %0.2f ',output_struct.MontageResiduals.unconnected_count(z_index), outlier_count_large,residuals_bounds(2))} ],... 
                only_greater_than); % generate figure for y residuals
        end
    end
end

%% list section outliers and statistics per section
if do_area_and_perimeter_calculations
    MedianAreaRatio = output_struct.Area.median;
    MedianPerimeterRatio = output_struct.Perimeter.median;
    MedianMontageResidual = output_struct.MontageResiduals.median_of_means;
    AreaOutliers  = output_struct.Area.outlier_count;
    AreaOutliersPercent = output_struct.Area.outlier_percent;
    PerimeterOutliers  = output_struct.Perimeter.outlier_count;
    PerimeterOutliersPercent  = output_struct.Perimeter.outlier_percent;
    MontageResidualOutliers  = output_struct.MontageResiduals.outlier_count;
    MontageResidualOutliersPercent  = output_struct.MontageResiduals.outlier_percent;
    TotalAreaAndPerimeterOutliers = cellfun(@(area_outlier_tile_ids, perimeter_outlier_tile_ids) numel(unique([area_outlier_tile_ids(:);perimeter_outlier_tile_ids(:)])), output_struct.Area.outlier_tile_ids,  output_struct.Perimeter.outlier_tile_ids);
    SectionName = cellstr(num2str(unique_z'));
    Table = table(MedianAreaRatio,MedianPerimeterRatio,MedianMontageResidual, AreaOutliers, AreaOutliersPercent, PerimeterOutliers, PerimeterOutliersPercent, MontageResidualOutliers, MontageResidualOutliersPercent, TotalAreaAndPerimeterOutliers,...
        'RowNames',SectionName');
else
    MedianMontageResidual = output_struct.MontageResiduals.median_of_means;
    MontageResidualOutliers  = output_struct.MontageResiduals.outlier_count;
    MontageResidualOuliersPercent = output_struct.MontageResiduals.outlier_percent;
    SectionName = cellstr(num2str(unique_z'));
    Table = table(MedianMontageResidual, MontageResidualOutliers, MontageResidualOuliersPercent, ...
        'RowNames',SectionName');
end
output_struct.Table = Table;
if options.show_table, disp(Table); end

%% summarize deformation for whole stack
edges = [0:.02:10];
if options.show_deformations && do_area_and_perimeter_calculations
    if numel(unique_z) == 1
        [non_zero_rows,~] = find(counts'~=0);
        bar(edges+0.01,counts);
        xlim([edges(min(non_zero_rows)) edges(max(non_zero_rows))]);
        xlabel('Area ratio (ideally 1)')
        ylabel('Count');
        title(['Area ratio for: ' num2str(unique_z)]);
    else
        [non_zero_rows,~] = find(counts'~=0);
        cc = counts(1:end,:);
        % plot results
        hf = figure;
        ha = axes;
        b = bar3(edges+0.01, cc.'); % note the transpose to get the colors right
        xlabel('section number');
        ylabel('Area ratio (ideally 1)');
        zlabel('Area ratio');
        ylim([edges(min(non_zero_rows)) edges(max(non_zero_rows))]);
        colorbar
        for k = 1:length(b)
            zdata = b(k).ZData;
            b(k).CData = zdata;
            b(k).FaceColor = 'interp';
        end
        view(2);
         xticklabels = get(gca,'xticklabels');
         for i=1:length(xticklabels)
            xticklabels{i} = str2num( num2str(xticklabels{i} + unique_z(1))); 
         end
         set(gca,'xticklabels', xticklabels);
         pbaspect([1 2 1])
        title('summary area deformation of stack');
    end
end











