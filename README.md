# EM_aligner
A set of Matlab tools for aligning EM images into a coherent image volume in two and three dimensions. This library works in conjunction with the "Renderer" ecosystem of tools. 

##Status: 
In production use at Janelia. This is a nascent set of tools that is undergoing large changes and code cleanup. We consider the library suitable for use by our collaborators as well as other research groups. Due to limited staffing, we do not guarantee support for outside groups.

##Terminology and definitions:
-	Tile: an image acquired as part of a larger mosaic. A tile is assumed to be part raw image data and part meta-data.
-	Montage: a set of tiles with same z-coordinate value that have been registered.
-	Section: a set of tiles with same z-coordinate value.
-	Slab: a contiguous set of sections.
-	Collection (or Renderer collection): a database collection of tile metadata for a group of tiles that may or may not be part of a slab or section.
-	Rough alignment: rough registration of sections relative to each other across z.
-	Fine alignment: refined alignment of tiles within the same, and across, z.

##Prerequisites 
- 	Renderer and point-match services and dependencies: (available freely and documented here: https://github.com/saalfeldlab/render)
-	(Optional) Bash scripts dependent on a system call that launches a java process
	-	Client-side rendering: This is relevant to all steps requiring generation of point-matches; full section montage and cross-layer point-match generation.
	-	Rough section alignment: This script
	-	Point-match generation (two scripts)
-	Matlab 2016b and above, toolboxes: Computer Vision Systems (or Video and Blockset), ImageProcessing, Statistics, (optional) compiler and (optional) Parallel computing.



##Main steps for stitching small-to-moderate size datasets (less than 1M tiles):

![Alt text] (https://github.com/khaledkhairy/EM_aligner/blob/master/doc/stitching_strategy_small_volume.jpg "stitching_schematic (small datasets)")
- 	[Install Renderer and point-match services] (https://github.com/saalfeldlab/render) and dependencies as indicated above
-	Ingest image metadata:
	-	See rules and assumptions for tile-spec ingestion (coming soon)
-	[Montage registration] (doc/doc_montage.md) of every section (tiles with same z-coordinate value)	
-	[Rough alignment] (doc/doc_rough.md) of montage collection
-	Fine alignment
	-	Run point-match generation across layers
	-	[Run full volume solve] (doc/doc_fine.md) of (rough) collection
-	[Diagnostics] (doc/doc_diagnostics.md) information for any section, set of sections or entire collection.
-	Post-stitching steps (Render images, intensity correction and CATMAID staging) will not be described here.



##Steps relevant to large datasets (more than 1M tiles):

![Alt text] (https://github.com/khaledkhairy/EM_aligner/blob/master/doc/stitching_strategy_large_volume.jpg "stitching_schematic (large datasets)")
- 	[Install Renderer and point-match services] (https://github.com/saalfeldlab/render) and dependencies as indicated above
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

##Independent tools
-	[Solve montage without point-match generation] (doc/doc_solve_montage.md), for testing and optimizing solver parameters.
-	Solve slab without point-match generation, for optimizing solver parameters.
-	Slab beautification: runs the full "small-volume"-pipeline described above on a limited slab with the aim of fixing local issues data issues detected while proofreading the final volume. In that (advanced) mode, the user is encouraged to experiment with different SURF parameters, other feature detectors, point-match filter parameters, or solver parameters. This mode is also used to re-stitch a slab of sections for which meta-information was incorrect or deficient, leading to poor point-matches in that region. At the end, the procedure will insert the re-stitched slab into the larger full collection. Limitation: assumes affine transformations throughout.

