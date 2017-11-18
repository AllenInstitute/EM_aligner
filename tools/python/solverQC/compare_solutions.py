import numpy as np
import matplotlib.pyplot as plt
import glob

fdir = '/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/20171117.9/'

guess = np.loadtxt(fdir+'d.txt')
msol = np.loadtxt(fdir+'x2.txt')
pfiles = glob.glob(fdir+'xpa*.txt')
ind = []
for pf in pfiles:
    ind.append(int(pf.split('xpa')[1].split('.')[0]))
ind = np.array(ind)    
s = np.argsort(ind)
pfiles =np.array(pfiles)[s]
pasin = np.array([0,0])
for pf in pfiles:
    pasin = np.vstack((pasin,np.loadtxt(pf)))
pasin = pasin[1:,:]
reind = pasin[:,0].astype('int')-1
psol = np.zeros_like(reind).astype('float')
psol[reind] = pasin[:,1]

a = msol
b = psol

plt.figure()
plt.clf()
for i in np.arange(6):
    plt.subplot(4,3,i+1)
    plt.plot(a[i::6],'.')
    plt.plot(b[i::6],'.')
    plt.subplot(4,3,i+1+6)
    plt.plot(a[i::6]-b[i::6],'.')
    plt.ylim(-0.000005,0.000005)
plt.show()

#plt.subplot(2,3,2)
#plt.title(fdir)
#
#plt.subplot(2,3,1)
#plt.ylabel('par a')
#plt.ticklabel_format(style='sci', axis='x', scilimits=(0,0))
#plt.subplot(2,3,2)
#plt.ylabel('par b')
#plt.ticklabel_format(style='sci', axis='x', scilimits=(0,0))
#plt.subplot(2,3,3)
#plt.ylabel('par c')
#plt.ticklabel_format(style='sci', axis='x', scilimits=(0,0))
#plt.subplot(2,3,4)
#plt.ylabel('par d')
#plt.ticklabel_format(style='sci', axis='x', scilimits=(0,0))
#plt.xlabel('tile #')
#plt.subplot(2,3,5)
#plt.ylabel('par e')
#plt.ticklabel_format(style='sci', axis='x', scilimits=(0,0))
#plt.xlabel('tile #')
#plt.subplot(2,3,6)
#plt.ylabel('par f')
#plt.ticklabel_format(style='sci', axis='x', scilimits=(0,0))
#plt.xlabel('tile #')
#
