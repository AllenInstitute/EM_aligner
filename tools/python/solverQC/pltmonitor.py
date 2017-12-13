import sys
import matplotlib.pyplot as plt
import numpy as np

d = open(sys.argv[1],'r')
lines = d.readlines()
d.close()

tm = []
mem = []
cpu = []

for line in lines:
    tmp = line.split('sec')[0]
    tm.append(int(tmp))
    tmp = line.split('GB')[0].split('sec')[-1]
    mem.append(float(tmp))
    tmp = line.split('equiv')[0].split('total')[-1]
    cpu.append(float(tmp))

plt.figure(1)
#plt.clf()
plt.subplot(2,1,1)
plt.plot(tm,mem)
plt.subplot(2,1,2)
plt.plot(tm,cpu)

plt.show()


