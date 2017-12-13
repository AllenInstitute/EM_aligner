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
    ncpus=7
    zfirst = 1023
    zlast = 1034

    #source collection 1 for montage
    source_collection1 = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_rev1039'
    source_collection_owner1 = 'gayathri_MM2'
    #source collection 2 for cross
    source_collection2 = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_1023_1034'
    source_collection_owner2 = 'gayathri_MM2'
    #target collection
    target_collection = 'NewPMS_combined_with_montage'
    target_collection_owner= 'danielk'

    #render
    scripts = '/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts/'
    render_target_params ={
        'host':'em-131fs',
        'port':8080,
        'owner':target_collection_owner,
        'project':'Reflections',
        'client_scripts' : scripts,
        'memGB':'2G'
    }
    render_target = renderapi.connect(**render_target_params)

    #define collections for direct mongo interface
    source_collection_name1 = source_collection_owner1+'__'+source_collection1
    source_collection_name2 = source_collection_owner2+'__'+source_collection2
    target_collection_name = target_collection_owner+'__'+target_collection

    def new_pm_entry(args):
        client = MongoClient("em-131fs:27017")
        z1 = args[0]
        z2 = args[1]
        source_collection_name = args[2]
        target_collection_name = args[3]
        target_collection_owner = args[4]
        render_target_params = args[5]
        render_target = renderapi.connect(**render_target_params)
        s = requests.Session()
        s.mount('http://', requests.adapters.HTTPAdapter(max_retries=5))

        db = client.match
        collection = db[source_collection_name]
        newcollection = db[target_collection_name]
        
        pm = collection.find({"pGroupId": str(z2),"qGroupId": str(z1)}) #assumes p<=q in db
        matches = list(pm)
        norig = pm.count()
        newmatches = []
        for im in np.arange(norig):
            newmatches.append(dict.copy(matches[im]))
            del newmatches[-1]['_id']  #render does not want this
        nnew = len(newmatches)
        if(nnew!=0):
            print '%s %s importing %d pointmatches'%(str(z1),str(z2),nnew)
            imp = renderapi.pointmatch.import_matches(target_collection,newmatches,owner=target_collection_owner,render=render_target,session=s)
            print 'import complete'
        return

    unz = np.arange(zfirst,zlast+1).astype('float')
    args = []
    #start with montage set
    for irow in np.arange(unz.size): #loop through all the unique original z values
        z1 = unz[irow]
        args.append([z1,z1,source_collection_name1,target_collection_name,target_collection_owner,render_target_params])
    #add the cross set
    for irow in np.arange(unz.size): #loop through all the unique original z values
        z1 = unz[irow]
        for icol in np.arange(irow): #loop through z's with cross or montage
            z2 = unz[icol]
            args.append([z1,z2,source_collection_name2,target_collection_name,target_collection_owner,render_target_params])

    #start the jobs
    pool = mp.Pool(processes=ncpus)
    tmp = pool.map(new_pm_entry,args)
    pool.terminate()
   
