#/bin/bash

#PBS -q emconnectome
#PBS -l walltime=01:00:00
#PBS -l nodes=1
#PBS -l pmem=10g
#PBS -N em_solver
#PBS -r n
#PBS -j oe
#PBS -o log/
#PBS -m a
#PBS -M danielk@alleninstitute.org

#make a directory for logging
logroot=/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/
mcr=/usr/local/MATLAB/MATLAB_Runtime/v91 #aloha
#mcr=/allen/aibs/pipeline/image_processing/volume_assembly/MATLAB_Runtime/v91 #qmaster

dirind=0
datedir=`date +%Y%m%d`
logdir=$logroot$datedir.$dirind
while [ -d "$logdir" ]; do
  dirind=$((dirind+1)) 
  logdir=$logroot$datedir.$dirind
done
mkdir $logdir
echo "creating: "$logdir

if [[ -v zval ]]; then
  #modify the input file for the section
  cat $input | sed "s/\"first_section\": [0123456789]*,/\"first_section\": $zval,/g" | sed "s/\"last_section\": [0123456789]*,/\"last_section\": $zval,/g" > $logdir/input.json
else
  cat $input > $logdir/input.json
fi

export EMA_RENDERBINPATH=/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts
export EMA_SERVICE_HOST=em-131fs:8080

#run the matlab with the input file as the argument

#affine
/allen/programs/celltypes/workgroups/em-connectomics/danielk/EM_aligner/allen_templates/run_system_solve_affine_with_constraint_SL.sh $mcr $logdir/input.json

#rigid (uniform scaling, rotation, translation)
#/allen/programs/celltypes/workgroups/em-connectomics/danielk/EM_aligner/allen_templates/run_system_solve_rigid_approximation_SL.sh $mcr $logdir/input.json

