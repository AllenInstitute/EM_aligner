function create_section_diagnostic_maps( rc_in, output_struct_in, section_zs, options, section_maps_in )
if numel(rc_in) ~= numel(output_struct_in), error('rc and output_struct need to be the same size'); end
if nargin<5, section_maps_provided = false; else section_maps_provided = true; end
if section_maps_provided
    if numel(rc_in) ~= numel(section_maps_in)
        error('rc and section_maps need to be the same size');
    end
end
if ~isfield(options, 'save_comparison_figure'), options.save_comparison_figure = false; end
num_to_compare = numel(rc_in);
if isfield(output_struct_in(1), 'Area')
    number_of_rows = 3;
else
    number_of_rows = 1;
end

for z_index=1:numel(section_zs)
    if isfield(options, 'visible') && options.visible == true
        new_fig = figure();
    else
        new_fig = figure('visible','off');
    end
    for index_to_compare = 1:numel(rc_in)
        rc = rc_in(index_to_compare);
        output_struct = output_struct_in(index_to_compare);
        map_options=[];
        current_z = section_zs(z_index);
        if section_maps_provided
            all_section_maps = section_maps_in(index_to_compare);
        else
            all_section_maps = calculate_section_maps(rc, current_z, current_z);
        end
        map_options.subplotting = true;
        plot_count = index_to_compare;
        subplot(number_of_rows,num_to_compare,plot_count);
        
        if isfield(output_struct, 'Area')
            ratio_bounds = [1-options.outlier_deviation_for_ratios,1+options.outlier_deviation_for_ratios];
            areas = output_struct.Area.ratios{z_index};
            areas(areas<=ratio_bounds(1)) = -Inf;
            areas(areas>=ratio_bounds(2)) = Inf;
            outlier_count_small = sum(areas<=ratio_bounds(1));
            outlier_count_large = sum(areas>=ratio_bounds(2));
            map_options.label_str{1} = [{['\fontsize{12}' strrep(rc.stack,'_','\_')]} ...
                {['\fontsize{11}Area Ratios for: ' num2str(current_z)] }...
                {sprintf('\\color[rgb]{0 0 0} %d Outliers \\leq %.2f \\color[rgb]{1 0 0} %d Outliers \\geq %.2f',outlier_count_small, ratio_bounds(1), outlier_count_large, ratio_bounds(2)) }];
            map_options.label_str{2} = 'Area Ratio';
            draw_colored_boxes(rc, current_z, all_section_maps{z_index}, areas, ratio_bounds, map_options);
            
            plot_count = plot_count+num_to_compare;
            subplot(number_of_rows,num_to_compare,plot_count);
            perimeters = output_struct.Perimeter.ratios{z_index};
            perimeters(perimeters<=ratio_bounds(1)) = -Inf;
            perimeters(perimeters>=ratio_bounds(2)) = Inf;
            outlier_count_small = sum(perimeters<=ratio_bounds(1));
            outlier_count_large = sum(perimeters>=ratio_bounds(2));
            map_options.label_str{1} = [{['Perimeter Ratios for: ' num2str(current_z)] }...
                {sprintf('\\color[rgb]{0 0 0} %d Outliers \\leq %.2f \\color[rgb]{1 0 0} %d Outliers \\geq %.2f',outlier_count_small, ratio_bounds(1), outlier_count_large, ratio_bounds(2)) }];
            map_options.label_str{2} = 'Perimeter Ratio';
            draw_colored_boxes(rc, current_z, all_section_maps{z_index}, perimeters, ratio_bounds, map_options);
            plot_count = plot_count+num_to_compare;
        end
        subplot(number_of_rows,num_to_compare,plot_count);
        residuals = cellfun(@mean,output_struct.MontageResiduals.values{z_index});  % all tile residuals for section zu1(z_index)
        residuals_bounds = [min(residuals), options.outlier_deviation_for_residuals];
        outlier_count_large = sum(residuals>=residuals_bounds(2));
        map_options.only_greater_than = true;
        map_options.label_str{1} = [{['Residuals for: ' num2str(current_z)]}...
            {sprintf('\\color[rgb]{0 0 0} %d Unconnected Tiles \\color[rgb]{1 0 0} %d Outliers \\geq %0.2f ',output_struct.MontageResiduals.unconnected_count(z_index), outlier_count_large,residuals_bounds(2))} ];
        map_options.label_str{2} = 'Residuals (Pixels)';
        draw_colored_boxes(rc, current_z, all_section_maps{z_index}, residuals, residuals_bounds, map_options); % generate figure for y residuals
    end
end
pos=get(new_fig, 'position');
pos(3) = 922;
pos(4) = 1031;
set(new_fig, 'position', pos);
if options.save_comparison_figure
    if ~isfield(options, 'save_comparison_figure_directory'), error('Need save_comparison_figure_directory if saving'); end
    if ~strcmp(options.save_comparison_figure_directory(end),'/'), options.save_comparison_figure_directory(end+1) = '/'; end
    if ~exist(options.save_comparison_figure_directory), mkdir(options.save_comparison_figure_directory); end
    if numel(rc_in) == 2
        saveas(gcf,[options.save_comparison_figure_directory '/' rc_in(1).stack '_vs_' rc_in(2).stack '_section_' num2str(section_zs(z_index)) '.tif']);
    else
        saveas(gcf,[options.save_comparison_figure_directory '/' rc_in(1).stack '_section_' num2str(section_zs(z_index)) '.tif']);     
    end
end
if ~options.visible, close(new_fig); end
end

