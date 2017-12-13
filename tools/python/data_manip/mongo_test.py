from pymongo import MongoClient
import renderapi
import numpy as np
import time

#which collection are we looking at?
collection_name='gayathri_MM2__mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_rev1039'
source_name='mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_rev1039'
source_owner='gayathri_MM2'

#make a client to the db
client = MongoClient("em-131fs:27017")
#switch into the match collection
db = client.match

collection = db[collection_name]

#define source and target
render_source_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':source_owner,
    'project':'MM2',
    'client_scripts':'/home/danielk/usr/render/render-ws-java-client/src/main/scripts/',
    'memGB':'2G'
}

render_source = renderapi.connect(**render_source_params)

groups = renderapi.pointmatch.get_match_groupIds(source_name,render=render_source)

#chunk = np.array(groups[0:4]).astype('float').astype('int')
chunk = np.array(groups[0:4])
for irow in np.arange(chunk.size):
    firstinrow=1
    for icol in np.arange(irow+1):
        t0=time.time()
        print 'reading groups %s %s'%(chunk[irow],chunk[icol])
        pm2a = collection.find({"pGroupId": groups[irow],"qGroupId": groups[icol]})
        if (irow==icol):
            pm = renderapi.pointmatch.get_matches_within_group(source_name,groups[irow],render=render_source)
            pm2b = -1
        else:
            pm = renderapi.pointmatch.get_matches_from_group_to_group(source_name,groups[irow],groups[icol],render=render_source)
            pm2b = collection.find({"pGroupId": groups[icol],"qGroupId": groups[irow]})
        print 'render time: %0.3f'%(time.time()-t0);
        t0=time.time()
        print 'mongo time: %0.3f'%(time.time()-t0);
        ntilepairs = len(pm)
        ntilepairs2 = pm2a.count()
        if pm2b!=-1:
            ntilepairs2=ntilepairs2+pm2b.count()
        print chunk[irow],chunk[icol],ntilepairs,ntilepairs2



#2017-11-15T09:42:07.046-0800 I COMMAND  [conn4417] command match.gayathri_MM2__mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_rev1039 command: getMore { getMore: 11393451784076, collection: "gayathri_MM2__mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_rev1039" } planSummary: IXSCAN { pGroupId: 1, qGroupId: 1, pId: 1, qId: 1 } cursorid:11393451784076 keysExamined:2600 docsExamined:2600 keyUpdates:0 writeConflicts:0 numYields:21 nreturned:2600 reslen:4195476 locks:{ Global: { acquireCount: { r: 44 } }, Database: { acquireCount: { r: 22 } }, Collection: { acquireCount: { r: 22 } } }
