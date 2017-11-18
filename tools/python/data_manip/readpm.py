from pymongo import MongoClient
import renderapi
from multiprocessing import Process
import time
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.pyplot as plt
import numpy as np

#use these for using render
#source_name='mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_rev1039'
source_name='mm2_acquire_8bit_reimage_montage'
#source_name = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine'
source_owner='gayathri_MM2'
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

#use these for using mongo directly: much much faster
collection_name=source_owner+'__'+source_name
#make a client to the db
client = MongoClient("em-131fs:27017")
#switch into the match collection
db = client.match
collection = db[collection_name]


t0 = time.time()
groups = renderapi.pointmatch.get_match_groupIds(source_name,render=render_source)
ng = len(groups)
print '%d groups'%ng
nchunk = 15
nhistbins = 10
plt.figure(figsize=(11.69,8.27))
pagecnt = 0
nmax=50000.

def page_blocks(ng,nchunk):
    #blocks of group #'s to fit per page, with one overlap
    chunks = []
    last=0
    while last<ng:
        chunks.append(np.arange(nchunk)+last)
        last = chunks[-1][-1]
        ind = np.argwhere(chunks[-1]>ng-1)
        chunks[-1] = np.delete(chunks[-1],ind)
    return chunks

chunks=page_blocks(ng,nchunk)

pdf = PdfPages('%s.pdf'%source_name)

for chunk in chunks:
    #make a new figure for a new pdf page
    plt.figure(figsize=(11.69,8.27))
    for irow in np.arange(chunk.size):
        firstinrow=1
        for icol in np.arange(irow+1):
            print 'reading groups %s %s'%(groups[chunk[irow]],groups[chunk[icol]])
            pm2a = collection.find({"pGroupId": groups[chunk[irow]],"qGroupId": groups[chunk[icol]]})
            if (irow==icol):
                #pm = renderapi.pointmatch.get_matches_within_group(source_name,groups[irow],render=render_source)
                pm2b=-1
            else:
                #pm = renderapi.pointmatch.get_matches_from_group_to_group(source_name,groups[irow],groups[icol],render=render_source)
                pm2a = collection.find({"pGroupId": groups[chunk[icol]],"qGroupId": groups[chunk[irow]]})
            #ntilepairs = len(pm)
            ntilepairs = pm2a.count()
            if pm2b!=-1:
                ntilepairs=ntilepairs+pm2b.count()
            if ntilepairs>0:
                cntr = np.zeros(ntilepairs)
                ##render:
                #for k in np.arange(ntilepairs):
                #    cntr[k] = len(pm[k]['matches']['q'][0])
                #
                #mongo:
                k=0
                for doc in pm2a:
                    cntr[k] = len(doc['matches']['q'][0])
                    k = k+1
                if pm2b!=-1:
                    for doc in pm2b:
                        cntr[k] = len(doc['matches']['q'][0])
                        k = k+1

                ax = plt.subplot(nchunk,nchunk,irow*nchunk+icol+1)
                plt.hist(cntr,bins=nhistbins)
                plt.xlim(0,500)
                plt.ylim(1,1e5)
                ax.set_yscale('log')
                f = 1-float(ntilepairs)/nmax      
                if f<0.0:
                    f=0.0
                ax.patch.set_facecolor((f, f, f))
                plt.gca().set_xticklabels([])
                plt.gca().set_yticklabels([])
                if firstinrow==1:
                     plt.ylabel('%d'%int(float(groups[chunk[irow]])),fontsize=8)
                     firstinrow=0
                if irow==icol:
                     plt.title('%d'%int(float(groups[chunk[icol]])),fontsize=8)
        
    #add a bigger one, upper right, for legend
    #just repeats last
    ax = plt.subplot(4,4,4) 
    plt.hist(cntr,bins=nhistbins)
    plt.xlim(0,500)
    plt.ylim(1,1e5)
    ax.set_yscale('log')
    f = 1.0-float(ntilepairs)/nmax      
    if f<0.0:
        f=0.0
    ax.patch.set_facecolor((f, f, f))
    plt.ylabel('section %d\n# of tile pairs'%int(float(groups[chunk[irow]])),fontsize=8)
    plt.xlabel('point matches per tile pair')
    plt.title('section %d'%int(float(groups[chunk[icol]])),fontsize=8)
    #make a background colorbar, lower left
    for ip in np.arange(4):
        ax = plt.subplot(10,10,91+ip)
        plt.gca().set_xticklabels([])
        plt.gca().set_yticklabels([])
        bg = 10000.*(ip+1)
        f = 1-bg/nmax      
        ax.patch.set_facecolor((f, f, f))
        plt.title('%d\ntile pairs'%int(bg),fontsize=8)
    #say what it is
    plt.subplot(10,10,5)
    plt.title(source_name,fontsize=10)
    plt.axis('off')  
    #save the figure and reset to the next page 
    #save the page
    pdf.savefig()

pdf.close()
