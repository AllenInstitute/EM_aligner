## Prerequisites
We are assuming that the Renderer and point-match services (and associated database) are set up and accessible for example at http://tem-services.int.janelia.org.
Also, you are using Matlab 2016b and above with toolboxes: Computer Vision Systems (or Video and Blockset), ImageProcessing, Statistics, (optional) Matlab compiler and (optional) Parallel computing. The EM_aligner directory and subdirectories are on your Matlab path.

Additional assumptions:
[1] A Renderer collection of montaged (contiguous) sections exists. Separation in z between these sections should be small enough that features can be detected across sections.
[2] A spark process is set up so that the shell script "generate_montage_scape_point_matches.sh" can be found and run. 
## Option 1: Rough alignment using SIFT point-matches runs within a Matlab session, but depends on external Java code for point-matching between montage scapes

Rough allignment across montaged sections for a specified range of z values. Calls external Java code to determine point-matches between montage sections, then solves the registration problem for montage scapes using these point-matches, applies the resulting transformation to all tiles in the montage collection within the specified z range, and persists the resulting transformations into a "rough-aligned" Renderer collection. 

Useage:
Open Matlab, make a copy of (and edit the configuration section of) the file: $EM_aligner/test_scripts/rough_align_example.m

After editing, run your new script file.

If CATMAID dynamic rendering is set up, you can view your rough alignment using a URL for example similar to this:
http://tem-services.int.janelia.org:8080/render-ws/view/stacks.html?owner=flyTEM&project=test&dynamicRenderHost=renderer:8080&catmaidHost=renderer-catmaid:8000

Rough alignment result should be very close to the expected final fine-align quality.


## Option 2: (In progress) Rough alignment without external script. 
Runs exclusively in Matlab using SURF point-matches and uses the Renderer API to generate montage-scapes as "boxes", where the box is defined by the box around a section. This is still under development.





