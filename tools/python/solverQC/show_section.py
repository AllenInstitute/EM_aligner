import shapely
import matplotlib.pyplot as plt
from matplotlib.collections import PatchCollection
import renderapi
from shapely.geometry import Polygon
from descartes.patch import PolygonPatch
import numpy as np

#specify the sectionA
source_stack = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Rough_rev1039_v2'
project = 'MM2'
z = 1028

#create a renderapi.connect.Render object
#start with the full stack
render_connect_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':'gayathri',
    'project': project,
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

    
#load bounds and tile specs
render = renderapi.connect(**render_connect_params)
source_bounds = renderapi.stack.get_bounds_from_z(source_stack,z,render=render)
rcsource = renderapi.tilespec.get_tile_specs_from_z(source_stack,z,render=render)

#make list of intermediate tile IDs
ids = []
for r in rcsource:
    ids.append(r.tileId)
ids = np.array(ids)

fig=plt.figure(2)
fig.clf()

patches = []
shearlist = []
xscalelist = []
yscalelist = []
rotlist = []
for i in np.arange(len(rcsource)):
    patches.append(make_patch(rcsource[i])) 
    shearlist.append(rcsource[i].tforms[1].shear)
    #shearlist.append(rcsource[i].tforms[1].M[0][1])
    xscalelist.append(rcsource[i].tforms[1].scale[0])
    yscalelist.append(rcsource[i].tforms[1].scale[1])
    rotlist.append(rcsource[i].tforms[1].rotation)
    #rotlist.append(rcsource[i].tforms[1].M[1][0])

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

shearlist = fixpi(np.array(shearlist))
rotlist = fixpi(np.array(rotlist)+np.pi)

cmap = plt.cm.plasma_r
cs = [shearlist,rotlist,xscalelist,yscalelist]
i=0
titles=['shear','rotation','xscale','yscale']
ax = fig.add_subplot(111)
ax.set_xlim(0,400000)
ax.set_ylim(0,400000)
LC = PatchCollection(patches,cmap=cmap)
LC.set_array(np.array(cs[i]))
#LC.set_edgecolor('none')
ax.add_collection(LC)
ax.set_aspect('equal')
fig.colorbar(LC)
ax.set_title(titles[i])
plt.show()

for i in np.arange(len(rcsource)):
    tile = rcsource[i]
    tileidlab = trunc_id(tile.tileId)
    ax.text(0.5*(tile.minX+tile.maxX),0.5*(tile.minY+tile.maxY),tileidlab,horizontalalignment='center',verticalalignment='center',fontsize=7)

#title = '%s | %s | z=%d'%(project,source_stack,z)
#ax.set_title(title)
#ax.set_xlabel('x',fontsize=18)
#ax.set_ylabel('y',fontsize=18)

#fig.show()

