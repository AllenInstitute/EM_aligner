import matplotlib.pyplot as plt
import numpy as np

sections = []
ntiles = []
setup = []
msolve = []
mram = []
psolve = []
pram = []

#50
sections.append(50)
ntiles.append(494005)
setup.append(61.+940.+240.+437)
msolve.append(544.)
mram.append(189.6)
psolve.append(9.5+328.+4.3+9)
pram.append(81.8)

#100
sections.append(100)
ntiles.append(974026)
setup.append(114.+1686.+392.+729.)
msolve.append(2351.)
mram.append(407.2)
psolve.append(25.6+1640+9.4+19.7)
pram.append(210.8)

#150
sections.append(150)
ntiles.append(1463570)
setup.append(159.+2448+713+1260)
msolve.append(2944.)
mram.append(571.5)
psolve.append(36.+2190+15.2+64.9)
pram.append(258.4)

#200
sections.append(200)
ntiles.append(1952741)
setup.append(167.+3226.+811.+1482.)
msolve.append(6500.)
mram.append(986.5)
psolve.append(59.3+4350+19.1+99.8)
pram.append(391.4)

#300
sections.append(300)
ntiles.append(2913640)
setup.append(293.+4061+1219+2225)
#msolve.append(6500.)
#mram.append(986.5) up to ~200GB just to make K
psolve.append(91.7+8390+31.4+292)
pram.append(619)

#505
sections.append(505)
ntiles.append(4922585)
setup.append(499.+7242.+2138.+3839.)
#msolve.append(6500.)
#mram.append(986.5) up to ~200GB just to make K
psolve.append(160.+15200.+47.+99.)
pram.append(954.)

#conversions
ntiles = np.array(ntiles)/1e6
setup = np.array(setup)/3600.
msolve = np.array(msolve)/3600.
psolve = np.array(psolve)/3600.
mram = np.array(mram)/1000.
pram = np.array(pram)/1000.

ms=8.0

plt.figure(1)
plt.clf()
plt.subplot(2,1,1)
plt.plot(ntiles,setup,'sb',markersize=ms,zorder=10)
nnp = msolve.size
plt.plot(ntiles[:nnp],setup[:nnp]+msolve,'sr',markersize=ms,zorder=10)
plt.plot(ntiles,setup+psolve,'sg',markersize=ms,zorder=10)
#plt.plot(ntiles[:-1],setup[:-1]+psolve[:-1],'sg',markersize=ms,zorder=10)
#plt.plot(ntiles[-1],setup[-1]+psolve[-1],'sw',markersize=ms,zorder=10)
for i in np.arange(len(ntiles)):
    plt.plot([ntiles[i],ntiles[i]],[0,setup[i]],'-k',markersize=ms,zorder=0)
for i in np.arange(msolve.size):
    plt.plot([ntiles[i],ntiles[i]],[setup[i],setup[i]+msolve[i]],'-k',markersize=ms,zorder=0)
for i in np.arange(psolve.size):
    plt.plot([ntiles[i],ntiles[i]],[setup[i],setup[i]+psolve[i]],'-k',markersize=ms,zorder=0)
#i=psolve.size-2
#plt.plot([ntiles[i],ntiles[i]],[setup[i],setup[i]+psolve[i]],'-k',markersize=ms,zorder=0)
#plt.text(ntiles[i]+0.025,setup[i]+psolve[i],'estimate',verticalalignment='center')

plt.ylabel('time [hours]',fontsize=18)

plt.legend(['construct K, matlab','solve, matlab','solve, pastix'],loc=2)
plt.grid()
plt.xlim(0,5.5)
plt.ylim(0,10)

plt.subplot(2,1,2)
nnp = mram.size
plt.plot(ntiles[:nnp],mram[:nnp],'sr',markersize=ms,zorder=10)
plt.plot(ntiles,pram,'sg',markersize=ms,zorder=10)
#plt.plot(ntiles[:-1],pram[:-1],'sg',markersize=ms,zorder=10)
#plt.plot(ntiles[-1],pram[-1],'sw',markersize=ms,zorder=10)
plt.ylabel('max RAM [TB]',fontsize=18)
plt.grid()
plt.legend(['matlab','pastix'],loc=2)
for i in np.arange(pram.size):
    plt.plot([ntiles[i],ntiles[i]],[0,pram[i]],'-k',markersize=ms,zorder=0)
for i in np.arange(mram.size):
    plt.plot([ntiles[i],ntiles[i]],[0,mram[i]],'-k',markersize=ms,zorder=0)

plt.xlabel('# of tiles [Mtiles]',fontsize=18)
plt.xlim(0,5.5)
for i in np.arange(len(sections)):
   plt.text(ntiles[i]+0.025,pram[i],'%d\nsections'%sections[i],verticalalignment='center')
#i=len(sections)-1
#plt.text(ntiles[i]+0.025,pram[i],'%d\nsections estimate'%sections[i],verticalalignment='center')
plt.ylim(0,2)
