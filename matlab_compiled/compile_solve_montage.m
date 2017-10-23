%% compile (you must customize this script to your system/environment


dir_curr = pwd;
dir_EM_aligner = '/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/EM_aligner';   % your local EM_aligner directory
cd /allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/EM_aligner/matlab_compiled    % deploy to this directory

setenv('MCC_USE_DEPFUN','1')


astr = [];
fn_use = dir([dir_EM_aligner '/classes/@Msection*.m']);
for ix = 1:numel(fn_use)
astr = [astr sprintf(' -a %s/classes/@Msection/%s',dir_EM_aligner, fn_use(ix).name)];
end

%astr = [];
fn_use = dir([dir_EM_aligner '/classes/@tile*.m']);
for ix = 1:numel(fn_use)
astr = [astr sprintf(' -a %s/classes/@tile/%s',dir_EM_aligner, fn_use(ix).name)];
end

fn_use = dir([dir_EM_aligner '/solver/*.m']);
for ix = 1:numel(fn_use)
astr = [astr sprintf(' -a %s/solver/%s',dir_EM_aligner, fn_use(ix).name)];
end

%astr = [];
fn_use = dir([dir_EM_aligner '/external/jsonlab/*.m']);
for ix = 1:numel(fn_use)
astr = [astr sprintf(' -a %s/external/jsonlab/%s',dir_EM_aligner, fn_use(ix).name)];
end


str = sprintf('mcc -m -R -nodesktop -v solve_montage_SL.m %s;', astr);
eval(str);
