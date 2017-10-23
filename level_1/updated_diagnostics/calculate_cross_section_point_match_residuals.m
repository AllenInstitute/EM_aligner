function [residuals_matrix] = calculate_cross_section_point_match_residuals(rc, zstart, zend, point_matches, varargin)
%% Generate statistics about cross section residuals
% Calculates cross section residuals for renderer collection rc, using
% zstart, zend, point matches point matches and varargin. If varargin does
% not contain unique_z and section_ids_grouped_by_z, they will be obtained
% based on zstart and zend. 
% varargin should contain 0-3 arguments:
%    1:                       The input should be options
%    2:                       The input should be unique_z and section_ids_grouped_by_z
%    3:                       The input should be unique_z, section_ids_grouped_by_z and options
% opts fields and their defaults:
%    min_points                   : 10
%    max_points                   : 100
%    number_of_cross_sections     : 2
%    xs_weight                    : 0.5
%    dir_scratch                  : '/scratch/ackermand' 
%    plot_cross_section_residuals : false
% Output:
%    residuals_matrix
% Author: David Ackerman
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Check the input arguments
options = [];
if isempty(varargin)
    [unique_z, section_ids_grouped_by_z, ~, ~, ~] = get_section_ids(rc, zstart, zend);
elseif length(varargin)==1
    if isstruct(varargin{1})
        options = varargin{1};
        [unique_z, section_ids_grouped_by_z, ~, ~, ~] = get_section_ids(rc, zstart, zend);
    else
        error('Not enough input arguments: need both unique_z and section_ids_grouped_by_z.');
    end
elseif length(varargin)==2
    if isstruct(varargin{2})
        error('Not enough input arguments: need both unique_z and section_ids_grouped_by_z.');
    else
       unique_z = varargin{1};
       section_ids_grouped_by_z = varargin{2};
    end
elseif length(varargin)==3
    if isstruct(varargin{3})
        unique_z = varargin{1};
        section_ids_grouped_by_z = varargin{2};
        options = varargin{3};
    end
end

% Configure options
if ~isfield(options, 'min_points'), options.min_points = 10; end
if ~isfield(options, 'max_points'), options.max_points = 100; end
if ~isfield(options, 'number_of_cross_sections'), options.number_of_cross_sections = 2; end % This is how many sections above/below the current section we will calculate residuals between
if ~isfield(options, 'xs_weight'), options.xs_weight = 0.5; end
if ~isfield(options, 'dir_scratch'), options.dir_scratch = '/scratch/ackermand'; end
if ~isfield(options, 'plot_cross_section_residuals'), options.plot_cross_section_residuals = false; end

% Create scratch directory and change to it
 dir_current = pwd;
 dir_scratch = [options.dir_scratch '/temp_' num2str(randi(3000000))];
 kk_mkdir(dir_scratch);
 cd(dir_scratch);

webopts = weboptions('Timeout', 60);

% Create simplified residuals matrix where the residuals for the nth
% section (Sn) will be stored as, eg.:
%  Column 1   |   Column 2   |   Column 3   |   Column 4
% Sn -> Sn+1  |  Sn -> Sn+2  |  Sn+1 -> Sn  |  Sn+2 - > Sn 
unique_z_number_of_elements = numel(unique_z);
simplified_residuals_matrix=zeros(unique_z_number_of_elements,options.number_of_cross_sections*2);

