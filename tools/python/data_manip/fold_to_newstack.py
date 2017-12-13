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
            resolved_t.tilespecs[k].tileId = tids[k]+'.c%d'%j
        renderapi.client.import_tilespecs(target,resolved_t.tilespecs,sharedTransforms=resolved_t.transforms,render=render_target)

if __name__== '__main__':
    #what type of copy
    ncpus=mp.cpu_count()
    zfirst = 1015
    zlast = 1024
    nreflections=3

    makenewstack = False
    makenewpmc = False
    checknewpmc = False

    if 'stack' in sys.argv:
        makenewstack=True
    if 'points' in sys.argv:
        makenewpmc=True
        ncpus=5
    if 'check' in sys.argv:
        checknewpmc=True

    #source stack
    source_name = "mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Rough_rev1039_v2"
    source_owner='gayathri'
    #target stack
    target_name = 'Secs_%d_%d_%d_reflections'%(zfirst,zlast,nreflections)
    target_owner= 'danielk'
    #source collection
    source_collection = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_rev1039'
    source_collection_owner = 'gayathri_MM2'
    #target collection
    target_collection = 'Secs_%d_%d_%d_reflections'%(zfirst,zlast,nreflections)
    target_collection_owner= 'danielk'

    #render
    scripts = '/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts/'
    #define source and target
    render_source_params ={
        'host':'em-131fs',
        'port':8080,
        'owner':source_owner,
        'project':'MM2',
        'client_scripts' : scripts,
        'memGB':'2G'
    }
    render_target_params ={
        'host':'em-131fs',
        'port':8080,
        'owner':target_owner,
        'project':'Reflections',
        'client_scripts' : scripts,
        'memGB':'2G'
    }
    render_source = renderapi.connect(**render_source_params)
    render_target = renderapi.connect(**render_target_params)

    #prepare for reflecting stack
    print 'reading source stack z values'
    zsource = np.array(renderapi.stack.get_z_values_for_stack(source_name,render=render_source))
    copylist = zsource[(zsource>=zfirst)&(zsource<=zlast)]
    
    #old and new z values
    origlist = np.copy(copylist)
    newzlist = np.copy(origlist)
    for i in np.arange(nreflections):
        origlist = np.append(origlist, copylist[::np.power(-1,i+1)][1:])
        while(len(newzlist)<len(origlist)):
            newzlist = np.append(newzlist,newzlist[-1]+1)    
    
    #unique list of z values
    unz = np.unique(origlist)
    
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
            for iz in unz:
                ind = np.argwhere(origlist==iz).flatten()
                args.append([iz,newzlist[ind],source_name,target_name,render_source_params,render_target_params])

            #start the jobs
            pool = mp.Pool(processes=ncpus)
            tmp = pool.map(stack_copyjob, args)
            pool.terminate()

            #close the new stack
            renderapi.stack.set_stack_state(target_name, 'COMPLETE', render = render_target)

    print unz

    #define collections for direct mongo interface
    #db = client.match
    source_collection_name = source_collection_owner+'__'+source_collection
    target_collection_name = target_collection_owner+'__'+target_collection
    #collection = db[source_collection_name]
    #newcollection = db[target_collection_name]

    def new_pm_entry(args):
        client = MongoClient("em-131fs:27017")
        z1 = args[0]
        z2 = args[1]
        origlist = args[2]
        newzlist = args[3]
        source_collection_name = args[4]
        target_collection_name = args[5]
        target_collection_owner = args[6]
        render_target_params = args[7]
        check = args[8]
        render_target = renderapi.connect(**render_target_params)
        s = requests.Session()
        s.mount('http://', requests.adapters.HTTPAdapter(max_retries=5))

        db = client.match
        collection = db[source_collection_name]
        newcollection = db[target_collection_name]
        
        newz1 = newzlist[np.argwhere(origlist==z1).flatten()]
        newz2 = newzlist[np.argwhere(origlist==z2).flatten()]
        newmatches = []
        if np.abs(z1-z2)<=2: #limit to depth of 2
            pm = collection.find({"pGroupId": str(z2),"qGroupId": str(z1)}) #assumes p<=q in db
            norig = pm.count()
            if not check:
                matches = list(pm)
            print '  original: %s %s %d in %s'%(str(z1),str(z2),norig,source_collection_name)
            for ii in np.arange(newz1.size):
                for jj in np.arange(newz2.size):
                    if ((z1==z2)&(newz1[ii]==newz2[jj]))|((z1!=z2)&(np.abs(newz1[ii]-newz2[jj])<=2)):
                        if check:
                            nz1 = max([newz1[ii],newz2[jj]])
                            nz2 = min([newz1[ii],newz2[jj]])
                            pmnew = newcollection.find({"pGroupId": str(nz2),"qGroupId": str(nz1)}) #assumes p<=q in db
                            nnew = pmnew.count()
                            if nnew !=norig:
                                print 'WARNING! for orig: %s %s new: %s %s'%(str(z1),str(z2),str(nz1),str(nz2))
                            print '  check   : %s %s %d in %s'%(str(nz1),str(nz2),nnew,target_collection_name)
                        else:
                            #newmatches = []
                            for im in np.arange(norig):
                                oldpgid = matches[im]['pGroupId']
                                oldqgid = matches[im]['qGroupId']
                                oldpid = matches[im]['pId']
                                oldqid = matches[im]['qId']
                                newqgid = '%0.1f'%newz1[ii]
                                newqid = oldqid+'.c%d'%ii
                                newpgid = '%0.1f'%newz2[jj]
                                newpid = oldpid+'.c%d'%jj
                                newmatches.append(dict.copy(matches[im]))
                                newmatches[-1]['pGroupId'] = newpgid
                                newmatches[-1]['qGroupId'] = newqgid
                                newmatches[-1]['pId'] = newpid
                                newmatches[-1]['qId'] = newqid
                                del newmatches[-1]['_id']  #render does not want this
                            print '  will add: %s %s %d in %s'%(newpgid,newqgid,norig,target_collection_name)
        nnew = len(newmatches)
        if(nnew!=0)&(not check):
            print 'importing %d pointmatches'%nnew
            imp = renderapi.pointmatch.import_matches(target_collection,newmatches,owner=target_collection_owner,render=render_target,session=s)
            print 'import complete'
        return

    if checknewpmc:
        args = [] 
        for irow in np.arange(unz.size): #loop through all the unique original z values
            z1 = unz[irow]
            for icol in np.arange(irow+1): #loop through z's with cross or montage
                z2 = unz[icol]
                args.append([z1,z2,origlist,newzlist,source_collection_name,target_collection_name,target_collection_owner,render_target_params,True])
        #start the jobs
        pool = mp.Pool(processes=ncpus)
        tmp = pool.map(new_pm_entry,args)
        pool.terminate()

    if makenewpmc:
        #ind = (unz>1076)&(unz<1083)
        #unz = unz[ind]
        args = []
        for irow in np.arange(unz.size): #loop through all the unique original z values
            z1 = unz[irow]
            for icol in np.arange(irow+1): #loop through z's with cross or montage
                z2 = unz[icol]
                args.append([z1,z2,origlist,newzlist,source_collection_name,target_collection_name,target_collection_owner,render_target_params,False])

        #start the jobs
        pool = mp.Pool(processes=ncpus)
        tmp = pool.map(new_pm_entry,args)
        pool.terminate()
   
