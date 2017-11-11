import renderapi
from multiprocessing import Process
import time

#what type of copy
njobs=8
copy_stack=True
#source_name = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2'
#source_owner='gayathri'
source_name='tmp'
source_owner='danielk'
target_name = 'tmp'
target_owner= 'notreal'

copy_pmc=False
#source_name = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine'
#source_owner='gayathri_MM2'
#target_name = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_DK'

#define source and target
render_source_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':source_owner,
    'project':'MM2',
    'client_scripts':'/home/danielk/usr/render/render-ws-java-client/src/main/scripts/',
    'memGB':'2G'
}
render_target_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':target_owner,
    'project':'MM2',
    'client_scripts':'/home/danielk/usr/render/render-ws-java-client/src/main/scripts/',
    'memGB':'2G'
}
render_source = renderapi.connect(**render_source_params)
render_target = renderapi.connect(**render_target_params)

if copy_stack:
    print 'reading source stack z values'
    copylist = renderapi.stack.get_z_values_for_stack(source_name,render=render_source)
    print 'creating target stack'
    renderapi.stack.create_stack(target_name,render=render_target)
elif copy_pmc:
    print 'reading source pm collection group IDs'
    copylist = renderapi.pointmatch.get_match_groupIds(source_name,render=render_source)

#parallel process function
def copyjob(sub_list,source,target,rsource_par,rtarg_par):
    render_source = renderapi.connect(**rsource_par)
    render_target = renderapi.connect(**rtarg_par)
    for iel in sub_list:
        #read in the tile specs of pointmatches
        if copy_stack:
            trans = renderapi.tilespec.get_tile_specs_from_z(source,iel,render=render_source)
        elif copy_pmc:
            trans = renderapi.pointmatch.get_matches_with_group(source,iel,render=render_source)
    
        #write out the tile specs
        if copy_stack:
            renderapi.client.import_tilespecs(target,trans,render=render_target)
        elif copy_pmc:
            renderapi.pointmatch.import_matches(target,trans,render=render_target)
    return len(sub_list)

#split up the list and copy in parallel
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

def running(joblist):
    codes=[]
    for job in jobs:
        codes.append(job.exitcode)
    return any(x==None for x in codes)

while running(jobs):
    time.sleep(3)

if copy_stack:
    renderapi.stack.set_stack_state(target_name, 'COMPLETE', render = render_target)