% Print out status and loop through all unique zs
fprintf('Cross Section Residuals Progress:');
fprintf(['\n' repmat('.',1,unique_z_number_of_elements) '\n\n']);
parfor z_index=1:unique_z_number_of_elements
    % Load in transformations and map ids necessary to calculate
    % residuals for current section
    [T, map_id, ~, ~] = load_all_transformations(rc, unique_z(z_index:min(z_index+options.number_of_cross_sections,unique_z_number_of_elements)), dir_scratch);
    % new_residuals_values will store the residuals as:
    % [ Sn -> Sn+1 ,  Sn -> Sn+2  ,  Sn+1 -> Sn  ,  Sn+2 -> Sn ]
    % Necessary to have this variable because of parfor
    new_residuals_values=zeros(1,options.number_of_cross_sections*2);
    % Store the offsets of T separately, and convert the remainder to a
    % cell array for efficiency
    offsets = [T(:,3),T(:,6)];
    T(:,[3,6])=[];
    T=reshape(T, length(T),2,2);
    T=num2cell(T,[2,3]);
    T=cellfun(@squeeze,T,'UniformOutput',false);
    % Loop through all the required sections and calculate cross-sectional
    % residuals
    for section_step = 1:options.number_of_cross_sections
        if z_index+section_step<=unique_z_number_of_elements
            % Load the cross section point matches and adjacency matrix
            factor = options.xs_weight/(section_step+1);
            [cross_section_point_matches, adjacency, ~, ~] = load_cross_section_pm(point_matches, section_ids_grouped_by_z{z_index}, section_ids_grouped_by_z{z_index+section_step}, ...
                map_id, options.min_points, options.max_points, webopts, factor);
            if ~isempty(cross_section_point_matches)
                % We now calculate the residuals for each tile pair as the
                % average of all point match residuals between the two
                % tiles. Below, we store the information for each pair for,
                % eg., Sn->Sn+1 in ..._current_section_tiles and Sn+1->Sn
                % in ..._next_section_tiles. ic1 assigns each unique tile
                % number in Sn an index between 1 and
                % length(unique(adjacency(:,1)). Likewise for ic2.
                [~,~,ic1] = unique(adjacency(:,1),'stable');
                num_unique_current_section_tiles = max(ic1);
                [~,~,ic2] = unique(adjacency(:,2),'stable');
                num_unique_next_section_tiles = max(ic2);
                residuals_current_section_tiles = zeros(num_unique_current_section_tiles,1);
                counts_current_section_tiles = zeros(num_unique_current_section_tiles,1);
                residuals_next_section_tiles = zeros(num_unique_next_section_tiles,1);
                counts_next_section_tiles = zeros(num_unique_next_section_tiles,1);
                for i=1:size(cross_section_point_matches,1)
                    residual = mean(sqrt(sum((cross_section_point_matches{i,1}*T{adjacency(i,1)}+offsets(adjacency(i,1),:) - (cross_section_point_matches{i,2}*T{adjacency(i,2)}+offsets(adjacency(i,2),:))).^2,2)));
                    residuals_current_section_tiles(ic1(i)) = residuals_current_section_tiles(ic1(i)) + residual;
                    residuals_next_section_tiles(ic2(i)) = residuals_next_section_tiles(ic2(i)) + residual;
                    counts_current_section_tiles(ic1(i)) = counts_current_section_tiles(ic1(i))+1;
                    counts_next_section_tiles(ic2(i)) = counts_next_section_tiles(ic2(i))+1;
                end
                
                % To calculate the section residuals, we want to take the
                % median of the mean residuals; residuals/counts provides
                % the mean residuals between each tile and all its adjacent
                % tiles, as stored above
                new_residuals_values(section_step) = median(residuals_current_section_tiles./counts_current_section_tiles);
                new_residuals_values(section_step+options.number_of_cross_sections) = median(residuals_next_section_tiles./counts_next_section_tiles);
            end
            simplified_residuals_matrix(z_index,:) = new_residuals_values;
        end
    end
    fprintf('\b|\n');
end

% Create the full residuals matrix
residuals_matrix = zeros(length(unique_z));
for z_index = 1:unique_z_number_of_elements
    for section_step = 1:options.number_of_cross_sections
        if z_index+section_step<=unique_z_number_of_elements
            residuals_matrix(z_index, z_index+section_step) = simplified_residuals_matrix(z_index,section_step);
            residuals_matrix(z_index+section_step, z_index) = simplified_residuals_matrix(z_index,section_step+options.number_of_cross_sections);
        end
    end
end

% Plot residuals
if options.plot_cross_section_residuals
    all_z = (zstart:zend);
    iptsetpref('ImshowAxesVisible','on')
    figure();
    Outer = get(gca,'OuterPosition');
    set(gca,'OuterPosition',[Outer(1)+0.05 Outer(2) + 0.05 Outer(3)-0.05 Outer(4)-0.05])
    max_residuals_matrix = max(residuals_matrix(:));
    imshow(residuals_matrix/max_residuals_matrix);
    label_spacing = max(1,floor(length(all_z)/10));
    set(gca,'XTick',(1:label_spacing:length(all_z)),'XTickLabel',all_z(1:label_spacing:end));
    set(gca,'YTick',(1:label_spacing:length(all_z)),'YTickLabel',all_z(1:label_spacing:end));
    c=colorbar();
    ylabel(c,'Residuals');
    set(c,'YTick',(0:.25:1),'YTickLabel',(0:max_residuals_matrix/4:max_residuals_matrix));
    title(['Cross Section Residuals For ' num2str(zstart) '-' num2str(zend)]); 
end
cd(dir_current);
end











