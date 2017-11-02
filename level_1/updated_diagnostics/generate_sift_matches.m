function generate_sift_matches(pm, source_directory, bill_to, scale)
if isempty(source_directory), source_directory = pwd; end
if source_directory(end) ~= '/', source_directory(end+1) = '/'; end

% ==========================================================================
% Change these parameters for each run ...
%setenv('BILL_TO',bill_to);
%setenv('HARD_RUN_TIME_MINUTES','14400'); % 10 days
hard_run_time_minutes = '14400'; %10 days

% source data parameters
service_host='10.40.3.162:8080';      % use IP address for tem-services until DNS issue is resolved
json_files = dir([source_directory '/tile_pairs*.json*']);
pair_json_args = [];
for i=1:length(json_files)
  pair_json_args=[pair_json_args ' --pairJson ' source_directory json_files(i).name];
end

% Default SIFT parameters are:
%   --renderWithFilter true 
%   --renderWithoutMask true 
%   --renderScale 1.0 
%   --fillWithNoise true
%   --SIFTfdSize 8
%   --SIFTminScale 0.5
%   --SIFTmaxScale 0.85
%   --SIFTsteps 3
sift_parameters=sprintf('--renderWithFilter false --SIFTfdSize 4 --SIFTminScale %s --renderScale %s --SIFTmaxScale %s --SIFTsteps 3', num2str(scale - 0.02), num2str(scale), num2str(scale));

% Default match filtering parameters are:
%   --matchRod 0.92
%   --matchMaxEpsilon 20.0
%   --matchMinInlierRatio 0.0
%   --matchMinNumInliers 10
match_filter_parameters='--matchRod 0.92 --matchModelType TRANSLATION --matchMaxEpsilon 5.0 --matchMinNumInliers 4 --matchMaxNumInliers 50';

% To be nice to others, avoid requesting more than 60 nodes.
% When the cluster is busy, you may want to decrease node count to get running since
% Spark job won't start until number of requested nodes are available.
number_of_spark_nodes=15;

base_spark_logs_dir = '/groups/flyem/data/render/spark_output';
% ==========================================================================
% You should be able to leave everything under here as is ...
class='org.janelia.render.client.spark.SIFTPointMatchClient';

argv=sprintf('--baseDataUrl http://%s/render-ws/v1 --owner %s --collection %s %s %s --maxFeatureCacheGb 15 %s', service_host, pm.owner, pm.match_collection, sift_parameters, match_filter_parameters, pair_json_args);
spark_args = sprintf('--sparkRunInBackground n --sparkClass %s --sparkNodes %s --sparkBillTo %s --sparkHardRunTimeMinutes %s --sparkDir %s', class, num2str(number_of_spark_nodes), bill_to, hard_run_time_minutes, base_spark_logs_dir);

system('sleep 2');

system(sprintf('mkdir -p %slogs',source_directory));
local_spark_launch_log=[source_directory 'logs/spark_launch.log'];
system(sprintf('/groups/flyTEM/flyTEM/render/spark/bin/run-spark-job-lsf.sh %s %s | tee -a %s',spark_args, argv, local_spark_launch_log));
end