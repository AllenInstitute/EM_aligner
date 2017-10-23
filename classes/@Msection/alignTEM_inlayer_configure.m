function obj = alignTEM_inlayer_configure(obj)
% configure the inlayer stitching pipeline with default parameters

% ---------------------- configure directories and filenames
s.dir_scratch = '/scratch/khairyk';

s.dir_work = '/nobackup/bock/khairy/mwork_alignTEM/temp';
% s.dir_work = '/scratch/khairyk/mwork_alignTEM_temp';

s.dir_bin = '/home/khairyk/mwork/stitching_utils';
s.chnk_size = 15;
s.pmin = 10;        % minimum number of points to consider a pair
s.nmax = 2000;      % maximum number of points to consider in a pair
s.tdim = 6;

%%% least-squares parameters
s.lambda = 5e7;


                    
%%% SURF parameters
s.NumOctaves = 3;
s.NumScaleLevels = 6;
s.MetricThreshold = 1000;
 
%%% additional parameters
s.job_out_option = '-j y -o /dev/null';
s.twait_jobs    = 5.0;       % seconds to wait before checking qstat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  ------------------------------      
obj.regConf.alignTEM = s;
