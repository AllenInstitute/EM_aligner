from pymongo import MongoClient
import numpy as np
import renderapi
import multiprocessing as mp
import time
from matplotlib.collections import LineCollection
import matplotlib.pyplot as plt
import sys
import requests

#parallel process function
def stack_copyjob(args):
    zin = args[0]
    source = args[1]
    target = args[2]
    rsource_par = args[3]
    rtarg_par = args[4]
    xybounds = args[5]

    render_source = renderapi.connect(**rsource_par)
    render_target = renderapi.connect(**rtarg_par)

    #read in the original section tilespecs    
    sourcetiles = renderapi.tilespec.get_tile_specs_from_minmax_box(source,zin,xybounds[0],xybounds[1],xybounds[2],xybounds[3],render=render_source)

    #write to the new one
    renderapi.client.import_tilespecs(target,sourcetiles,render=render_target)

if __name__== '__main__':
    #what type of copy
    ncpus=mp.cpu_count()
    xmin = 0
    xmax = 240000
    ymin = 0
    ymax = 80000
    zmin = 1023
    zmax = 1024

    makenewstack = True

    #source stack
    source_name = "mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Rough_rev1039_v2"
    source_project = 'MM2'
    source_owner='gayathri'
    #target stack
    target_name = 'Substack_x_%d_%d_y_%d_%d'%(xmin,xmax,ymin,ymax)
    target_project = 'Seams'
    target_owner= 'danielk'

    #render
    scripts = '/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts/'
    #define source and target
    render_source_params ={
        'host':'em-131fs',
        'port':8080,
        'owner':source_owner,
        'project':source_project,
        'client_scripts' : scripts,
        'memGB':'2G'
    }
    render_target_params ={
        'host':'em-131fs',
        'port':8080,
        'owner':target_owner,
        'project':target_project,
        'client_scripts' : scripts,
        'memGB':'2G'
    }
    render_source = renderapi.connect(**render_source_params)
    render_target = renderapi.connect(**render_target_params)

    #prepare for copying subsection of stack
    print 'reading source stack z values'
    zsource = np.array(renderapi.stack.get_z_values_for_stack(source_name,render=render_source))
    copylist = zsource[(zsource>=zmin)&(zsource<=zmax)]
    
    #make a client to the db
    client = MongoClient("em-131fs:27017")

    if makenewstack: 
        db = client.render
        mongo_name = render_target_params['owner']+'__'+render_target_params['project']+'__'+target_name+'__tile'
        if mongo_name in db.collection_names():
            print 'target stack:\n%s\nalready exists. This script does not overwrite.'%mongo_name
        else:
            print 'creating target stack:\n%s'%mongo_name
            renderapi.stack.create_stack(target_name,render=render_target)
  
            #setup the arguments for the different jobs
            args = []
            for iz in copylist:
                bounds = [xmin,xmax,ymin,ymax]
                args.append([iz,source_name,target_name,render_source_params,render_target_params,bounds])

            #start the jobs
            pool = mp.Pool(processes=ncpus)
            tmp = pool.map(stack_copyjob, args)
            pool.terminate()

            #close the new stack
            renderapi.stack.set_stack_state(target_name, 'COMPLETE', render = render_target)

