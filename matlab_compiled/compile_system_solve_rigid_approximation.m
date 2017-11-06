%% compile (you must customize this script to your system/environment


cd /groups/flyTEM/home/ackermand/EM_aligner/matlab_compiled

astr = [];
fn = dir('/groups/flyTEM/home/ackermand/EM_aligner/solver/*.m');
for ix = 1:numel(fn)
astr = [astr sprintf(' -a /groups/flyTEM/home/ackermand/EM_aligner/solver/%s',fn(ix).name)];
end

fn = dir('/groups/flyTEM/home/ackermand/EM_aligner/external/jsonlab/*.m');
for ix = 1:numel(fn)
astr = [astr sprintf(' -a /groups/flyTEM/home/ackermand/EM_aligner/external/jsonlab/%s',fn(ix).name)];
end


str = sprintf('mcc -m -R -nodesktop -v system_solve_rigid_approximation_SL.m %s;', astr);
eval(str);
