function [ output_struct, results_table ] = calculate_drift_diagnostics( ...
    rcs, zs, point_matches, options)
%% Calculates drifts in terms of cross section residuals
% Calculates the cross section residuals for all collections in rc. If
% plotting is desired, the cross section residuals are plotted as well as
% the ratio between the first collection and each of the subsequent
% collections.
% options fields and their defaults:
%    calculate_montage_residuals: (false) Whether to calculate montage residuals
%    show_residuals_plot:        (false) Whether to show residuals plot
%    save_residuals_plot:        (false) Whether to save residuals plot 
%    plot_output_directory:            Output directory for saving residuals plots
% Output:
%       output_struct             Contains residuals matrix as well as
%                                 the mean and median residuals for ± 1 or 2 sections.
%       results_table             Summarizes the mean and median
%                                 information in the output_struct, making sure to only take the
%                                 means and medians of section pairs that are non-NaN in all
%                                 collections.
% Example:
% options.dir_scratch = '/scratch/ackermand';
% options.calculate_montage_residuals = false;
% options.xs_weight = 1;
% options.min_points = 3;
% options.max_points = Inf;
% options.number_of_cross_sections = 2;
% options.show_residuals_plot = true;
% options.save_residuals_plot = true;
% options.plot_output_directory = '/groups/flyTEM/home/ackermand/beautification/test_drift_for_khaled/';
% 
% rc.owner = 'flyTEM';
% rc.project = 'FAFBv14_kk';
% rc.stack = 'KK_05_9_2709_2953';
% rc.baseURL = 'http://10.37.5.60:8080/render-ws/v1';
% rc.verbose = 0;
% 
% pm.server= 'http://10.40.3.162:8080/render-ws/v1';
% pm.owner= 'flyTEM';
% pm.match_collection= 'FAFB_pm_4';
% pm.verbose= 0;
% 
% [output_struct, results_table] = calculate_drift_diagnostics(rc, (2867:2900), pm, options);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


if numel(rcs) ==1
    rcs(2).baseURL = 'http://10.37.5.60:8080/render-ws/v1';
    rcs(2).owner = 'flyTEM';
    rcs(2).project = 'FAFB00_beautification';
    rcs(2).stack = 'patch_FULL_FAFB_FUSED_05_ROTATED';
    rcs(2).verbose = 0;
    
    rcs(3).baseURL = 'http://10.37.5.60:8080/render-ws/v1';
    rcs(3).owner = 'flyTEM';
    rcs(3).project = 'FAFB00_beautification';
    rcs(3).stack = 'FULL_FAFB_FUSED_05_ROTATED';
    rcs(3).verbose = 0;
end

if ~isfield(options, 'calculate_montage_residuals'), options.calculate_montage_residuals = false; end
if ~isfield(options, 'show_residuals_plot'), options.show_residuals_plot = false; end
if ~isfield(options, 'save_residuals_plot'), options.save_residuals_plot = false; end
if options.save_residuals_plot
    if ~isfield(options, 'plot_output_directory') 
        error('Need options.plot_output_directory to save plot.');
    else
       if ~strcmp(options.plot_output_directory(end), '/'), options.plot_output_directory(end+1) = '/'; end
       system(['mkdir -p ' options.plot_output_directory]);
    end
end
zstart = zs(1);
zend = zs(end);
output_struct = [];
[unique_z, section_ids_grouped_by_z, ~, ~, ~] = get_section_ids(rcs(1), zstart, zend);
all_z = unique(floor(unique_z))';

distance_one_nonnan_values = ones(2*(numel(zs)-1),1);
distance_two_nonnan_values = ones(2*(numel(zs)-2),1);

for current_collection = 1:numel(rcs)
    output_struct(current_collection).stack = rcs(current_collection).stack;
    if zstart ~= zend
        
        residuals_matrix = ...
            calculate_cross_section_point_match_residuals(...
            rcs(current_collection), ...
            zstart, ...
            zend, ...
            point_matches, ...
            unique_z, ...
            section_ids_grouped_by_z, ...
            options);
        
        residuals_matrix(1 : length(residuals_matrix)+1 : numel(residuals_matrix)) = 0; %Set diagonal to 0 rather than NaN
        if options.calculate_montage_residuals
            montage_residuals = calculate_montage_point_match_residuals(rcs(current_collection), point_matches,unique_z, options);
            residuals_matrix = residuals_matrix + diag(montage_residuals.median_of_means);
        end
        output_struct(current_collection).residuals_matrix = residuals_matrix;
    end
    output_struct(current_collection).distance_one_residuals.values = [diag( output_struct(current_collection).residuals_matrix,1); diag(output_struct(current_collection).residuals_matrix,-1)];
    output_struct(current_collection).distance_one_residuals.mean = mean(output_struct(current_collection).distance_one_residuals.values);
    output_struct(current_collection).distance_one_residuals.median = median(output_struct(current_collection).distance_one_residuals.values);
    output_struct(current_collection).distance_two_residuals.values = [diag( output_struct(current_collection).residuals_matrix,2); diag(output_struct(current_collection).residuals_matrix,-2)];
    output_struct(current_collection).distance_two_residuals.mean = mean(output_struct(current_collection).distance_two_residuals.values);
    output_struct(current_collection).distance_two_residuals.median = median(output_struct(current_collection).distance_two_residuals.values);
    
    distance_one_nonnan_values = distance_one_nonnan_values & ~isnan(output_struct(current_collection).distance_one_residuals.values);
    distance_two_nonnan_values = distance_two_nonnan_values & ~isnan(output_struct(current_collection).distance_two_residuals.values);
