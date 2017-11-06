function system_solve_affine_with_constraint_SL(fn)
% Intended for deployment: solve matrix system using affine based on json input provided by fn

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


%%% deprecated?
[err,R, Tout, Diagnostics] = system_solve_affine_with_constraint(sl.first_section, sl.last_section, sl.source_collection, sl.source_point_match_collection, sl.solver_options, sl.target_collection);