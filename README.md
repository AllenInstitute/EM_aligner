# EM_aligner
A set of Matlab tools for aligning EM images into a coherent image volume in two and three dimensions. This library works in conjunction with the "Renderer" ecosystem of tools. 

## Status: 
In production use at Janelia. This is a nascent set of tools that is undergoing large changes and code cleanup. We consider the library suitable for use by our collaborators as well as other research groups. Due to limited staffing, we do not guarantee support for outside groups.

## Terminology and definitions:
-	Tile: an image acquired as part of a larger mosaic. A tile is assumed to be part raw image data and part meta-data.
-	Montage: a set of tiles with same z-coordinate value that have been registered.
-	Section: a set of tiles with same z-coordinate value.
-	Slab: a contiguous set of sections.
-	Collection (or Renderer collection): a database collection of tile metadata for a group of tiles that may or may not be part of a slab or section.
-	Rough alignment: rough registration of sections relative to each other across z.
-	Fine alignment: refined alignment of tiles within the same, and across, z.

## Prerequisites 
- 	Renderer and point-match services and dependencies: (available freely and documented here: https://github.com/saalfeldlab/render)
-	(Optional) Bash scripts dependent on a system call that launches a java process
	-	Client-side rendering: This is relevant to all steps requiring generation of point-matches; full section montage and cross-layer point-match generation.
	-	Rough section alignment: This script
	-	Point-match generation (two scripts)
-	Matlab 2016b and above, toolboxes: Computer Vision Systems (or Video and Blockset), ImageProcessing, Statistics, (optional) compiler and (optional) Parallel computing.



## Main steps for stitching small-to-moderate size datasets (less than 1M tiles):

Important:
For montage or cross-layer affine registration use "system_solve_affine_with_constraint.m". Usage is documented in the file.
This function requires a starting collection that will serve to constrain the affine solution (regularization). The typical way to obtain a good starting alignment is by solving your source collection using either system_solve_translation.m or system_solve_rigid_approximation.m. Neither of them requires (or makes use of) a starting guess, they only need the source tiles (Renderer collection) and of course a good point-match collection.

![Alt text](https://github.com/khaledkhairy/EM_aligner/blob/master/doc/stitching_strategy_small_volume.jpg "stitching_schematic (small datasets)")
- 	[Install Renderer and point-match services](https://github.com/saalfeldlab/render) and dependencies as indicated above
-	Ingest image metadata:
	-	See rules and assumptions for tile-spec ingestion (coming soon)
-	[Montage registration](doc/doc_montage.md) of every section (tiles with same z-coordinate value)	
-	[Rough alignment](doc/doc_rough.md) of montage collection
-	Fine alignment
	-	Run point-match generation across layers
	-	[Run full volume solve](doc/doc_fine.md) of (rough) collection
-	[Diagnostics](doc/doc_diagnostics.md) information for any section, set of sections or entire collection.
-	[Patching/spot-correction] (doc/doc_spot_correction.md) for local alignment issues.
-	Post-stitching steps (Render images, intensity correction and CATMAID staging) will not be described here.



## Steps relevant to large datasets (more than 1M tiles):

![Alt text](https://github.com/khaledkhairy/EM_aligner/blob/master/doc/stitching_strategy_large_volume.jpg "stitching_schematic (large datasets)")
- 	[Install Renderer and point-match services](https://github.com/saalfeldlab/render) and dependencies as indicated above
-	Ingest image metadata:
	-	See rules and assumptions for tile-spec ingestion (coming soon)
-	Run montage of every section (same z-coordinate value)
- 	Slab definition for rough alignment
-	Run rough alignment of montage collection
-	Run point-match generation across layers
-	(Optional) fuse rough slabs. 
-	(Optional) redefine slabs for fine alignment
-	Run individual slab solve
-	Fuse fine slabs. Limitation: works for affine only.
-	Post-stitching steps (Render images, intensity correction and CATMAID staging) will not be described here.

## Independent tools
-	[Solve montage without point-match generation](doc/doc_solve_montage.md), for testing and optimizing solver parameters.
-	Solve slab without point-match generation, for optimizing solver parameters.
-	Slab beautification: runs the full "small-volume"-pipeline described above on a limited slab with the aim of fixing local issues data issues detected while proofreading the final volume. In that (advanced) mode, the user is encouraged to experiment with different SURF parameters, other feature detectors, point-match filter parameters, or solver parameters. This mode is also used to re-stitch a slab of sections for which meta-information was incorrect or deficient, leading to poor point-matches in that region. At the end, the procedure will insert the re-stitched slab into the larger full collection. Limitation: assumes affine transformations throughout.

## Recipes
-	You need to instantiate a section object, optionally do something with it,  and then ingest into a destination collection. Before ingestion it is sometimes a good idea to make sure no tiles with this same z exist in the destination collection.
```json
> L = Msection(rc_source, z); % read the section with z-value z
> resp = delete_renderer_section(rc_destination, z);% optionally delete the section from destination before ingesting
> resp = ingest_section_into_renderer_database(L, rc_destination, rc_source, dir_temp, 1);
```


-	If you need to produce a "translation-only" collection, find this example below:

```json
nfirst= 1;
nlast = 20948;
% configure source
rcsource.stack          = 'v1_acquire';
rcsource.owner          ='hessh';
rcsource.project        = 'tomoko_Santomea11172016_04_A3_T1';
rcsource.service_host   = '10.40.3.162:8080';
rcsource.baseURL        = ['http://' rcsource.service_host '/render-ws/v1'];
rcsource.verbose        = 1;

% configure translation-only alignment
rctranslation.stack          = ['TOS_tomoko_Santomea11172016_04_A3_T1_' num2str(nfirst) '_' num2str(nlast) '_translation'];
rctranslation.owner          ='hessh';
rctranslation.project        = 'tomoko_Santomea11172016_04_A3_T1';
rctranslation.service_host   = '10.40.3.162:8080';
rctranslation.baseURL        = ['http://' rctranslation.service_host '/render-ws/v1'];
rctranslation.verbose        = 0;

% configure fine alignment
rcfine.stack          = ['TOS_tomoko_Santomea11172016_04_A3_T1_' num2str(nfirst) '_' num2str(nlast) '_fine'];
rcfine.owner          ='hessh';
rcfine.project        = 'tomoko_Santomea11172016_04_A3_T1';
rcfine.service_host   = '10.40.3.162:8080';
rcfine.baseURL        = ['http://' rcfine.service_host '/render-ws/v1'];
rcfine.verbose        = 0;
pm.server = 'http://10.40.3.162:8080/render-ws/v1';
pm.owner = 'zlaticm';
pm.match_collection = 'tomoko_Santomea11172016_04_A3_T1';
dir_scratch = '/scratch/khairyk';
kk_clock();



%% produce a translation-only stack

opts.min_tiles = 1; % minimum number of tiles that constitute a cluster to be solved. Below this, no modification happens
opts.degree = 0;    % 1 = affine, 2 = second order polynomial, maximum is 3
opts.outlier_lambda = 1e3;  % large numbers result in fewer tiles excluded
opts.lambda = 1e5;
opts.edge_lambda = opts.lambda;
opts.solver = 'backslash';
opts.min_points = 5;
opts.max_points = 50;
opts.nbrs = 10;
opts.xs_weight = 1;
opts.stvec_flag = 0;   % i.e. do not assume rcsource providing the starting values.

opts.use_peg = 0;
opts.complete = 1;
opts.disableValidation = 1;
opts.apply_scaling = 1;
opts.scale_fac = 1.0;
opts.translation_only = 1;
opts.translate_to_origin = 1;

[L]  = load_point_matches(nfirst, nlast,...
       rcsource, pm, opts.nbrs, opts.min_points, opts.xs_weight);
               
[L2] = get_rigid_approximation(L, opts.solver, opts);

ingest_section_into_renderer_database(L2,rctranslation, rcsource, pwd,...
            opts.translate_to_origin, opts.complete, opts.disableValidation);
```
