import numpy as np
import scipy
from scipy.io import loadmat as loadmat
import matplotlib.pyplot as plt

path = '/allen/programs/celltypes/workgroups/em-connectomics/danielk/EMsolve/data/'
infile = 'MM2_12section.mat'
data = loadmat(path+infile)
x2=np.array(data.get('x2')).flatten()
del data

xp = np.loadtxt(path+'pastix_solution.dat')

ind=np.arange(x2.size)

plt.figure(1)
plt.clf()
for i in np.arange(1,7):
    plt.subplot(2,3,i)
    xind = np.argwhere(np.mod(ind,6)==(i-1))
    plt.plot(x2[xind],'.')
    plt.plot(x2[xind]-xp[xind],'.')
    plt.title('Affine param: %d'%i)
    if i>3:
        plt.xlabel('tile #')

plt.subplot(2,3,2)
plt.legend(['matlab solution','matlab-pastix'],loc=0)
