import numpy as np
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from matplotlib.collections import PatchCollection
import matplotlib.patches as mpatches
import MatlabClasses as mlc
reload(mlc)


result_dir = '../../../../solver_exchange/matlab/20171208.6/'

d = mlc.Diagnostics(result_dir,'Diagnostics.mat',plot=False)
print ''
p = mlc.PointMatches(result_dir,'PM.mat',plot=False)
result = np.loadtxt(result_dir+'x2.txt')
#result = np.loadtxt(result_dir+'d.txt')

#first, group into montages and cross sections
dp = np.abs(np.diff(np.diff(p.adj).flatten()))
ind = np.argwhere(dp>4500).flatten()
indrange = np.zeros((ind.size+1,2)).astype('int')
for i in np.arange(ind.size):
    indrange[i,1] = ind[i]+1
    indrange[i+1,0] = ind[i]+1
indrange[-1,1] = p.adj.shape[0]

plt.figure(1)
plt.clf()
for i in np.arange(indrange.shape[0]):
    plt.subplot(indrange.shape[0],1,i+1)
    x = np.arange(indrange[i,0],indrange[i,1])
    y = np.diff(p.adj).flatten()[indrange[i,0]:indrange[i,1]]
    plt.plot(x,y,'.')
  
def transform(pt,tr):
    newpt = np.zeros_like(pt)
    newpt[:,0] = tr[0]*pt[:,0]+tr[1]*pt[:,1]+tr[2]
    newpt[:,1] = tr[3]*pt[:,0]+tr[4]*pt[:,1]+tr[5]
    return newpt
 
plt.figure(2)
plt.clf()
pclist = [[]]
clist = [[]]
rangeind=0

radius=100
xr = [0,600000]
yr = [0,600000]

k=0 #this will index where we are in residuals
resnorm = np.sqrt(d.residuals[0::2]**2.0+d.residuals[1::2]**2)
#resnorm = np.sqrt(result[0::6]**2.0+result[4::6]**2)

for i in np.arange(p.ntilepairs):
    if np.mod(i,10000)==0:
        print '%d of %d'%(i,p.ntilepairs)
    if i==indrange[rangeind,1]:
        rangeind += 1
        pclist.append([])
        clist.append([])
    ppts=p.raw[0][0][0][i][0]
    npts = ppts.shape[0]
    tind = (p.adj[i][0]-1)*6 #matlab is zero-based
    ppts = transform(ppts,result[tind:(tind+6)])

    qpts=p.raw[0][0][0][i][1]
    tind = (p.adj[i][1]-1)*6 #matlab is zero-based
    qpts = transform(qpts,result[tind:(tind+6)])

    xav = 0.5*(ppts[:,0]+qpts[:,0])
    yav = 0.5*(ppts[:,1]+qpts[:,1])
    
    for j in np.arange(npts):
        if (xav[j]>xr[0])&(xav[j]<xr[1])&(yav[j]>yr[0])&(yav[j]<yr[1]):
            pclist[-1].append(mpatches.Circle((xav[j],yav[j]),radius=radius))
            clist[-1].append(resnorm[k])
        k=k+1
    
cmap = plt.cm.plasma_r

for i in np.arange(len(pclist)):
    pdfname = result_dir+'residual_map_scale%d.pdf'%i
    pdf = PdfPages(pdfname)
    fig = plt.figure(3+i,figsize=(11.69,8.27))
    fig.clf()
    ax = fig.add_subplot(111)
    ax.set_xlim(0,580000)
    ax.set_ylim(0,580000)
    
    LC = PatchCollection(pclist[i],cmap=cmap)
    LC.set_array(np.array(clist[i]))
    LC.set_edgecolor('none')
    ax.add_collection(LC)
    fig = plt.gcf()
    ax.set_aspect('equal')
    ax.patch.set_color([0.5,0.5,0.5]) #gray background, easier to see yellow
    #ax.set_title('%s %s\n%d tile pairs %d point pairs'%(zmontage1,zmontage2,len(pm),sum(clist[2:])))
    fig.colorbar(LC)
    #plt.show()
    pdf.savefig(fig) #save the figure as a pdf page
    pdf.close()
    print '%s done'%pdfname

