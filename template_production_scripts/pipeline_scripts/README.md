# Building the binaries

Before building the binaries make sure that your matlab environment variables is set properly.

`
export matlabroot="/usr/local/matlab-2016a"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:\
$matlabroot/bin/glnxa64:\
$matlabroot/runtime/glnxa64:\
$matlabroot/sys/os/glnxa64:\
$matlabroot/sys/java/jre/glnxa64/jre/lib/amd64/native_threads:\
$matlabroot/sys/java/jre/glnxa64/jre/lib/amd64/server:\
$matlabroot/sys/java/jre/glnxa64/jre/lib/amd64"
export XAPPLRESDIR="$matlabroot/X11/app-defaults"
export MCR_INHIBIT_CTF_LOCK=0
`

Then simply run:
     `make`

If you want to build only a specific tool you can run `make target` where target_name
is one or more from the list:

* generate\_diagnostic\_stats
* Register\_montage
* Register\_fine
* Register\_rough
* Collection\_fusion
* generate\_slab\_definitions

For example to build Register\_fine and Register\_rough you can run:

    `make Register_rough Register_fine`

# Running the compiled binaries

If you want to run the binaries directly you need to have the matlab toolbox libraries in your LD\_LIBRARY\_PATH so you need to set your environment just as if you compile these tools. The main advantage of compiling the tools is that the matlab licenses are only needed at compile time and after that you are no longer constraint by the available licenses


## Running Register_montage

### Command line:

`
bin/Register_montage start_section end_section json_options_file
`

### Parameters:
* start\_section - first section to register.
* end\_section - last section to register.
* json\_options\_file - JSON config file containing source, target, point match and solver options

### JSON Config parameters for Register_montage:
* rs\_acq\_collection - defines the parameters of the acquisition collection - the source collection, where the
parameters are  renderer service connection parameters: renderer service URL, owner name, project name, collection name:

```
    "rs_acq_collection": {
       "service_host": "10.40.3.162:8080",
       "stack": "v12_acquire",
       "project": "FAFB00",
       "owner": "flyTEM",
       "verbose": 1
    }
```

* rs\_montage\_collection - defines the parameters of target collection that results after tiles are assembled into a montage

```
    "rs_montage_collection": {
        "service_host": "10.40.3.162:8080",
        "stack": "v12_montage",
        "project": "FAFB00",
		"owner": "flyTEM",
		"verbose": 1
	},
```

* pm\_opts - defines the point match collection parameters: service URL, collection owner and collection name; pm\_opts also contains 
a parameter _verbose_ which specify the level of verbosity (the higher the value the more verbose and 0 means no log information)

```
	"pm_opts": {
		"server": "http://10.40.3.162:8080/render-ws/v1",
		"match_collection": "v12_acquire_merged_sift",
		"owner": "flyTEM",
		"verbose": 4
	},
```

