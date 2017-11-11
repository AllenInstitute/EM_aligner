import numpy as np
import renderapi
from multiprocessing import Process,Pool
import time
import matplotlib.pyplot as plt

#parallel process function
def stack_copyjob(args):
    zin = args[0]
    zout = args[1]
    source = args[2]
    target = args[3]
    rsource_par = args[4]
    rtarg_par = args[5]

    render_source = renderapi.connect(**rsource_par)
    render_target = renderapi.connect(**rtarg_par)

    #read in the original section tilespecs    
    resolved_t = renderapi.resolvedtiles.get_resolved_tiles_from_z(source,zin,render=render_source)
    tids = []
    for t in resolved_t.tilespecs:
        tids.append(t.tileId)
    #write to the new ones
    for j in np.arange(len(zout)):
        for k in np.arange(len(resolved_t.tilespecs)):
            resolved_t.tilespecs[k].z=zout[j]
            resolved_t.tilespecs[k].layout.sectionId='%0.1f'%zout[j]
            if j!=0:
                resolved_t.tilespecs[k].tileId = tids[k]+'.c%d'%j
        renderapi.client.import_tilespecs(target,resolved_t.tilespecs,sharedTransforms=resolved_t.transforms,render=render_target)

if __name__== '__main__':
    #what type of copy
    ncpus=8
    nsections=5
    nreflections=3

    source_name = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2'
    source_owner='gayathri'

    target_name = 'reflected2'
    target_owner= 'danielk'
    
    
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
    
    #prepare for reflecting stack
    print 'reading source stack z values'
    copylist = renderapi.stack.get_z_values_for_stack(source_name,render=render_source)
    copylist = np.array(copylist[0:nsections])
    print 'creating target stack'
#    renderapi.stack.create_stack(target_name,render=render_target)
    
    #old and new z values
    origlist = np.copy(copylist)
    newzlist = np.copy(origlist)
    for i in np.arange(nreflections):
        origlist = np.append(origlist, copylist[::np.power(-1,i+1)][1:])
        while(len(newzlist)<len(origlist)):
            newzlist = np.append(newzlist,newzlist[-1]+1)    
    
    #setup a copy job for each original section
    unz = np.unique(origlist)
    args = []
    for iz in unz:
        ind = np.argwhere(origlist==iz).flatten()
        args.append([iz,newzlist[ind],source_name,target_name,render_source_params,render_target_params])

    #start the jobs
#    pool = Pool(processes=ncpus)
#    tmp = pool.map(stack_copyjob, args)
#    pool.terminate()

    #close the new stack
#    renderapi.stack.set_stack_state(target_name, 'COMPLETE', render = render_target)

    #make a new point match collection for the new stack
    source_collection = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine'
    collection_owner = 'gayathri_MM2'

#    pmgroups = np.array(renderapi.pointmatch.get_match_groupIds(source_collection,render=render_source,owner=collection_owner)).flatten().astype('float').astype('int')
#    pmatches = []
#    for z1 in unz:
#        pmrow = []
#        for z2 in unz:
#            if z1==z2:
#                pmrow.append(renderapi.pointmatch.get_matches_within_group(source_collection,'%0.1f'%float(z1),render=render_source,owner=collection_owner))
#            elif (z1<z2):
#                pmrow.append(renderapi.pointmatch.get_matches_from_group_to_group(source_collection,'%0.1f'%float(z1),'%0.1f'%float(z2),render=render_source,owner=collection_owner))
#            else:
#                pmrow.append([]) 
#            print z1,z2,len(pmrow[-1])
#        pmatches.append(pmrow)

    cnt = np.zeros((len(newzlist),len(newzlist))).astype('int')
    #cycle through columns
    for i in np.arange(len(unz)):
        for j in np.arange(i+1):
            cnt[j,i] = len(pmatches[j][i])
            cnt[i,j] = cnt[j,i]
            print i,j,cnt[i,j]
            
    plt.figure(1)
    plt.clf()
    plt.imshow(cnt,interpolation='nearest',cmap='gist_heat')
    plt.colorbar()
    plt.gca().set_xticks(np.arange(len(newzlist)))
    plt.gca().set_xticklabels(origlist)
    plt.gca().set_yticks(np.arange(len(newzlist)))
    plt.gca().set_yticklabels(origlist)

    
