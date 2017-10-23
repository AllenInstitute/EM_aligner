function [ data_median, data_mean, data_variance, data_outlier_count, data_outlier_percent, data_outlier_indices, data_outlier_tile_ids ] = calculate_statistics_and_outliers( data, cutoff, tile_ids, determination_method, only_greater_than )
if nargin < 5
    only_greater_than = false; % Used if only want outliers greater than mean, for eg. residuals where smaller than the mean is better
end
data_median = nanmedian(data);
data_mean = nanmean(data);
data_variance = nanvar(data);
data_outlier_tile_ids = [];
if strcmp(determination_method, 'fixed_cutoff')
    if only_greater_than
        data_outlier_indices = find(data>=cutoff); % Cutoff is the accepted fixed deviation magnitude, here being used for ratios so subtract 1 
    else
        data_outlier_indices = find(abs(data-1)>=cutoff);
    end
    data_outlier_tile_ids = tile_ids(data_outlier_indices);
elseif strcmp(determination_method, 'std')
    if only_greater_than
        data_outlier_indices = find(data-nanmean(data)>=cutoff*nanstd(data)); % Cutoff is the number of standard deviations, but only care about positive
    else
        data_outlier_indices = find(abs(data-nanmean(data))>=cutoff*nanstd(data)); % Cutoff is the number of standard deviations, but only care about positive
    end
    data_outlier_tile_ids = tile_ids(data_outlier_indices)'; 
end
data_outlier_count = numel(data_outlier_tile_ids);
data_outlier_percent = data_outlier_count*100/numel(data);
end

