%%% test solve montage
fn = '/groups/flyTEM/home/khairyk/EM_aligner/test_scripts/test_solve_montage_input.json';
% read json input
sl = loadjson(fileread(fn));

if sl.verbose
    kk_clock();
    disp(['Using input file: ' fn]);
    disp(['Section(s) with z value:' num2str(sl.z_value)]);
    disp('Using solver options:');disp(sl.solver_options);
    disp('Using source collection:');disp(sl.source_collection);
    disp('Using target collection:');disp(sl.target_collection);
end

%%
solve_montage_SL(fn);
view_collection_dashboard(sl.target_collection);