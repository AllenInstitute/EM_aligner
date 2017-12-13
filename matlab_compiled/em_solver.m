function em_solver(fn)
% Intended for deployment: solve matrix system using affine based on json input provided by fn

logroot='/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/'
newdir = set_AIBS_logging_path(logroot,'default');
copyfile(fn,strcat(newdir,'/input.json'));
%system_solve_affine_with_constraint_SL(strcat(newdir,'/input.json'));

system_solve_rigid_approximation_UB(strcat(newdir,'/input.json'));
