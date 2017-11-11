import numpy as np
import struct

fdir='/allen/programs/celltypes/workgroups/em-connectomics/danielk/solver_exchange/matlab/2017-10-23_54/'
fpetsc = open(fdir+'K.petsc','rb')
#fmat = open(fdir+'K.petsc.mat','rb')

fmt='>l'

b=0
print '----header'
for i in np.arange(4):
    a=struct.unpack(fmt, fpetsc.read(4))[0]
#    b=struct.unpack(fmt, fmat.read(4))[0]
    print '%d\t%d'%(a,b)
    if(i==1):
        nrows=a
    if(i==2):
        ncols=a
    if(i==3):
        nnz=a

print '----nnz per row'
for i in np.arange(nrows):
    a=struct.unpack(fmt, fpetsc.read(4))[0]
#    b=struct.unpack(fmt, fmat.read(4))[0]
    print '%d\t%d'%(a,b)

print '----col indices'
for i in np.arange(nnz):
    a=struct.unpack(fmt, fpetsc.read(4))[0]
#    b=struct.unpack(fmt, fmat.read(4))[0]
    print '%d\t%d'%(a,b)

fmt='>d'
print '----values'
for i in np.arange(nnz):
    a=struct.unpack(fmt, fpetsc.read(8))[0]
#    b=struct.unpack(fmt, fmat.read(8))[0]
    print '%f\t%f'%(a,b)


#fmat.close()
fpetsc.close()
