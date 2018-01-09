from pymongo import MongoClient
import renderapi
import matplotlib
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.collections import LineCollection
import matplotlib.pyplot as plt
import matplotlib.colors
import numpy as np

#cross-section or montage?
cross=False

#limit how many zeros we look up
#zvalues = [1064]
zmin = 1023
zmax = 1034
maxdepth=2
nfig=1

#collection name
#collection_name = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine'
#collection_name = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Fine_1023_1034'
#collection_owner='gayathri_MM2'
collection_name = 'NewPMS_combined_with_montage'
collection_owner='danielk'
#collection_name = 'Dec_MM500_t2'
#collection_owner='russelt'
stack_name = 'mm2_acquire_8bit_reimage_postVOXA_TEMCA2_Rough_rev1039_v2'
stack_owner = 'gayathri'
stack_project = 'MM2'
#collection_name = 'Secs_1015_1099_5_reflections'
#collection_owner = 'danielk'
#collection_name = 'Dec_MM500_t1'
#collection_owner = 'russelt'
#stack_name = 'Secs_1015_1099_5_reflections'
#stack_owner='danielk'
#stack_project = 'Reflections'

scripts = '/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts/'

#render parameters
render_source_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':stack_owner,
    'project':stack_project,
    'client_scripts':scripts,
    'memGB':'2G'
}
render_source = renderapi.connect(**render_source_params)

#direct mongo parameters. faster
mongo_collection_name=collection_owner+'__'+collection_name
client = MongoClient("em-131fs:27017")
db = client.match
collection = db[mongo_collection_name]

#find the groups that are represented in the point match collection
groups = renderapi.pointmatch.get_match_groupIds(collection_name,render=render_source,owner=collection_owner)
ng = len(groups)
print '%d point match groups'%ng

#this is a nice color scheme
cmap = plt.cm.plasma_r

def specs(z):
   #given a z, use renderapi to get the tile center coordinates, and tile IDs
   tspecs = renderapi.tilespec.get_tile_specs_from_z(stack_name,float(z),render=render_source)
   xc = []
   yc = []
   tid = []
   for k in np.arange(len(tspecs)):
       xc.append(0.5*tspecs[k].bbox[0]+tspecs[k].bbox[2])
       yc.append(0.5*tspecs[k].bbox[1]+tspecs[k].bbox[3])
       tid.append(tspecs[k].tileId)
   return np.array(xc),np.array(yc),np.array(tid)

pdf = PdfPages('pdfout/%s.pdf'%collection_name)

for cross in [False,True]:
    for i in np.arange(ng):
       #loop of first section
       zmontage1 = groups[i]
       zm1 = int(float(zmontage1))
       if cross:
           jiter = np.arange(i)
       else:
           jiter = [i]
       for j in jiter:
           #loop of second section, may be the samefor montage
           zmontage2 = groups[j]
           zm2 = int(float(zmontage2))
           if (zmax>=zm1>=zmin)&(zmax>=zm2>=zmin)&((np.abs(zm1-zm2)<=maxdepth)): #should save some time. untested
               print zmontage1,zmontage2
               x1,y1,id1 = specs(zmontage1)
               x2,y2,id2 = specs(zmontage2)
               
               #use mongo to get the point matches
               pm = list(collection.find({"pGroupId":zmontage1,"qGroupId":zmontage2}))
               if len(pm)==0:
                   #maybe it is (q,p) and not (p,q). If it is both, not handled well here.
                   pm = list(collection.find({"pGroupId":zmontage2,"qGroupId":zmontage1}))
               print(len(pm))
    
               lclist = [] #will hold coordinates of line segments (between tile pairs)
               clist = []  #will hold number of point match pairs, used as color
    
               #tiny line to make sure zero is in there for consistent color range
               tmp=[]
               tmp.append((0,0))
               tmp.append((0,0.1))
               lclist.append(tmp)
               clist.append(0)
               #tiny line to make sure max is in there for consistent color range
               tmp=[]
               tmp.append((0.1,0.1))
               tmp.append((0,0.1))
               lclist.append(tmp)
               if i!=j:
                  clist.append(500) #limit was set at 500 for cross-section matches
               else:
                  clist.append(200) #limit was set at 200 for within section matches
     
               if len(pm)!=0: #only plot if there are matches
                   for k in np.arange(len(pm)):
                       #find the tilespecs
                       k1 = np.argwhere(id1==pm[k]['qId']).flatten()
                       k2 = np.argwhere(id2==pm[k]['pId']).flatten()
                       if (k1.size!=0)&(k2.size!=0):
                           k1 = k1[0]
                           k2 = k2[0]
                           tmp=[]
                           tmp.append((x1[k1],y1[k1]))
                           tmp.append((x2[k2],y2[k2]))
                           lclist.append(tmp)
                           clist.append(len(pm[k]['matches']['q'][0]))
                   print sum(clist[2:]) 
                   #plot the line segments all at once for speed:
                   # https://matplotlib.org/examples/pylab_examples/line_collection2.html
                   fig = plt.figure(nfig,figsize=(11.69,8.27))
                   fig.clf()
                   ax = fig.add_subplot(111)
                   ax.set_xlim(0,580000)
                   ax.set_ylim(0,580000)
    
                   LC = LineCollection(lclist,cmap=cmap)
                   LC.set_array(np.array(clist))
                   ax.add_collection(LC)
                   fig = plt.gcf()
                   ax.set_aspect('equal')
                   ax.patch.set_color([0.5,0.5,0.5]) #gray background, easier to see yellow
                   ax.set_title('%s %s\n%d tile pairs %d point pairs'%(zmontage1,zmontage2,len(pm),sum(clist[2:])))
                   fig.colorbar(LC)
                   plt.show()
                   pdf.savefig(fig) #save the figure as a pdf page
  
pdf.close() #close the pdf file
