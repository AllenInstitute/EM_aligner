## Prerequisites
We are assuming that the Renderer and point-match services (and associated database) are set up and accessible for example at http://tem-services.int.janelia.org.
Also, you are using Matlab 2016b and above with toolboxes: Computer Vision Systems (or Video and Blockset), ImageProcessing, Statistics, (optional) Matlab compiler and (optional) Parallel computing. The EM_aligner directory and subdirectories are on your Matlab path.

## Montaging of one section by calculating and using SURF point-matches: non-deployed point-match generation + solve
Use this only if you don't have precalculated point-matches.
A full montage of a specific section (a set of tiles sharing the same z value) defined by "source_collection" and "section_number" will calculate point-matches using SURF features between tile pairs, persist those point-matches in a point-match database collection "target_point_match_collection", solve the registration problem using "solver_options", and persist the resulting transformations into the Renderer collection "target_collection". 

at the Matlab prompt:

[1] fn = 'full_path_to_json_configuration_file.json';  %% specify the input json file

[2] montage_section_SL_prll(fn); %% perform montage

If CATMAID dynamic rendering is set up, you can view your registered montage using a URL for example similar to this:
http://tem-services.int.janelia.org:8080/render-ws/view/stacks.html?owner=flyTEM&project=test&dynamicRenderHost=renderer:8080&catmaidHost=renderer-catmaid:8000



An example json input file is provided below.


```json
{
    "__comments": {
        "comment_0": "IMPORTANT: Before running check: source_collection, target_collection ...",
        "comment_1": "... target_point_match_collection, scratch and section_number",
        "comment_2": "Parameters to tweak I : solver_options.scale, solver_options.lambda",
        "comment_3": "Parameters to tweak II: solver_options.min_points, solver_options.max_points",
        "comment_4": " common values: solver_options.scale 0.3-0.5, solver_options.lambda = 0.0001 - 100",
        "comment_5": " common values: solver_options.min_points = 3, solver_options.max_points = 100"
    },
	"solver_options": {
		"min_tiles": 3,
		"degree": 1,
		"outlier_lambda": 1000,
		"solver": "backslash",
		"min_points": 10,
        "max_points": 50,
		"nbrs": 0,
		"xs_weight": 0.05,
		"stvec_flag": 0,
		"conn_comp": 1,
		"distributed": 0,
		"lambda": 0.1,
		"edge_lambda": 0.1,
		"small_region_lambda": 10,
		"small_region": 5,
		"calc_confidence": 1,
		"translation_fac": 1,
        "dthresh_factor": 1.2,
        "scale": 0.5,
        "use_peg": 1,
        "peg_weight": 0.0001,
        "peg_npoints": 5
	},
    "SURF_options": {
		"SURF_NumOctaves": 2,
		"SURF_NumScaleLevels": 3,
        "SURF_MetricThreshold": 1000,
        "SURF_MaxFeatures": 100
	},
	"source_collection": {
		"stack": "v1_acquire",
		"owner": "flyTEM",
		"project": "spc",
		"service_host": "tem-services.int.janelia.org:8080",
		"baseURL": "http://tem-services.int.janelia.org:8080/render-ws/v1",
		"verbose": 1
	},
	"target_collection": {
		"stack": "v1_montage_SURF_kk04_P2",
		"owner": "flyTEM",
		"project": "spc",
		"service_host": "tem-services.int.janelia.org:8080",
		"baseURL": "http://tem-services.int.janelia.org:8080/render-ws/v1",
		"verbose": 1,
        "versionNotes": "experiments to find optimal parameters for Allen dataset"
	},
	"target_point_match_collection": {
		"server": "http://tem-services.int.janelia.org:8080/render-ws/v1",
		"owner": "flyTEM",
		"match_collection": "spc_test"
	},
	"section_number": 3357,
    "image_filter": "true",
    "scratch": "/gpfs1/scratch/spc/matlab_work/montage/scratch",
    "renderer_client": "/groups/flyTEM/flyTEM/render/bin/render.sh",
	"verbose": 2,
    "ncpus": 8,
    "complete": 0

}

```
## Montage using deployed application: deployed point-match generation + solve
Under directory matlab_compiled, open the file "compile_montage_section" for editing.
Edit lines 4 and 5 and run the script.
Now the "compiled" output file can be called from a the shell (or used in a qsub system) by passing it the path to the json input file without need for additional Matlab licenses.
An example for deploying multiple montage jobs (using a Matlab script) is provided [here] (/template_production_scripts/SPC_scripts/script_to_montage_multiple_sections_using_deployed_montager.m).


## Montaging of one section using precalculated point-matches with json: non-deployed solve
Use this if you already have precalculated point-matches. It perfoms a solve only.
A montage of a specific section (a set of tiles sharing the same z value) defined by "source_collection" and "section_number". This will  solve the registration problem using "solver_options", and persist the resulting transformations into the Renderer collection "target_collection". 

Usage: At the Matlab prompt:

[1] fn = 'full_path_to_json_configuration_file.json';  %% specify the input json file

[2] solve_montage_SL(fn); %% perform montage

If CATMAID dynamic rendering is set up, you can view your registered montage using a URL for example similar to this:
http://tem-services.int.janelia.org:8080/render-ws/view/stacks.html?owner=flyTEM&project=test&dynamicRenderHost=renderer:8080&catmaidHost=renderer-catmaid:8000



An example json input file is provided below.


