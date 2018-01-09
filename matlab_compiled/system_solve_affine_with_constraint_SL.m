function system_solve_affine_with_constraint_SL(fn,description)
% Intended for deployment: solve matrix system using affine based on json input provided by fn

diary on;
disp(fn);
% read json input
sl = loadjson(fileread(fn));

%set some user env vvariables (requires a "source" call before launching
%MATLAB or exe)
sl = set_user_environment(sl);

%override description, if provided
if nargin<2
    description = '';
end
if strcmp(description,'')==0
    sl.solver_options.logging.description = description;
    %if function input description is '', will take from json
end

% make alogging directory
%sl.solver_options.AIBSdir = set_AIBS_logging_path(sl.solver_options.logging.logroot,sl.solver_options.logging.description);
tmp=strsplit(fn,'/');
ldir = '';
for i=1:(size(tmp,2)-1)
    ldir=strcat(ldir,tmp(i),'/');
end
sl.solver_options.AIBSdir=char(ldir);

disp('using directory:')
disp(sl.solver_options.AIBSdir)
%copy the input json into it

%copyfile(fn,strcat(sl.solver_options.AIBSdir,'/input.json'))

if sl.verbose
    kk_clock();
    disp(['Using input file: ' fn]);
    disp(['First section:' num2str(sl.first_section)]);
    disp(['Last section:' num2str(sl.last_section)]);
    disp('Using solver options:');disp(sl.solver_options);
    disp('Using source collection:');disp(sl.source_collection);
    disp('Using target collection:');disp(sl.target_collection);
    for i = 1:numel(sl.source_point_match_collection)
        disp('Using point-match collection:');disp(sl.source_point_match_collection(i));
    end
end

%lamiter = [100 200 500 1000 2000 5000 10000 20000 50000 100000]
%for lam=lamiter
%    sl.solver_options.lambda=lam;
%    sl.solver_options.edge_lambda=lam;
%    sl.target_collection.stack = sprintf('lambda_sweep_%d',lam);
    [err,R, Tout, Diagnostics] = system_solve_affine_with_constraint(sl.first_section, sl.last_section, sl.source_collection, sl.source_point_match_collection, sl.solver_options, sl.target_collection);

    diary on;
    diary off;
%end
