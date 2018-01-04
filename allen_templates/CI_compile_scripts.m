cwd = pwd;
EM_ALIGNER_ROOT = fileparts(cwd);

addpath(genpath(EM_ALIGNER_ROOT));

try
    OUTPUT_FOLDER = [EM_ALIGNER_ROOT '/allen_templates/'];

    solver_scripts = [EM_ALIGNER_ROOT '/solver/*.m'];

    jsonlab_scripts = [EM_ALIGNER_ROOT '/external/jsonlab/*.m'];

    classes = [EM_ALIGNER_ROOT '/classes'];

    cmd = sprintf('mcc -m -R -nodesktop -v %s/allen_templates/em_solver.m -N -p %s -p vision -a %s -a %s -a %s -d %s', EM_ALIGNER_ROOT, EM_ALIGNER_ROOT, solver_scripts, jsonlab_scripts, classes, OUTPUT_FOLDER);

    eval(cmd);
catch M
    disp(M);
    exit(1);
end

exit(0);