```json

{
	"solver_options": {
		"min_tiles": 3,
		"degree": 1,
		"outlier_lambda": 1000,
		"solver": "backslash",
		"min_points": 3,
                "max_points": 20,
		"stvec_flag": 0,
		"conn_comp": 1,
		"distributed": 0,
		"lambda": 0.1,
		"edge_lambda": 0.1,
		"small_region_lambda": 10,
		"small_region": 5,
		"calc_confidence": 1,
		"translation_fac": 1,
                "use_peg": 1,
                "peg_weight": 0.0001,
                "peg_npoints": 5
	},
	"source_collection": {
		"stack": "v12_acquire_merged",
		"owner": "flyTEM",
		"project": "FAFB00",
		"service_host": "10.37.5.60:8080",
		"baseURL": "http://10.37.5.60:8080/render-ws/v1",
		"verbose": 1
	},
	"source_point_match_collection": {
		"server": "http://10.40.3.162:8080/render-ws/v1",
		"owner": "flyTEM",
		"match_collection": "v12_dmesh"
	},
	"target_collection": {
		"stack": "EXP_test_montage_solver_1",
		"owner": "flyTEM",
		"project": "test",
		"service_host": "10.37.5.60:8080",
		"baseURL": "http://10.37.5.60:8080/render-ws/v1",
		"verbose": 1,
                "initialize": 0,
                "complete": 1
	},
	"z_value": 1,
        "filter_point_matches": 1,
        "temp_dir":"/scratch/khairyk",
	"verbose": 1,
        "disableValidation": 0
}

```

## Montage a series of sections using Matlab directly and assuming precalculated point-matches
Use this if you already have precalculated point-matches. It perfoms a solve only.
Montage one or more sections. This will  solve the registration problem using "solver_options", and persist the resulting transformations into the Renderer collection "target_collection". 
See example below for montaging FAFB


```json

% solver options
disp('----only performing translation as regularizer');
sl.solver_options.translation_only = 1;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

sl.solver_options.degree                = 1;
sl.solver_options.solver                = 'backslash';
sl.solver_options.min_points            = 3;
sl.solver_options.max_points            = 50;
sl.solver_options.lambda                = 1e-1;              % regularization parameter
sl.solver_options.edge_lambda           = sl.solver_options.lambda;
sl.solver_options.translation_fac       = 1;
sl.solver_options.use_peg               = 1;                % peg
sl.solver_options.peg_weight            = 1e-5;             % peg
sl.solver_options.peg_npoints           = 50;                % peg
sl.solver_options.da                    = 0.1;

sl.solver_options.distributed           = 0;
sl.solver_options.min_tiles             = 3;
sl.solver_options.verbose               = 0;
sl.solver_options.nbrs                  = 0;
sl.solver_options.filter_point_matches  = 1;
sl.solver_options.dir_scratch           = '/scratch/khairyk';
sl.solver_options.verbose               = 0;


sl.solver_options.pmopts.NumRandomSamplingsMethod = 'Desired confidence';
sl.solver_options.pmopts.MaximumRandomSamples = 7000;
sl.solver_options.pmopts.DesiredConfidence = 99.5;
sl.solver_options.pmopts.PixelDistanceThreshold = 0.1;

% configure source collection
sl.source_collection.stack          = 'v12_acquire_merged';
sl.source_collection.owner          = 'flyTEM';
sl.source_collection.project        = 'FAFB00';
sl.source_collection.service_host   = '10.37.5.60:8080';
sl.source_collection.baseURL        = 'http://10.37.5.60:8080/render-ws/v1';
sl.source_collection.verbose        = 0;

% configure target collection
sl.target_collection.stack          = 'kk14_montage';
sl.target_collection.owner          = 'flyTEM';
sl.target_collection.project        = 'FAFBv14_kk';
sl.target_collection.service_host   = '10.37.5.60:8080';
sl.target_collection.baseURL        = 'http://10.37.5.60:8080/render-ws/v1';
sl.target_collection.versionNotes   = 'Created using script /nrs/flyTEM/khairy/FAFB00v13/matlab_production_scripts/Beautification_script_generate_all_montages.m';
sl.target_collection.verbose        = 0;
sl.target_collection.complete       = 0;
sl.target_collection.initialize     = 0;

% configure point-match collection(s)
clear pm;
pmix = 1;

pm(pmix).server = 'http://10.40.3.162:8080/render-ws/v1';
pm(pmix).owner  = 'flyTEM';
pm(pmix).match_collection = 'FAFB_pm_7';pmix = pmix + 1;

sl.source_point_match_collection = pm;

% other configurations
sl.z_value = 1;
sl.temp_dir = '/scratch/khairyk';
sl.dir_scratch = sl.temp_dir;
sl.verbose = 0;

temp_config_fn ='/nrs/flyTEM/khairy/FAFB00v14/matlab_production_scripts/sl.mat';
save (temp_config_fn, 'sl');

%% call solve_montage_SL for every section and save diagnostics
kk_clock;
failed = zeros(100,1);
save sl sl;
parfor ix = 1:7062
    c = load(temp_config_fn, 'sl');
    config = c.sl;
    config.z_value = ix;
    try
    solve_montage_SL(config);
    catch err_montage
        kk_disp_err(err_montage);
        failed(ix) = 1;
    end
end
               
resp = set_renderer_stack_state_complete(sl.target_collection); % complete the stack

kk_clock;
if sum(failed)
disp('Failed section list:');
disp(find(failed));
end
```


