function kk_disp_err(err)


disp(err);
disp(err.message);
for ix = 1:numel(err.stack)
    disp(err.stack(ix));
end

if isfield(err, 'remotecause')
    for ix = 1:numel(err.remotecause)
        kk_disp_err(err.remotecause{ix});
    end
end