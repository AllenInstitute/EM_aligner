function em_solver(fn)
% Intended for deployment: solve matrix system using affine based on json input provided by fn

setenv('EMA_RENDERBINPATH','/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts');
setenv('EMA_SERVICE_HOST','em-131fs:8080');
setenv('TZ','America/Los_Angeles');

logroot='/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/'
newdir = set_AIBS_logging_path(logroot,'default');
copyfile(fn,strcat(newdir,'/input.json'));

system_solve_affine_with_constraint_SL(strcat(newdir,'/input.json'));

%system_solve_rigid_approximation_SL(strcat(newdir,'/input.json'));
