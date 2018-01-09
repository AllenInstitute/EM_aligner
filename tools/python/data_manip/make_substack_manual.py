from pymongo import MongoClient
import numpy as np
import renderapi
import multiprocessing as mp
import time
from matplotlib.collections import LineCollection
import matplotlib.pyplot as plt
import sys
import requests

if __name__== '__main__':
    makenewstack = True

    #source stack
    source_name = "mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Rough_rev1039_v2"
    source_project = 'MM2'
    source_owner='gayathri'
    #target stack
    target_name = '2_sections_near_crack'
    target_project = 'Seams'
    target_owner= 'danielk'
    #
    collection_owner='danielk'
    collection_name='NewPMS_combined_with_montage'

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

    zvals = ['1028.0','1029.0']

    def add_involved(tid):
        section = tid.split('.')[-2]+'.'+tid.split('.')[-1]
        involved = renderapi.pointmatch.get_matches_involving_tile(collection_name,section,tid,owner=collection_owner,render=render_source)
        tids = []
        for z in zvals:
            for inv in involved:
                if z in inv['pId']:
                    tids.append(inv['pId'])
                if z in inv['qId']:
                    tids.append(inv['qId'])
        return tids

    kernel="20170503022718333_295434_5LC_0064_01_001028_0_11_97.1028.0"
    tids = []
    tids.append(kernel)
    for i in np.arange(3):
        print tids
        tmp = []
        for tid in tids:
            newtids = add_involved(tid)
            for nt in newtids:
                if not (nt in tids):
                    tmp.append(nt)
        for t in tmp:
            tids.append(t)
    
    renderapi.stack.create_stack(target_name,render=render_target)
    sourcetiles = []
    for tid in tids:
       sourcetiles.append(renderapi.tilespec.get_tile_spec(source_name,tid,render=render_source))
    
    renderapi.client.import_tilespecs(target_name,sourcetiles,render=render_target)
    renderapi.stack.set_stack_state(target_name, 'COMPLETE', render = render_target)

