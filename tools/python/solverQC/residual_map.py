import numpy as np
from pymongo import MongoClient
import matplotlib.pyplot as plt
from matplotlib.collections import PatchCollection
import matplotlib.patches as mpatches
from shapely.geometry import Polygon
from descartes.patch import PolygonPatch
import mpl_scatter_density
import renderapi
from multiprocessing import Pool
import copy
import requests
import sys
from residual_map_functions import *

if __name__ == "__main__":
    #when the solved area is a substack, this can be used to show the substack location
    #see the very end
    full_stack = ['gayathri','Tests','mm2_acquire_1023_1034_Fine_Affine']
    
    #will proceed in order through the stack list
    stacks = []
    #stacks.append(['danielk','Seams','Substack_x_40000_80000_y_40000_80000_fine_lam_1e03'])
    #stacks.append(['danielk','Seams','Substack_x_0_240000_y_0_240000_fine_lam_1e03'])
    #stacks.append(['danielk','Seams','2_sections_near_crack_fine_lam_1e3'])
    stacks.append(['gayathri','Tests','mm2_acquire_1023_1034_Fine_Affine'])
    #stacks.append(['danielk','Seams','2_sections_near_crack'])
    #stacks.append(['danielk','Seams','Substack_x_0_240000_y_0_240000_fine_lam_1e3_thr_10'])
    #stacks.append(['danielk','Seams','Substack_x_0_240000_y_0_240000_fine_lam_1e3_thr_9'])
    #stacks.append(['danielk','Seams','Substack_x_0_240000_y_0_240000_fine_lam_1e3_thr_8'])
    #stacks.append(['danielk','Seams','Substack_x_0_240000_y_0_240000_fine_lam_1e3_thr_7'])
    #stacks.append(['danielk','Seams','Substack_x_0_240000_y_0_240000_fine_lam_1e3_thr_6'])
    #stacks.append(['danielk','Seams','Substack_x_0_240000_y_0_240000_fine_lam_1e3_thr_5'])
    #stacks.append(['danielk','Seams','Substack_x_0_240000_y_0_240000_fine_lam_1e3_thr_3'])
    #stacks.append(['gayathri','MM2','mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Rough_rev1039_v2'])
    #zvals = ['1023.0','1025.0']
    zvals = [str(float(sys.argv[1])),str(float(sys.argv[2]))]
    
    #point match collection
    pmcs = []
    pmcs.append(['gayathri_MM2','mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_1023_1034_with_montage'])
    #pmcs.append(['danielk','NewPMS_combined_with_montage'])
    #pmcs.append(['danielk','NewPMS_CrossThreshold_10'])
    #pmcs.append(['danielk','NewPMS_CrossThreshold_9'])
    #pmcs.append(['danielk','NewPMS_CrossThreshold_8'])
    #pmcs.append(['danielk','NewPMS_CrossThreshold_7'])
    #pmcs.append(['danielk','NewPMS_CrossThreshold_6'])
    #pmcs.append(['danielk','NewPMS_CrossThreshold_5'])
    #pmcs.append(['danielk','NewPMS_CrossThreshold_3'])
    
    #new point match collection (for writing after filtering)
    dofilter = False
    makenewpmc = False
    rssthresh = 3
    new_pmc = ['danielk','NewPMS_CrossThreshold_%d'%rssthresh]
   
    for iss in np.arange(len(stacks)):
        stack = stacks[iss]
        pmc = pmcs[iss] 
    #for stack in stacks:
        mongo_stack_name = stack[0]+'__'+stack[1]+'__'+stack[2]+'__tile'
        mongo_collection_name = pmc[0]+'__'+pmc[1]
    
        client = MongoClient("em-131fs:27017")
        mstack = client.render[mongo_stack_name]
        mcollection = client.match[mongo_collection_name]
    
        render_connect_params ={
            'host':'em-131fs',
            'port':8080,
            'owner':stack[0],
            'project': stack[1],
            'client_scripts':'/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts',
            'memGB':'2G'
        }
        render = renderapi.connect(**render_connect_params)
    
        #specify z values here in some way, or manually above
        #the computation should work for more than 2 z values,
        #but the plot does not
        #zvals = mstack.distinct("layout.sectionId") #mongo direct

        #get the tile specs 
        tids_by_section = []   #list of tile ids
        tforms_by_section = [] #list of transforms
        tspecs_by_section = [] #list of transforms
        for z in zvals:
            tspecs = renderapi.tilespec.get_tile_specs_from_z(stack[2],int(float(z)),render=render)
            tids = []
            tforms = []
            for ts in tspecs:
                tids.append(ts.tileId)
                tforms.append(ts.tforms[1])
            #get the stack tilespecs
            tids_by_section.append(np.array(tids))
            tforms_by_section.append(tforms)
            tspecs_by_section.append(tspecs)
        
        nsub = -1; #this to calculate and plot all of the point matches
        #nsub = 20; #this to randomly choose up to nsub point match pairs
    
        #compute the location and residual for each point match pair, via the correct transforms
        #xya and xyd will be 2D lists 
        #list[i][j] i=j  will contain montage information
        #list[i][j] i!=j will contain cross   information
        xya = [] #average    position of a point match pair
        xyd = [] #difference position of a point match pair
        matches_all = []
        for i in np.arange(len(zvals)):
            xyarow = [] #will become one row of xya
            xydrow = [] #will become one row pf xyd
            matches_row = []
            tids1 = np.array(tids_by_section[i])
            tforms1 = tforms_by_section[i]
            for j in np.arange(i+1):
                tids2 = np.array(tids_by_section[j])
                tforms2 = tforms_by_section[j]
    
                #make a mongo cursor
                query = mcollection.find({"pGroupId":zvals[j],"qGroupId":zvals[i]})
                if query.count()!=0:
                    #if there's anything there, get it
                    matches = np.array(list(query))
                    #this way, to do the whole section at once
                    ind = np.arange(matches.size)
                    norss = -1
                    args = [tids1,tids2,tforms1,tforms2,matches[ind],nsub,norss]
                    [xya1,xyd1,newmatches,counts] = compute_residuals(args) #if nsub or rssthresh are set, matches gets overwritten
                    #this does not work yet: parallelize by splitting up ind
                    #nsplit = 1
                    #start=0
                    #nsp = matches.size/nsplit
                    #p = Pool(processes=nsplit)
                    #for k in np.arange(nsplit):
                    #    if k==(nsplit-1):
                    #        end = matches.size-1
                    #    else:
                    #        end = start+nsp
                    #    ind = np.arange(start,end)
                    #    ind = np.arange(matches.size)
                    #    args = [tids1,tids2,tforms1,tforms2,matches[ind],nsub]
                    #    results = p.map_async(compute_residuals,(args,))
                    #    [xya1,xyd1] = result.get()
                    #    start = end
    
                    print 'computed residuals for %s %s sampling %d random pts and with rss threshold of %d\n \
                           reducing from %d to %d tile pairs and %d to %d pt pairs' \
                           %(zvals[i],zvals[j],nsub,norss,matches.size,newmatches.size,counts[0],counts[1])
                    xyarow.append(xya1)
                    xydrow.append(xyd1)
                    matches_row.append(newmatches)
            xya.append(xyarow)
            xyd.append(xydrow)
            matches_all.append(matches_row)
    
       
        rowij = []
        rowij.append([0,0,0]) #1st montage row
        rowij.append([1,1,1]) #2nd montage row
        rowij.append([2,1,0]) #cross section row
        sds = []
        print mongo_stack_name
        print '            min   max   average   std'
    
        fig = plt.figure(1)
        fig.clf()
       
        cell_text = [] 
        rows = []
        for row,i,j in rowij:
            #x residuals
            sds.append(make_sd_plot(fig,3,7,5+row*7,xya[i][j][0,:],xya[i][j][1,:],xyd[i][j][0,:]))
            sds[-1].set_clim(-5,5)
            #y residuals
            sds.append(make_sd_plot(fig,3,7,6+row*7,xya[i][j][0,:],xya[i][j][1,:],xyd[i][j][1,:]))
            sds[-1].set_clim(-5,5)
            #rss
            rss = np.sqrt(np.power(xyd[i][j][0,:],2.0),np.power(xyd[i][j][1,:],2.0))
            sds.append(make_sd_plot(fig,3,7,7+row*7,xya[i][j][0,:],xya[i][j][1,:],rss))
            sds[-1].set_clim(0,5)
    
            v = xyd[i][j][0,:]
            print '%s %s  x    %0.1f   %0.1f   %0.1f   %0.1f'%(zvals[i],zvals[j],v.min(),v.max(),v.mean(),v.std())
            cell_row = []
            cell_row.append('%0.1f'%v.min())
            cell_row.append('%0.1f'%v.max())
            cell_row.append('%0.1f'%v.mean())
            cell_row.append('%0.1f'%v.std())
            v = xyd[i][j][1,:]
            print '%s %s  y    %0.1f   %0.1f   %0.1f   %0.1f'%(zvals[i],zvals[j],v.min(),v.max(),v.mean(),v.std())
            cell_row.append('%0.1f'%v.min())
            cell_row.append('%0.1f'%v.max())
            cell_row.append('%0.1f'%v.mean())
            cell_row.append('%0.1f'%v.std())
            v = np.sqrt(np.power(xyd[i][j][0,:],2.0),np.power(xyd[i][j][1,:],2.0))
            print '%s %s  rss    %0.1f   %0.1f   %0.1f   %0.1f'%(zvals[i],zvals[j],v.min(),v.max(),v.mean(),v.std())
            cell_row.append('%0.1f'%v.min())
            cell_row.append('%0.1f'%v.max())
            cell_row.append('%0.1f'%v.mean())
            cell_row.append('%0.1f'%v.std())

            cell_text.append(cell_row)
            rows.append('%d-%d'%(int(float(zvals[i])),int(float(zvals[j]))))

        columns = ['x-min','x-max','x-mean','x-std','y-min','y-max','y-mean','y-std','rss-min','rss-max','rss-mean','rss-std']
        plt.subplot(3,2,5)
        plt.table(cellText=cell_text,rowLabels=rows,colLabels=columns,fontsize=12,loc='center',cellLoc='center')
        #plt.xlabel(stack[2])
        plt.gca().set_axis_off()
    
        xlim = plt.subplot(3,7,7).get_xlim()
        ylim = plt.subplot(3,7,7).get_ylim()
        tpatches = []
        for i in np.arange(len(tids_by_section)):
            tpatches.append(make_transform_patches(tspecs_by_section[i]))
        for i in np.arange(len(tpatches)):
            for j in np.arange(1,5):
                make_transform_plot(fig,3,7,j+i*7,xlim,ylim,tpatches[i][0],tpatches[i][j])
    
        plt.subplot(3,7,1);plt.title('shear')
        plt.subplot(3,7,2);plt.title('rotation')
        plt.subplot(3,7,3);plt.title('xscale')
        plt.subplot(3,7,4);plt.title('yscale')
        plt.subplot(3,7,5);plt.title('x residuals')
        plt.subplot(3,7,6);plt.title('y residuals')
        plt.subplot(3,7,7);plt.title('rss residuals')
    
        plt.subplot(3,7,1);plt.ylabel(zvals[0])
        plt.subplot(3,7,8);plt.ylabel(zvals[1])
        plt.subplot(3,7,19);plt.ylabel('cross section')

        #for i in [1,2,3,4,5,6,7,8,9,10,11,12,13,14,19,20,21]:
        #    ax = plt.subplot(3,7,i)
        #    plt.xlim(8000,30500)
        #    plt.ylim(30500,8000)
        #    plt.xlim(67000,88000)
        #    plt.ylim(303000,330000)
           

        plt.show()
    
        #map where this subplot is in the section, just for the first section
        #rcoriginal = renderapi.tilespec.get_tile_specs_from_z(full_stack[2],int(float(zvals[0])),render=render,owner=full_stack[0],project=full_stack[1])
        #original_patch = make_transform_patches(rcoriginal)
        #ax = make_transform_plot(fig,3,7,15,[0,500000],[0,500000],original_patch[0],original_patch[1]*0.0,bar=False)
        #rcsub = []
        #for rco in rcoriginal:
        #    if rco.tileId in tids_by_section[0]:
        #        rcsub.append(rco)
        #sub_patch = make_transform_patches(rcsub)
        #ax = make_transform_plot(fig,3,7,15,[0,500000],[0,500000],sub_patch[0],sub_patch[1],bar=False,ax=ax)
       
        #ax.collections[0].set_alpha(0.5)
        #ax.set_xlim(0,400000)
        #ax.set_ylim(0,400000)
    
        #fig.savefig('./output/'+mongo_stack_name+'.png')

        #fig=plt.figure(2)
        #fig.clf()

 
        ##choose the cross section
        #i=1
        #j=0
        #d = make_sd_plot(fig,2,3,1,xya[i][j][0,:],xya[i][j][1,:],xyd[i][j][0,:])
        #d.set_clim(-5,5)
        ##y residuals
        #d = make_sd_plot(fig,2,3,2,xya[i][j][0,:],xya[i][j][1,:],xyd[i][j][1,:])
        #d.set_clim(-5,5)
        ##rss
        #rss = np.sqrt(np.power(xyd[i][j][0,:],2.0),np.power(xyd[i][j][1,:],2.0))
        #d = make_sd_plot(fig,2,3,3,xya[i][j][0,:],xya[i][j][1,:],rss)
        #d.set_clim(0,5)
      
        if dofilter:
            #threshold the cross-section by rss value
            nsub=-1
            #rssthresh = 10.0
            args = [np.array(tids_by_section[i]),np.array(tids_by_section[j]),tforms_by_section[i],tforms_by_section[j],matches_all[i][j],nsub,rssthresh]
            [xya_thr,xyd_thr,matches_thr,counts] = compute_residuals(args) #if nsub or rssthresh are set, matches gets overwritten
            print 'computed residuals for %s %s sampling %d random pts and with rss threshold of %d\n \
                   reducing from %d to %d tile pairs and %d to %d pt pairs' \
                   %(zvals[i],zvals[j],nsub,rssthresh,matches_all[i][j].size,matches_thr.size,counts[0],counts[1])

            #replace it, for ingesting into a new pmc
            matches_all[i][j] = matches_thr

            #make some threshold, units of pixels
            d = make_sd_plot(fig,2,3,4,xya_thr[0,:],xya_thr[1,:],xyd_thr[0,:])
            d.set_clim(-5,5)
            #y residuals
            d = make_sd_plot(fig,2,3,5,xya_thr[0,:],xya_thr[1,:],xyd_thr[1,:])
            d.set_clim(-5,5)
            #rss
            rss_thr = np.sqrt(np.power(xyd_thr[0,:],2.0),np.power(xyd_thr[1,:],2.0))
            d = make_sd_plot(fig,2,3,6,xya_thr[0,:],xya_thr[1,:],rss_thr)
            d.set_clim(0,5)

            plt.subplot(2,3,1)
            plt.ylabel('No threshold',fontsize=18)
            plt.title('x residuals',fontsize=18)
            plt.subplot(2,3,4)
            plt.ylabel('remove rss>%0.1f pixels'%rssthresh,fontsize=18)
            plt.subplot(2,3,2)
            plt.title('y residuals',fontsize=18)
            plt.subplot(2,3,3)
            plt.title('rss residuals\n%d point pairs'%(xya[i][j][0,:].size),fontsize=18)
            plt.subplot(2,3,6)
            plt.title('%d point pairs'%(xya_thr[0,:].size),fontsize=18)

        if makenewpmc:
            s = requests.Session()
            s.mount('http://', requests.adapters.HTTPAdapter(max_retries=5))

            print 'adding point matches to: '
            print new_pmc
            for i in np.arange(len(matches_all)):
               for j in np.arange(len(matches_all[i])):
                   renderapi.pointmatch.import_matches(new_pmc[1],matches_all[i][j].tolist(),owner=new_pmc[0],render=render,session=s)
                   print '%s %s done'%(zvals[i],zvals[j])
