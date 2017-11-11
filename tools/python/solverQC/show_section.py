import shapely
import matplotlib.pyplot as plt
import renderapi
from shapely.geometry import Polygon
from descartes.patch import PolygonPatch
import numpy as np

#specify the sectionA
project = 'Tests'
source_stack = '3_section_rigid_approx_fromv2'
z = 1080

#create a renderapi.connect.Render object
#start with the full stack
render_connect_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':'danielk',
    'project': project,
    'client_scripts':'/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts',
    'memGB':'2G'
}

def make_patches(rc,color):
    polys = []
    patches = []
    
    for tile in rc:
        pts = []
        pts.append((tile.minX,tile.minY))
        pts.append((tile.maxX,tile.minY))
        pts.append((tile.maxX,tile.maxY))
        pts.append((tile.minX,tile.maxY))
        pts.append((tile.minX,tile.minY))
        polys.append(Polygon(pts))
    
    for j in np.arange(len(polys)):
        poly=polys[j]
        color = color
        patches.append(PolygonPatch(poly, facecolor=color, edgecolor='k', alpha=0.5, zorder=2))

    return patches

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

fig=plt.figure(1)
fig.clf()
ax = fig.add_subplot(111)

patches = make_patches(rcsource,'b')
plot_patches(ax,patches,source_bounds)

for i in np.arange(len(rcsource)):
    tile = rcsource[i]
    tileidlab = trunc_id(tile.tileId)
    ax.text(0.5*(tile.minX+tile.maxX),0.5*(tile.minY+tile.maxY),tileidlab,horizontalalignment='center',verticalalignment='center',fontsize=7)

title = '%s | %s | z=%d'%(project,source_stack,z)
ax.set_title(title)
ax.set_xlabel('x',fontsize=18)
ax.set_ylabel('y',fontsize=18)

fig.show()

