cwd = pwd;
EM_ALIGNER_ROOT = fileparts(cwd);

addpath(genpath(EM_ALIGNER_ROOT));

try
    run compile_scripts.m;
catch M
    disp(M);
    exit(1);
end

exit(0);