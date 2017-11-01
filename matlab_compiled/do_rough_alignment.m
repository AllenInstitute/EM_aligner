function do_rough_alignment(jsonfile)

sl = loadjson(fileread(jsonfile));

nfirst = sl.minz;
nlast = sl.maxz;

input_lowres_stack = sl.input_lowres_stack;
output_lowres_stack = sl.output_lowres_stack;
opts = sl.solver_options;
pm = sl.point_match_collection;

[L]  = load_point_matches(nfirst, nlast, input_lowres_stack, pm, opts.nbrs, opts.min_points, opts.xs_weight, opts.max_points);

[L2] = get_rigid_approximation(L, opts.solver, opts);
solver_opts.lambda = 10.^1;
solver_opts.edge_lambda = 10.^1;
solver_opts.constrain_edges = 0;
solver_opts.translate_to_origin = 1;
if opts.degree == 1
[L3, errA] = solve_affine_explicit_region(L2, solver_opts); % obtain an affine solution
else
L3 = L2
end

ingest_section_into_renderer_database(L3,output_lowres_stack, input_lowres_stack, pwd,...
              opts.translate_to_origin, opts.complete, opts.disableValidation);
