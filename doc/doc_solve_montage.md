## Prerequisites
We are assuming that the Renderer and point-match services (and associated database) are set up and accessible for example at http://tem-services.int.janelia.org.
Also, you are using Matlab 2015a and above with toolboxes: Computer Vision Systems (or Video and Blockset), ImageProcessing, Statistics, (optional) Matlab compiler and (optional) Parallel computing. The EM_aligner directory and subdirectories are on your Matlab path.

## Solve one section using point-matches that have been generated before

A montage-solve only of a specific section (a set of tiles sharing the same z value) defined by "source_collection" and "z_value" will use precalculated point-matches "source_point_match_collection" between tile pairs, and solve the registration problem using "solver_options". After solving it will persist the resulting transformations into the Renderer collection "target_collection". 

at the Matlab prompt:

[1] fn = 'full_path_to_json_configuration_file.json';  %% specify the input json file

[2] solve_montage_SL(fn); %% perform montage solve

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
		"min_points": 10,
        "max_points": 100,
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
		"match_collection": "eric_test_sift"
	},
	"target_collection": {
		"stack": "Revised_slab_525_545_montage_SURF_eric",
		"owner": "flyTEM",
		"project": "FAFB00_beautification",
		"service_host": "10.37.5.60:8080",
		"baseURL": "http://10.37.5.60:8080/render-ws/v1",
		"verbose": 1,
        "initialize": 0,
        "complete": 1
	},
	"z_value": 525,
    "filter_point_matches": 1,
    "temp_dir":"/scratch/khairyk",
	"verbose": 1
}

```
## Solve montage using deployed application
Under directory matlab_compiled, open the file "compile_solve_montage" for editing.
Edit lines 4 and 5 and run the script.
Now the compiled output executable can be called from a the shell (or used in a qsub system) by passing it the path to the json input file without need for checking out Matlab licenses.
For example at the bash shell run:
$EM_aligner_path/matlab_compiled/solve_montage_SL $EM_aligner_path/Experiments/solve_montage_input_FAFB00_525.json




