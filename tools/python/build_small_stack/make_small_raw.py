import numpy as np
import matplotlib.pyplot as plt
from matplotlib.collections import PatchCollection
from shapely.geometry import Polygon
from descartes.patch import PolygonPatch
import renderapi

create_small_stack=True

#specify the sectionA
source_stack = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_rev1039'
source_project = 'MM2'
source_owner = 'gayathri'

target_stack = '1000_3D_lens_only'
target_project = 'SmallVolume'
target_owner = 'danielk'

zmin = 1015
zmax = 1024

xmin=60000
ymin=20000
hwtarg = (10*0.75)*3840

render_source_params={
    'host':'em-131fs',
    'port':8080,
    'owner':source_owner,
    'project': source_project,
    'client_scripts':'/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts',
    'memGB':'2G'
}
render_target_params={
    'host':'em-131fs',
    'port':8080,
    'owner':target_owner,
    'project': target_project,
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

render_source = renderapi.connect(**render_source_params)
render_target = renderapi.connect(**render_target_params)

if create_small_stack:
    #renderapi.stack.create_stack(target_stack,render=render_target)
    #for iz in np.arange(zmin,zmax+1):
    #    tspecs=renderapi.tilespec.get_tile_specs_from_box(source_stack,iz,xmin,ymin,hwtarg,hwtarg,render=render_source)
     #   renderapi.client.import_tilespecs(target_stack,tspecs,render=render_target)
    renderapi.stack.set_stack_state(target_stack, 'COMPLETE', render=render_target)


#patches = []
#for i in np.arange(len(tspecs)):
#    patches.append(make_patch(tspecs[i]))
#
#fig = plt.figure(1)
#fig.clf()
#ax = fig.add_subplot(111)
#ax.set_xlim((xmin-3840)*0.95,(xmin+hwtarg)*1.05)
#ax.set_ylim((ymin-3840)*0.95,(ymin+hwtarg)*1.05)
#pc = PatchCollection(patches,alpha=0.5)
#ax.add_collection(pc)
#ax.set_aspect('equal')
#fig.show()
#
#im = renderapi.image.get_tile_image_data(source_stack,tspecs[0].tileId,render=render,img_format='jpg')
#gray = cv2.cvtColor(im,cv2.COLOR_BGR2GRAY)
#
#plt.figure(2)
#plt.imshow(gray)
#
#plt.show()
