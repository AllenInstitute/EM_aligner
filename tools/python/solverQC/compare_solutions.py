import numpy as np
import glob
import sys

print sys.argv[1]
print sys.argv[2]

a = np.loadtxt(sys.argv[1])
b = np.loadtxt(sys.argv[2])
d = a-b

if sys.argv[3]=='plot':
    import matplotlib.pyplot as plt
    plt.figure()
    plt.clf()
    for i in np.arange(6):
        plt.subplot(4,3,i+1)
        plt.plot(a[i::6],'.')
        plt.plot(b[i::6],'.')
        plt.subplot(4,3,i+1+6)
        plt.plot(d[i::6],'.')
        plt.ylim(-0.000005,0.000005)
    plt.show()

else:
    print 'no plot'    

for i in np.arange(6):
    frac = d[i::6]/a[i::6]
    print 'par %d frac max: %e val max %f'%(i,frac.max(),np.abs(d[i::6]).max())
