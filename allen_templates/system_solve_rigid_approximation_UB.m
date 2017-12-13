function [err, R, Tout, A, b, map_id, tIds, z_val] = system_solve_rigid_approximation_UB(fn)
% Intended for deployment: solve matrix system using rigid based on json input provided by fn


% read json input
sl = loadjson(fileread(fn));

sl = set_user_environment(sl);

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

%%% deprecated?
[err,R, Tout, A, b, map_id, tIds, z_val] = system_solve_rigid_approximation(sl.first_section, sl.last_section, sl.source_collection, sl.source_point_match_collection, sl.solver_options, sl.target_collection);