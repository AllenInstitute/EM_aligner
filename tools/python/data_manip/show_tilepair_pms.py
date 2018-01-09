import matplotlib.pyplot as plt
import numpy as np
import renderapi
from matplotlib.backends.backend_pdf import PdfPages

def resetlims(extent,xlims,ylims):
    #tool for setting plot limits
    newxlims = [xlims[0],xlims[1]]
    newylims = [ylims[0],ylims[1]]
    if extent[0]<xlims[0]:
        newxlims[0]=extent[0]
    if extent[1]>xlims[1]:
        newxlims[1]=extent[1]
    if extent[2]<ylims[0]:
        newylims[0]=extent[2]
    if extent[3]>ylims[1]:
        newylims[1]=extent[3]
    return newxlims,newylims

def plot_2_tiles(fig,nrows,row,sp1,sp2,im1,im2,matches):
    print sp1.tileId,sp2.tileId,len(matches['matches']['p'][0])
    
    #shift each image according to the offsets in the transform
    extents=[]
    for sp in [sp1,sp2]:
        x0=sp.tforms[1].B0
        w=sp.width
        y0=sp.tforms[1].B1
        h=sp.height
        extents.append([x0,x0+w,y0,y0+h])
    
    #make some whitespace between
    dx = extents[1][0]-extents[0][0]
    dy = extents[1][2]-extents[0][2]
    gap = 100
    if (np.abs(dx)>np.abs(dy)):
        offsetx = np.sign(dx)*(extents[1][1]-extents[1][0]+gap)-dx #figure width + gap
        extents[1][0] = extents[1][0]+offsetx
        extents[1][1] = extents[1][1]+offsetx
    else:
        offsety = np.sign(dy)*(extents[1][3]-extents[1][2]+gap)-dy #figure width + gap
        extents[1][2] = extents[1][2]+offsety
        extents[1][3] = extents[1][3]+offsety
    
    #plot the 2 images and update the axes limits
    ax1 = fig.add_subplot(nrows,2,row*2+1)
    ax1.imshow(im1)
    tid = sp1.tileId
    title = tid[:len(tid)/2]+'\n'+tid[len(tid)/2:]
    ax1.set_title(title,fontsize=8)
    ax1.patch.set_color('k')
    ax1.set_axis_off()

    ax2 = fig.add_subplot(nrows,2,row*2+2)
    ax2.imshow(im2)
    tid = sp2.tileId
    title = tid[:len(tid)/2]+'\n'+tid[len(tid)/2:]
    ax2.set_title(title,fontsize=8)
    ax2.patch.set_color('k')
    ax2.set_axis_off()

    xp = np.array(matches['matches']['p'][0])
    yp = np.array(matches['matches']['p'][1])
    xq = np.array(matches['matches']['q'][0])
    yq = np.array(matches['matches']['q'][1])
  
    #is the first tile p or q?
    if sp1.tileId==matches['pId']:
        axp = ax1
        axq = ax2
    if sp1.tileId==matches['qId']:
        axp = ax2
        axq = ax1

    axp.scatter(xp,yp,s=4,c='r',marker='+')
    axq.scatter(xq,yq,s=4,c='r',marker='+')

    #add in the point matches
    #ax1.plot(np.array(pm[0]['matches']['p'][0])+extents[0][0],np.array(pm[0]['matches']['p'][1])+extents[0][2],'or',markeredgecolor='None',alpha=0.5)
#    plt.plot(np.array(pm[0]['matches']['q'][0])+extents[1][0],np.array(pm[0]['matches']['q'][1])+extents[1][2],'ob',markeredgecolor='None',alpha=0.5)
#    

stack_owner='gayathri'
stack_project='MM2'
stack='mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Rough_rev1039_v2'
collection_owner='danielk'
collection_name='NewPMS_combined_with_montage'

#tid = "20170503022624994_295434_5LC_0064_01_001028_0_23_95.1028.0"
#tid = "20170503014629901_295434_5LC_0064_01_001028_0_1_11.1028.0"
#tid = "20170503022742435_295434_5LC_0064_01_001028_0_13_98.1028.0"
#tid = "20170503022742185_295434_5LC_0064_01_001028_0_12_98.1028.0"
tid = "20170503022718333_295434_5LC_0064_01_001028_0_11_97.1028.0"
section = "1028.0"

#render stuff
scripts = '/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts/'
render_source_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':stack_owner,
    'project':stack_project,
    'client_scripts':scripts,
    'memGB':'2G'
}
render = renderapi.connect(**render_source_params)

involved = renderapi.pointmatch.get_matches_involving_tile(collection_name,section,tid,owner=collection_owner,render=render)
print len(involved)
fn=1
nrows=2
row=0
imsize = 2 #inches
pdf = PdfPages('pdfout/%s_matches.pdf'%tid)

#for inv in involved[0:1]:
for inv in involved:
     if inv['pId']==tid:
         sp1 = renderapi.tilespec.get_tile_spec(stack,inv['pId'],render=render)
         sp2 = renderapi.tilespec.get_tile_spec(stack,inv['qId'],render=render)
     if inv['qId']==tid:
         sp2 = renderapi.tilespec.get_tile_spec(stack,inv['pId'],render=render)
         sp1 = renderapi.tilespec.get_tile_spec(stack,inv['qId'],render=render)
     im1 = renderapi.image.get_tile_image_data(stack,sp1.tileId,render=render,normalizeForMatching=True)
     im2 = renderapi.image.get_tile_image_data(stack,sp2.tileId,render=render,normalizeForMatching=True)
     if np.mod(row,nrows)==0:
         fig = plt.figure(fn,figsize=(12,11))
         fig.clf()
         row=0
     plot_2_tiles(fig,nrows,row,sp1,sp2,im1,im2,inv)
     row+=1
     if (np.mod(row,nrows)==0)|(inv==involved[-1]):
         pdf.savefig(fig)
         fn+=1

pdf.close()
     
