import shapely
import matplotlib.pyplot as plt
from matplotlib.collections import PatchCollection
import renderapi
from shapely.geometry import Polygon
from descartes.patch import PolygonPatch
import numpy as np

#specify the section
z = 1047
fig=plt.figure(z)
#specify the stacks for comparison
stacks = []
stacks.append(['gayathri','MM2','mm2_acquire_8bit_reimage_postVOXA_TEMCA2_rev1039'])
stacks.append(['gayathri','MM2','mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Montage_rev1039'])
stacks.append(['gayathri','MM2','mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Rough_rev1039_v2'])
#stacks.append(['danielk','Seams','single_section'])
#stacks.append(['danielk','Seams','two_sections'])
#stacks.append(['danielk','Seams','two_sections_tf_1em3'])
#stacks.append(['danielk','Seams','two_sections_constr_z'])
#stacks.append(['danielk','Seams','two_sections_constr_z3'])
#stacks.append(['danielk','Seams','lambda_5em3'])


#create a renderapi.connect.Render object
#start with the full stack
render_connect_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':'gayathri',
    'project': 'MM2',
    'client_scripts':'/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts',
    'memGB':'2G'
}

def make_patch(tile):
    pts = []
    pts.append((tile.minX,tile.minY))
    pts.append((tile.maxX,tile.minY))
    pts.append((tile.maxX,tile.maxY))
    pts.append((tile.minX,tile.maxY))
    pts.append((tile.minX,tile.minY))
    return PolygonPatch(Polygon(pts))

def plot_patches(ax,patches,bounds):
    for patch in patches:
        ax.add_patch(patch)
    ax.set_xlim(bounds['minX']*0.9,bounds['maxX']*1.1)
    ax.set_ylim(bounds['minY']*0.9,bounds['maxY']*1.1)
    ax.set_aspect(1)

def trunc_id(tileid):
    tmp = tileid.split('.2316')[0].split('_')
    return tmp[-2]+'_'+tmp[-1]

def fixpi(arr):
    ind = np.argwhere(arr>np.pi)
    while len(ind)!=0:
        arr[ind] = arr[ind]-2.0*np.pi
        ind = np.argwhere(arr>np.pi)
    ind = np.argwhere(arr<-np.pi)
    while len(ind)!=0:
        arr[ind] = arr[ind]+2.0*np.pi
        ind = np.argwhere(arr<-np.pi)
    return arr

nstack = len(stacks)
fig.clf()
cmap = plt.cm.plasma_r
Pcollections = []

for j in np.arange(nstack):
    owner = stacks[j][0]
    project = stacks[j][1]
    stack = stacks[j][2]
    
    #load bounds and tile specs
    render = renderapi.connect(**render_connect_params)
    source_bounds = renderapi.stack.get_bounds_from_z(stack,z,render=render,owner=owner,project=project)
    rcsource = renderapi.tilespec.get_tile_specs_from_z(stack,z,render=render,owner=owner,project=project)
    
    #make list of intermediate tile IDs
    ids = []
    for r in rcsource:
        ids.append(r.tileId)
    ids = np.array(ids)
    
    patches = []
    shearlist = []
    xscalelist = []
    yscalelist = []
    xtrans = []
    ytrans = []
    rotlist = []
    for i in np.arange(len(rcsource)):
        patches.append(make_patch(rcsource[i])) 
        shearlist.append(rcsource[i].tforms[1].shear)
        xscalelist.append(rcsource[i].tforms[1].scale[0])
        yscalelist.append(rcsource[i].tforms[1].scale[1])
        xtrans.append(rcsource[i].tforms[1].translation[0])
        ytrans.append(rcsource[i].tforms[1].translation[1])
        rotlist.append(rcsource[i].tforms[1].rotation)

    #some pi ambiguity    
    shearlist = fixpi(np.array(shearlist))
    rotlist = fixpi(np.array(rotlist))
    if np.array(rotlist).std() > 0.5:
        rotlist = fixpi(np.array(rotlist+np.pi))
        
    
    cs = [shearlist,rotlist,xscalelist,yscalelist,xtrans,ytrans]
    titles=['shear','rotation','xscale','yscale','xtranslation','ytranslation']
    PcollectionRow=[]
    for i in np.arange(6):
        ax = fig.add_subplot(nstack,6,i+1+j*6)
        ax.set_xlim(0,400000)
        ax.set_ylim(0,400000)
        PcollectionRow.append(PatchCollection(patches,cmap=cmap))
        PcollectionRow[-1].set_array(np.array(cs[i]))
        PcollectionRow[-1].set_edgecolor('none')
        ax.add_collection(PcollectionRow[-1])
        ax.set_aspect('equal')
        plt.gca().set_xticks([])
        plt.gca().set_yticks([])
        fig.colorbar(PcollectionRow[-1])
        ax.set_title(titles[i])
        ax.patch.set_color([0.5,0.5,0.5])
        if i==0:
            tmp=''
            k=0
            nwide=30
            while k<len(stack):
                kend = np.min([k+nwide,len(stack)])
                tmp = tmp+stack[k:kend]+'\n'
                k+=nwide
            plt.ylabel('%d\n%s'%(z,tmp),fontsize=8,rotation='vertical',horizontalalignment='center')
    Pcollections.append(PcollectionRow)

#cycle through the columns and set the color min and max all the same
for i in np.arange(len(Pcollections[0])):
    for j in np.arange(len(Pcollections)):
        if j==0:
            cmin=Pcollections[j][i].get_clim()[0]
            cmax=Pcollections[j][i].get_clim()[0]
        else:
            clims = Pcollections[j][i].get_clim()
            if clims[0]<cmin:
                cmin=clims[0]
            if clims[1]>cmax:
                cmax=clims[1]
        print i,j,cmin,cmax
    if 0<=i<2:
        ex = np.max(np.abs([cmin,cmax]))
    #    print i,ex
        clims = [-ex,ex]
    elif 2<=i<4:
        ex = np.max(np.abs([1-cmin,1-cmax]))
    #    print i,ex
        clims = [1-ex,1+ex]
    else:
        clims=[cmin,cmax]
    print clims
    #if i==0:
    #    clims=[-0.025,0.025]
    #if i==1:
    #    clims=[-0.025,0.075]
    #if (i==2)|(i==3):
    #    clims=[0.95,1.05]
    for j in np.arange(len(Pcollections)):
        plt.subplot(nstack,6,j*6+i+1)
        Pcollections[j][i].set_clim(clims)
    
plt.show()

