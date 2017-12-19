
%% assumes that you are on the allen_templates folder path while compiling this script

cwd = pwd


EM_ALIGNER_ROOT = fileparts(cwd);

OUTPUT_FOLDER = [EM_ALIGNER_ROOT '/allen_templates/'];

solver_scripts = [EM_ALIGNER_ROOT '/solver/*.m'];

jsonlab_scripts = [EM_ALIGNER_ROOT '/external/jsonlab/*.m'];

classes = [EM_ALIGNER_ROOT '/classes'];

cmd1 = sprintf('mcc -m -R -nodesktop -v %s/matlab_compiled/system_solve_affine_with_constraint_SL.m -a %s -a %s -d %s', EM_ALIGNER_ROOT, solver_scripts, jsonlab_scripts, OUTPUT_FOLDER);
cmd2 = sprintf('mcc -m -R -nodesktop -v %s/matlab_compiled/system_solve_rigid_approximation_SL.m -a %s -a %s -d %s', EM_ALIGNER_ROOT, solver_scripts, jsonlab_scripts, OUTPUT_FOLDER);
cmd3 = sprintf('mcc -m -R -nodesktop -v %s/matlab_compiled/system_solve_rigid_approximation_SL.m -a %s -a %s -d %s', EM_ALIGNER_ROOT, solver_scripts, jsonlab_scripts, OUTPUT_FOLDER);
cmd4 = sprintf('mcc -m -R -nodesktop -v %s/matlab_compiled/solve_montage_SL.m -a %s -a %s -a %s -d %s', EM_ALIGNER_ROOT, solver_scripts, jsonlab_scripts, classes, OUTPUT_FOLDER);
cmd5 = sprintf('mcc -m -R -nodesktop -v %s/matlab_compiled/solve_slab_SL.m -a %s -a %s -a %s -d %s', EM_ALIGNER_ROOT, solver_scripts, jsonlab_scripts, classes, OUTPUT_FOLDER);
cmd6 = sprintf('mcc -m -R -nodesktop -v %s/matlab_compiled/point_match_gen_pairs_SURF.m -a %s -a %s -a %s -d %s', EM_ALIGNER_ROOT, solver_scripts, jsonlab_scripts, classes, OUTPUT_FOLDER);
cmd7 = sprintf('mcc -m -R -nodesktop -v %s/allen_templates/system_solve_main.m -a %s -a %s -a %s -d %s', EM_ALIGNER_ROOT, solver_scripts, jsonlab_scripts, classes, OUTPUT_FOLDER);

eval(cmd1);
eval(cmd2);
eval(cmd3);
eval(cmd4);
eval(cmd5);
eval(cmd6);
eval(cmd7);