end

DistanceOneMean = zeros(numel(rcs),1);
DistanceOneMedian = zeros(numel(rcs),1);
DistanceTwoMean = zeros(numel(rcs),1);
DistanceTwoMedian = zeros(numel(rcs),1);
for current_collection = 1:numel(rcs)
    DistanceOneMean(current_collection) = mean(output_struct(current_collection).distance_one_residuals.values(distance_one_nonnan_values));
    DistanceOneMedian(current_collection) = median(output_struct(current_collection).distance_one_residuals.values(distance_one_nonnan_values));
    DistanceTwoMean(current_collection) = mean(output_struct(current_collection).distance_two_residuals.values(distance_two_nonnan_values));
    DistanceTwoMedian(current_collection) = median(output_struct(current_collection).distance_two_residuals.values(distance_two_nonnan_values));
end
results_table = table(DistanceOneMean, DistanceOneMedian, DistanceTwoMean, DistanceTwoMedian,'RowNames', {rcs.stack});
disp(results_table);
ratios.residuals_matrix = [];
for comparison_collection = 2:numel(rcs)
    ratios(comparison_collection-1).residuals_matrix = output_struct(1).residuals_matrix./output_struct(comparison_collection).residuals_matrix;
end

%% Plot
if options.show_residuals_plot || options.save_residuals_plot
    num_rows = numel(rcs);
    iptsetpref('ImshowAxesVisible','on')
    maximum_of_all_matrices = max(max([output_struct(:).residuals_matrix]));
    label_spacing = max(1,floor(length(all_z)/5));
    if options.show_residuals_plot
        fh = figure();
    else
        fh = figure('visible','off');
    end
    set(gca,'position',[0 0 1 1],'units','normalized')
    
    for current_collection=1:numel(rcs)
        subplot(num_rows,2,num_rows*2 - (current_collection-1)*2-1);
        imshow(output_struct(current_collection).residuals_matrix/maximum_of_all_matrices);
        title(strrep(rcs(current_collection).stack,'_','\_'));
        set(gca,'XTick',(1:label_spacing:length(all_z)),'XTickLabel',all_z(1:label_spacing:end));
        set(gca,'YTick',(1:label_spacing:length(all_z)),'YTickLabel',all_z(1:label_spacing:end));
        c=colorbar();
        ylabel(c,'Residuals');
        set(c,'YTick',(0:.25:1),'YTickLabel',(0:maximum_of_all_matrices/4:maximum_of_all_matrices));
    end
    
    max_residuals_ratio = max(max([ratios(:).residuals_matrix]));
    min_residuals_ratio = min(min([ratios(:).residuals_matrix]));
    
    for comparison_collection = 2:numel(rcs)
        subplot(num_rows-1,2,(num_rows-1)*2 -(comparison_collection-2)*2);
        residuals_ratio = ratios(comparison_collection-1).residuals_matrix;
        residuals_ratio(isnan(residuals_ratio))=1;
        %rescaling based on having a ratio of 1 be in the center of the
        %color scaling
        residuals_ratio(residuals_ratio<=1) = 0.5*((residuals_ratio(residuals_ratio<=1) - min_residuals_ratio)/(1- min_residuals_ratio));
        residuals_ratio(residuals_ratio>1) = 0.5*((residuals_ratio(residuals_ratio>1) - 1)/(max_residuals_ratio - 1))+0.5;
        %residuals_ratio = (residuals_ratio-min_residuals_ratio)/(max_residuals_ratio-min_residuals_ratio);
        index_of_unity_ratio = 129;%(1-min_residuals_ratio)*255/(max_residuals_ratio-min_residuals_ratio)+1;
        red_and_blue_color = ((1:index_of_unity_ratio)-1)/(index_of_unity_ratio-1);
        decreased_residuals_color = ones(length(red_and_blue_color),3);
        decreased_residuals_color(:,[1,3]) = [red_and_blue_color', red_and_blue_color'];
        red_color = flip((256:-1:index_of_unity_ratio)-index_of_unity_ratio)/(256-index_of_unity_ratio);
        increased_residuals_color = zeros(length(red_color),3);
        increased_residuals_color(:,1) = red_color;
        combined_color_map = [decreased_residuals_color; increased_residuals_color];
        imshow(residuals_ratio, 'colormap',combined_color_map);
        title(sprintf('Ratio (%s/%s)', strrep(rcs(1).stack,'_','\_'), strrep(rcs(comparison_collection).stack,'_','\_')));
        set(gca,'XTick',(1:label_spacing:length(all_z)),'XTickLabel',all_z(1:label_spacing:end));
        set(gca,'YTick',(1:label_spacing:length(all_z)),'YTickLabel',all_z(1:label_spacing:end));
        c=colorbar();
        ylabel(c,'Ratio')
        caxis([0,1]);
        %middle = (1-min_residuals_ratio)/max_residuals_ratio;
        set(c,'YTick',[0, 0.25, 0.5, 0.75, 1],'YTickLabel',sort([min_residuals_ratio, (min_residuals_ratio+1)/2, 1, (max_residuals_ratio+1)/2, max_residuals_ratio]));
        pos=get(fh, 'position');
        pos(3) = 1500;
        pos(4) = 1000;
        set(fh, 'position', pos);
    end
    if options.save_residuals_plot
        saveas(fh,[options.plot_output_directory num2str(zstart) '_' num2str(zend) '.tif']);
        if ~options.show_residuals_plot, close(fh); end
    end
end
end