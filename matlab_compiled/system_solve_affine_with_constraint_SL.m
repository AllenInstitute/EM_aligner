function system_solve_affine_with_constraint_SL(fn,description)
% Intended for deployment: solve matrix system using affine based on json input provided by fn

diary on;

% read json input
sl = loadjson(fileread(fn));

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

if nargin<2
    description = '';
end

if strcmp(description,'')==0
    sl.solver_options.logging.description = description;
    %if function input description is '', will take from json
end

if sl.target_collection.owner=='danielk'
    [err,R, Tout, Diagnostics] = system_solve_affine_with_constraint(sl.first_section, sl.last_section, sl.source_collection, sl.source_point_match_collection, sl.solver_options, sl.target_collection);
else
    disp "target owner not danielk"
    disp "no action"
end
diary off;
