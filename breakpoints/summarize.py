import numpy as np
import matplotlib.pyplot as plt

ntiles = [47182,94330,193019]

#standard backslash performance
stm = [33.6,192.8,1339.8] #seconds
smem = [7.28,28.1,121.9] #GB RAM

#force symm
chtm = [4.1,16.7,80.7]
chmem = [2.37,7.13,24.9]
nch = len(chtm)

plt.figure(1)
plt.clf()
plt.subplot(2,1,1)
plt.loglog(ntiles,stm,'-o')
plt.loglog(ntiles[0:nch],chtm,'-o')
plt.grid()
plt.ylabel('solve time [s]',fontsize=18)

plt.subplot(2,1,2)
plt.loglog(ntiles,smem,'-o')
plt.loglog(ntiles[0:nch],chmem,'-o')
plt.grid()
plt.xlabel('# tiles',fontsize=18)
plt.ylabel('RAM usage [s]',fontsize=18)

plt.legend(['backslash','force symmetric'],loc=0)
plt.axhline(250,color='m')

l = np.polyfit(np.log10(ntiles),np.log10(chmem),1)
xplt = np.arange(1e4,2e6,1e3)
yplt = np.power(10,l[0]*np.log10(xplt)+l[1])

plt.loglog(xplt,yplt,'--')

n250 = np.power(10,(np.log10(1000)-l[1])/l[0])

plt.subplot(2,1,1)
plt.axvline(n250,color='r',linestyle='-')

lt = np.polyfit(np.log10(ntiles),np.log10(chtm),1)
ytplt = np.power(10,lt[0]*np.log10(xplt)+lt[1])
plt.loglog(xplt,ytplt,'--')


plt.show()

