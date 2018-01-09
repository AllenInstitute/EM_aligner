import renderapi
from multiprocessing import Process
import numpy as np
import time

xmin = 200000
xmax = 250000
ymin = 200000
ymax = 250000
zmin = 1015
zmax = 1016

#what type of copy
njobs=8
copy_stack=True
#source_name = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2'
#source_owner='gayathri'
source_project = 'Reflections'
source_name='Secs_1015_1099_5_reflections'
source_owner='danielk'

target_project = 'Seams'
target_name = 'Substack_x_%d_%d_y_%d_%d'%(xmin,xmax,ymin,ymax)
target_owner= 'danielk'

scripts = '/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts/'

#define source and target
render_source_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':source_owner,
    'project':source_project,
    'client_scripts':scripts,
    'memGB':'2G'
}
render_target_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':target_owner,
    'project':target_project,
    'client_scripts':scripts,
    'memGB':'2G'
}
render_source = renderapi.connect(**render_source_params)
render_target = renderapi.connect(**render_target_params)

if copy_stack:
    print 'reading source stack z values'
    copylist = renderapi.stack.get_z_values_for_stack(source_name,render=render_source)
    copylist = np.array(copylist)
    copylist = copylist[(copylist>=zmin)&(copylist<=zmax)]

    print 'creating target stack'
    renderapi.stack.create_stack(target_name,render=render_target)

#parallel process function
def copyjob(sub_list,source,target,rsource_par,rtarg_par):
    render_source = renderapi.connect(**rsource_par)
    render_target = renderapi.connect(**rtarg_par)
    for iel in sub_list:
        #read in the tile specs of pointmatches
        if copy_stack:
            trans = renderapi.tilespec.get_tile_specs_from_min_max_box(source,iel,xmin,ymin,xmax,ymax,render=render_source)
    return len(sub_list)

##split up the list and copy in parallel
nperjob = float(len(copylist))/njobs
jobs=[] 
last=0
while last<len(copylist):
    lmin=last
    lmax=int(last+nperjob)
    last = lmax
    njobs = njobs-1
    if njobs!=0:
        nperjob = float(len(copylist[last:]))/njobs
    else:
        nperjob = len(copylist[last:])
    print lmin,lmax,lmax-lmin
    job = Process(target=copyjob,args=(copylist[lmin:lmax],source_name,target_name,render_source_params,render_target_params))
    jobs.append(job)
    job.start()

#def running(joblist):
#    codes=[]
#    for job in jobs:
#        codes.append(job.exitcode)
#    return any(x==None for x in codes)
#
#while running(jobs):
#    time.sleep(3)
#
#if copy_stack:
#    renderapi.stack.set_stack_state(target_name, 'COMPLETE', render = render_target)
#
