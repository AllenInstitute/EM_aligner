import numpy as np
import matplotlib
import matplotlib.pyplot as plt
import glob
import sys
import renderapi

#directory of the original, non-reflected solution
fdir1 = '/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171129.0/'
stack = 'Original_1015_1024_check_Fine'
nr = 3
#directory of the reflected solution
fdir2 = '/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171128/'
stack2 = 'Secs_1015_1024_3_reflections_Fine'

plots=1
plots=6

#render
scripts = '/allen/programs/celltypes/workgroups/em-connectomics/gayathrim/nc-em2/Janelia_Pipeline/render_latest/render-ws-java-client/src/main/scripts/'
render_params ={
    'host':'em-131fs',
    'port':8080,
    'owner':'danielk',
    'project':'Reflections',
    'client_scripts' : scripts,
    'memGB':'2G'
}
render = renderapi.connect(**render_params)
d=renderapi.stack.get_stack_sectionData(stack,render=render)
ntiles = []
for i in d:
    ntiles.append(i['tileCount'])
ntiles = np.array(ntiles)
d=renderapi.stack.get_stack_sectionData(stack2,render=render)
ntiles2 = []
for i in d:
    ntiles2.append(i['tileCount'])
ntiles2 = np.array(ntiles2)

msol1 = np.loadtxt(fdir1+'x2.txt')
d1 = np.loadtxt(fdir1+'d.txt')
msol2 = np.loadtxt(fdir2+'x2.txt')
d2 = np.loadtxt(fdir2+'d.txt')

plt.figure(1)
plt.clf()
ax = plt.subplot(2,1,1)
i=0
cmap = plt.cm.plasma_r
normalize = matplotlib.colors.Normalize(vmin=0, vmax=len(ntiles))
sm = matplotlib.cm.ScalarMappable(norm=normalize, cmap=cmap)


orig = np.arange(len(ntiles))
r = orig
for k in np.arange(nr):
    r = np.hstack((r,orig[::np.power(-1,k+1)][1:]))
def plot1(r,ntiles,msol1,d1,i,ax):
    xend = -1
    for j in np.arange(r.size):
        xstart = xend+1
        xend = xstart + ntiles[r[j]]
        xplt = np.arange(xstart,xend)
        ystart = ntiles[:r[j]].sum()
        yend = ystart + ntiles[r[j]]
        yplt = msol1[i::6][ystart:yend]
        yplt2 = d1[i::6][ystart:yend]
        plt.scatter(xplt,yplt,s=0.8,c=sm.to_rgba(r[j]),edgecolors='None')
        plt.scatter(xplt,yplt2,s=0.1,c='k',edgecolors='None',alpha=0.8)
    plt.xlim(0,xend)

plot1(r,ntiles,msol1,d1,i,ax)

xl = np.linspace(200000,250000,10)
yl = np.ones_like(xl)*1.12
plt.scatter(xl,yl,c=sm.to_rgba(np.arange(10)),edgecolors='None')
plt.text(255000,1.12,'fine alignment solution',verticalalignment='center')
plt.scatter(xl[-1],[1.1],c=[[0.0,0.0,0.0,1]],edgecolors='None')
plt.text(255000,1.1,'rough alignment constraint',verticalalignment='center')

ax = plt.gca()
ax.patch.set_color([0.5,0.5,0.5]) #gray background, easier to see yellow
plt.ylabel('Affine parameter %d'%i,fontsize=18)
plt.text(50000,1.1,'10 section stack\nsolution reflected',fontsize=18,color='w')

ax = plt.subplot(2,1,2)
def plot2(r,ntiles2,msol2,d2,i,ax):
    xend = -1
    for j in np.arange(ntiles2.size):
        xstart = xend+1
        xend = xstart + ntiles2[j]
        if j==ntiles2.size-1:
            xend = msol2.size/6   
        xplt = np.arange(xstart,xend)
        yplt = msol2[i::6][xstart:xend]
        yplt2 = d2[i::6][xstart:xend]
        plt.scatter(xplt,yplt,s=0.8,c=sm.to_rgba(r[j]),edgecolors='None')
        plt.scatter(xplt,yplt2,s=0.1,c='k',edgecolors='None',alpha=0.8)
    plt.xlim(0,xend)

plot2(r,ntiles2,msol2,d2,i,ax)

ax.patch.set_color([0.5,0.5,0.5]) #gray background, easier to see yellow
plt.ylabel('Affine parameter %d'%i,fontsize=18)
plt.text(50000,1.1,'10 section stack\nreflected, then solved',fontsize=18,color='w')
plt.xlabel('Tile #',fontsize=18)
plt.show()


plt.figure(2)
plt.clf()
for i in np.arange(3):
    ax = plt.subplot(2,3,i+1)   
    plot1(r,ntiles,msol1,d1,i,ax)
    ax.patch.set_color([0.5,0.5,0.5]) #gray background, easier to see yellow
    plt.title('Affine parameter %d'%i)
    ax = plt.subplot(2,3,i+4)   
    plot2(r,ntiles2,msol2,d2,i,ax)
    ax.patch.set_color([0.5,0.5,0.5]) #gray background, easier to see yellow
 
plt.show()

plt.figure(3)
plt.clf()
for i in np.arange(3,6):
    ax = plt.subplot(2,3,i+1-3)   
    plot1(r,ntiles,msol1,d1,i,ax)
    ax.patch.set_color([0.5,0.5,0.5]) #gray background, easier to see yellow
    plt.title('Affine parameter %d'%i)
    ax = plt.subplot(2,3,i+4-3)
    plot2(r,ntiles2,msol2,d2,i,ax)
    ax.patch.set_color([0.5,0.5,0.5]) #gray background, easier to see yellow
 
plt.show()
