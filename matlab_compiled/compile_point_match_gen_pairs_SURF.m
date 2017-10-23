%% compile (you must customize this script to your system/environment


cd /groups/flyTEM/home/khairyk/EM_aligner/matlab_compiled

% astr = [];
% fn = dir('/groups/flyTEM/home/khairyk/EM_aligner/classes/@Msection*.m');
% for ix = 1:numel(fn)
% astr = [astr sprintf(' -a /groups/flyTEM/home/khairyk/EM_aligner/classes/@Msection/%s',fn(ix).name)];
% end

astr = [];
fn = dir('/groups/flyTEM/home/khairyk/EM_aligner/classes/@tile*.m');
for ix = 1:numel(fn)
astr = [astr sprintf(' -a /groups/flyTEM/home/khairyk/EM_aligner/classes/@tile/%s',fn(ix).name)];
end

% fn = dir('/groups/flyTEM/home/khairyk/EM_aligner/solver/*.m');
% for ix = 1:numel(fn)
% astr = [astr sprintf(' -a /groups/flyTEM/home/khairyk/EM_aligner/solver/%s',fn(ix).name)];
% end

%astr = [];
fn = dir('/groups/flyTEM/home/khairyk/mwork_nogit/fileexchange/jsonlab/*.m');
for ix = 1:numel(fn)
astr = [astr sprintf(' -a /groups/flyTEM/home/khairyk/mwork_nogit/fileexchange/jsonlab/%s',fn(ix).name)];
end

str = sprintf('mcc -m -R -nodesktop -v point_match_gen_pairs_SURF.m %s;', astr);
eval(str);



% cd /groups/flyTEM/home/khairyk/EM_aligner/matlab_compiled
