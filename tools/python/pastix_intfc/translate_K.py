import sys
import numpy as np
import scipy
from scipy.io import loadmat as loadmat
from petsc4py import PETSc

if len(sys.argv)!=2:
    print 'use something like: '
    print 'python translate_K.py /allen/.../xxxK.mat'
    print 'or'
    print 'python translate_K.py /allen/.../xxxLm.mat'
    exit()

if 'K.mat' in sys.argv[1]:
    data = loadmat(sys.argv[1])
    K=data.get('K')
    del data
    bname = sys.argv[1].split('K.mat')[0]
    newname = bname+'K.petsc'
    petsc_mat = PETSc.Mat().createAIJ(size=K.shape,csr=(K.indptr,K.indices,K.data))
    viewer=PETSc.Viewer().createBinary(newname,'w')
    viewer(petsc_mat)
    print 'wrote: %s'%newname
    
if 'Lm.mat' in sys.argv[1]:
    data = loadmat(sys.argv[1])
    Lm=data.get('Lm')
    del data
    nv = np.array(Lm).flatten()
    bname = sys.argv[1].split('Lm.mat')[0]
    newname = bname+'K.petsc.rhs'
    np.savetxt(newname,nv)
    print 'wrote: %s'%newname