* solver\_opts - solver options
  - min\_tiles  minimum number of tiles that constitute a cluster to be solved. Below this no modification happens.
  - degree solvers polynomial degree: 1 - affine, 2 - second order polynomial
  - outlier\_lambda - the higher the value the fewer tiles get excluded (default value 1e1
  - lambda - default value 0.1
  - edge\_lambda - default value 0.1
  - solver - default 'backslash'
  - min\_points
  - max\_points
  - nbrs - number of cross section used - which for montage should be 0
  - xs\_weight
  - stvec\_flag - 0 if no initial solution approximation is given, 1 if an initial solution approximation is provided
  - conn\_comp
  - filter\_pm - flag that specifies whether the point match filter should be applied or not.
  - use\_peg - flag that specifies whether pegs should be used
  - peg\_weight - default peg weight 1e-4
  - peg\_npoints - number of pegs - defaults to 5
  
* pm\_filter\_opts - parameters used by the point match RANSAC filter if solver\_opts.filter\_pm is true
  - NumRandomSamplingsMethod - default method is "Desired confidence"
  - MaximumRandomSamples - default value 3000
  - DesiredConfidence - typical values are between 99.5 and 99.9
  - PixelDistanceThreshold - typical values are between 0.001 and 1.0

e.g.
Run montage for sections 1 to 50 using the options defined in stitching_options.json

`
bin/Register_montage 1 50 stitching_options.json
`

## Generate slab definitions (generate\_slab\_definitions)

### Command line:

`
bin/generate_slab_definitions start_section end_section json_slab_rule
`

### Parameters:
* start\_section - start section
* end\_section - end section
* json\_slab\_rule - json file containing rules regarding the slab creation such as slab thickness, 
  slap overlap, min\_scale, max\_scale as well as the start collection that must be partition into slabs and
  a rule for naming the target slabs
  
Example json slab rule file:

```
{
    "rs_source": {
        "service_host": "10.40.3.162:8080",
        "stack": "v14_montage",
		"owner": "flyTEM",
		"project": "goinac_FAFB00",
		"verbose": 1
	},
	"rs_target": {
	    "service_host": "10.40.3.162:8080",
		"stack_pattern": "v14_rough_<si>",
		"owner": "flyTEM",
		"project": "goinac_FAFB00",
		"verbose": 1
	},
	"thickness": 50,
	"overlap": 10,
	"max_image_area": "1.575*10^8",
	"min_scale": 0.02,
	"max_scale": 0.1
=}
```

## Running Register_rough

### Command line:

`
bin/Register_rough slabs json_slab_definitions rough_slabs_dir store_dir json_options_file
`

### Parameters:
* slabs - array of slabs to be rough aligned
* json\_slab\_definitions - JSON file that contains the slab definitions. This file can be generated using generate\_slab\_definitions
  or it can be created manually.
* rough\_slabs\_dir - directory to store serialized rough slab matrices
* store\_dir - directory used for intermediate results (defaults to '/nobackup/flyTEM/khairy/FAFB00v13/montage\_scape\_pms')
* json\_options\_file - JSON config file


### JSON Config parameters for Register_rough:
* rs\_acq\_collection - defines the parameters of the acquisition collection - the source collection, where the
parameters are  renderer service connection parameters: renderer service URL, owner name, project name, collection name:
* rs\_montage\_collection - defines the parameters of target collection that results after tiles are assembled into a montage
* montage\_scape\_options - rough align options
  - fd\_size
  - min\_sift\_scale
  - max\_sift\_scale
  - steps
  - similarity\_range
  - skip\_similarity\_matrix
  - skip\_aligned\_image\_generation
  - base\_output\_dir - base spark job directory
  - script - script ran by the spark job
* default\_rs - defines default render server connectivity that is used as part of the slab definition if the slabs definitions do not
  contain the renderer server information - in other words in some way it denormalizes the renderer service connectivity information.

e.g.
Run rough alignment for slabs 1 to 10 using the stitching_options.json and the slabs defined in rough_slab_defs.json

`
bin/Register_rough "1:10" rough_slab_defs.json "" stitching_options.json
`

## Running Register_fine

### Command line:

`
bin/Register_fine slabs json_slab_definitions slabs_dir json_options_file
`

### Parameters:
* slabs - array of slabs to be rough aligned
* json\_slab\_definitions - JSON file that contains the slab definitions
* slabs\_dir - directory used for storing solved slabs (defaults to '/nobackup/flyTEM/khairy/FAFB00v13/matlab_slabs')
* json\_options\_file - JSON config file

e.g.
Run fine alignment for slabs 1 to 10 using fine_slabs_def.json and stitching_options.json

`
bin/Register_fine "1:10" fine_slabs_def.json "" stitching_options.json
`

## Running Collection_fusion

### Command line:

`
bin/Collection_fusion start_slab end_slab json_slab_definitions json_options_file
`

### Parameters:
* start_slab - first slab to fuse.
* end_slab - last slab to fuse.
* json\_slab\_definitions - JSON file that contains the slab definitions
* json\_options\_file - JSON config file

e.g.
`
bin/Collection_fusion 2 78 fine_slabs_def.json stitching_options.json
`

## Running generate\_diagnostic\_stats

### Command line:

`
bin/generate_diagnostic_stats zstart zend todo json_options_file
`

### Parameters:
* zstart - first section to be checked - defaults to 1
* zend - last section to be checked - defaults to 7062
* todo - specifies what stats to generate - defaults to 15
* json\_options\_file - JSON config file

_todo_ is a bitwise value that specifes what data to generate. The meaning of the bits is the following:

	- 0x1 - generate the area and perimeter median plots
	- 0x2 - save diagnostic data table in a CSV file
	- 0x4 - generate the residual diagrams
	- 0x8 - generate the deformation diagrams

The default value for _todo_ is 15, i.e., generate all stats that it can generate

e.g.
Generate the area and perimeter plots for the first 20 sections from 'FULL_FAFB_FUSED' and also
save the diagnostic data in a CSV file.

`
bin/generate_diagnostic_stats 1 20 3 stitching_options.json
`


##JSON configuration example:

`
{
	"default_rs": {
        "service_host": "10.40.3.162:8080",
        "project": "goinac_FAFB00",
        "owner": "flyTEM",
        "verbose": 1
    },
    "rs_acq_collection": {
        "service_host": "10.40.3.162:8080",
        "stack": "v12_acquire_merged",
        "project": "FAFB00",
        "owner": "flyTEM",
        "verbose": 1
    },
    "rs_montage_collection": {
        "service_host": "10.40.3.162:8080",
        "stack": "v14_montage_1196_1197",
        "project": "goinac_FAFB00",
		"owner": "flyTEM",
		"verbose": 1
	},
	"pm_opts": {
		"server": "http://10.40.3.162:8080/render-ws/v1",
		"match_collection": "v12_acquire_merged_sift_1196_1197",
		"owner": "flyTEM",
		"verbose": 4
	},
	"pm_filter_opts": {
	    "NumRandomSamplingsMethod": "Desired confidence",
		"MaximumRandomSamples": 10,
		"DesiredConfidence": 99.9,
	    "PixelDistanceThreshold": 1
	},
	"montage_scape_options": {
		"min_sift_scale": "0.2",
		"max_sift_scale": "1.0",
		"steps": "3",
		"similarity_range": "15",
		"skip_similarity_matrix": "y",
		"skip_aligned_image_generation": "y",
		"base_output_dir": "/nobackup/flyTEM/spark_montage",
		"script": "/groups/flyTEM/home/khairyk/EM_aligner/renderer_api/generate_montage_scape_point_matches.sh",
		"number_of_spark_nodes": "2.0"
	},
	"solver_opts": {
		"min_tiles": "2",
		"degree": "1",
		"outlier_lambda": "1e1",
		"lambda": "10^(-1)",
		"edge_lambda": "10^(-1)",
		"solver": "backslash",
		"min_points": "3",
		"nbrs": "2",
		"xs_weight": "1/100",
		"stvec_flag": "0",
		"distributed": "1",
		"conn_comp": "1",
		"filter_pm": "1",
		"use_peg": "1",
		"peg_weight": "1e-4",
		"peg_npoints": "5"
	},
	"rs_rough_collection": {
		"service_host": "10.40.3.162:8080",
		"stack": "v14_rough_1196_1197",
		"project": "goinac_FAFB00",
		"owner": "flyTEM",
		"verbose": 1
	},
	"rs_fused_collection": {
		"service_host": "10.40.3.162:8080",
		"stack": "v14_fine_1196_1197",
		"project": "goinac_FAFB00",
		"owner": "flyTEM",
		"verbose": 1,
		"nworkers": 0,
		"cluster_profile": "",
		"grid_account": "",
		"grid_user": ""
	},
	"stats_options": {
		"service_host": "10.40.3.162:8080",
		"stack": "v14_fine_1196_1197",
		"project": "goinac_FAFB00",
		"owner": "flyTEM",
		"verbose": 1
	},
	"verbose": true
}
`
