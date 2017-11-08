/home/danielk/cgmemtime/cgmemtime \
matlab -nojvm -nosplash -nodisplay -r "startup; \
matfilename = '/allen/programs/celltypes/workgroups/em-connectomics/danielk/EM_aligner/breakpoints/$1'; \
newstackname='$2'; \
run_from_mat; \
exit" \
> $1_$2.profcgm 2>&1
