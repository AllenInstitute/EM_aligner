import numpy as np
import matplotlib.pyplot as plt
import glob
import sys

print sys.argv[1]
print sys.argv[2]

a = np.loadtxt(sys.argv[1])
b = np.loadtxt(sys.argv[2])

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

