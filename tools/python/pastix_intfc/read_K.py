import numpy as np
import scipy
from scipy.io import loadmat as loadmat
from petsc4py import PETSc

path = '/allen/programs/celltypes/workgroups/em-connectomics/danielk/EMsolve/data/'
infile = 'MM2_12section_K.mat'
data = loadmat(path+infile)
K=data.get('K')
del data

petsc_mat = PETSc.Mat().createAIJ(size=K.shape,csr=(K.indptr,K.indices,K.data))
viewer=PETSc.Viewer().createBinary(path+'MM2_12section_K_petsc.dat','w')
viewer(petsc_mat)

infile = 'MM2_12section_Lm.mat'
data = loadmat(path+infile)
Lm=data.get('Lm')
del data

nv = np.array(Lm,dtype=PETSc.ScalarType).flatten()
#nvendian = nv.newbyteorder()
#nvendian.astype('float').tofile(path+'MM2_12section_K_petsc.dat.rhs')
#nvendian.astype('float32').tofile(path+'MM2_12section_K_petsc.dat.rhs')
petsc_vec = PETSc.Vec().createWithArray(nv)
viewer=PETSc.Viewer().createASCII(path+'MM2_12section_K_petsc.dat.rhs','w')
viewer(petsc_vec)


