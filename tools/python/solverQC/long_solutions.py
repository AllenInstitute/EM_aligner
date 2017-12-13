import matplotlib.pyplot as plt
import numpy as np
import glob
import sys

dirs = []
dirs.append('../../../../solver_exchange/matlab/section.tests.50')
dirs.append('../../../../solver_exchange/matlab/section.tests.100')
dirs.append('../../../../solver_exchange/matlab/section.tests.150')
dirs.append('../../../../solver_exchange/matlab/section.tests.200')
dirs.append('../../../../solver_exchange/matlab/section.tests.300')
dirs.append('../../../../solver_exchange/matlab/section.tests.505')
nd = len(dirs)

plt.figure(1)
plt.clf()

for i in np.arange(nd):
    a = np.loadtxt(dirs[i]+'/all_xpa.txt')
    ascale = np.sqrt(np.power(a[0::6],2.0)+np.power(a[4::6],2.0))
    ashear = np.sqrt(np.power(a[1::6],2.0)+np.power(a[3::6],2.0))
    atrans = np.sqrt(np.power(a[2::6],2.0)+np.power(a[5::6],2.0))/1e5
    if i<=3:
        a2 = np.loadtxt(dirs[i]+'/x2.txt')
        ascale2 = np.sqrt(np.power(a[0::6],2.0)+np.power(a[4::6],2.0))
        ashear2 = np.sqrt(np.power(a[1::6],2.0)+np.power(a[3::6],2.0))
        atrans2 = np.sqrt(np.power(a[2::6],2.0)+np.power(a[5::6],2.0))/1e5

    ntiles = np.arange(ascale.size)/1e6
    
    plt.subplot(nd,3,1+3*i)
    plt.scatter(ntiles[::10],ascale[::10],0.3,marker='o')
    if i<=3:
        plt.scatter(ntiles[::10],(ascale-ascale2)[::10],0.3,color='b',marker='o')
    plt.xlim(0,ntiles.max())
    plt.ylim(-0.1,2.1)
    plt.subplot(nd,3,2+3*i)
    plt.scatter(ntiles[::10],ashear[::10],0.3)
    if i<=3:
        plt.scatter(ntiles[::10],(ashear-ashear2)[::10],0.3,color='b',marker='o')
    plt.xlim(0,ntiles.max())
    plt.ylim(-0.1,2.1)
    plt.subplot(nd,3,3+3*i)
    plt.scatter(ntiles[::10],atrans[::10],0.3)
    if i<=3:
        plt.scatter(ntiles[::10],(atrans-atrans2)[::10],0.3,color='b',marker='o')
    plt.xlim(0,ntiles.max())


for i in np.arange(nd):
    for j in np.arange(3):
        plt.subplot(nd,3,j+1+3*i)
        plt.xlim(0,ntiles.max())
        if i==(nd-1):
            plt.xlabel('tile # [Mtiles]')
    plt.subplot(nd,3,i*3+1)
    plt.ylabel(dirs[i].split('tests.')[-1]+' sections',fontsize=14)


plt.subplot(nd,3,1)
plt.title('Scale rss ',fontsize=18)
plt.legend(['Pastix fit','Pastix-matlab'],loc=0,fontsize=8)
plt.subplot(nd,3,2)
plt.title('Shear rss ',fontsize=18)
plt.subplot(nd,3,3)
plt.title('Translation rss [kpixels]',fontsize=18)

plt.show()

plt.figure(2)
plt.clf()

