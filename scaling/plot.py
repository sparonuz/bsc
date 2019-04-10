#!/usr/bin/python

import numpy as np
from matplotlib import pyplot as plt

pts = np.genfromtxt('pts.txt')

fig, ax = plt.subplots()
n_cores=pts[:, 0]
real_time=pts[:, 1]
real_time = real_time/real_time[0]
ideal_curve =np.zeros(n_cores.shape[0])
for i in range(1,n_cores.shape[0]+1) :
  ideal_curve[i-1] = n_cores[0]*1./n_cores[i-1]
#ideal_curve=np.linspace(n_cores[0], n_cores[-1], n_cores.shape[0])
ax.plot(n_cores, real_time, 'bs', n_cores, ideal_curve, 'r--')
#ax.plot(n_cores, real_time, 'r--')

ax.set(xlabel='N cores', ylabel='Normalized time(s)',  title='MN4 scaling curve NEMO4')
ax.grid()
plt.show()
