#!/usr/bin/python
import sys
import numpy as np
from matplotlib import pyplot as plt

f_proc=sys.argv[1]
f_time_step=sys.argv[2]

n_cores = np.genfromtxt(f_proc)
time_step = np.genfromtxt(f_time_step)

fig, ax = plt.subplots()

for i in range(0, time_step.shape[1]-1):
  time_step[:, i] = time_step[:, i+1] - time_step[:, i]

real_time =  np.mean(time_step[:,5:-5], axis=1)
real_time = real_time/real_time[0]

std_dev =   np.std(time_step[:,5:-5], axis=1)
print(std_dev)
std_dev = std_dev / std_dev[0]
exit()
ideal_curve =np.zeros(n_cores.shape[0])
for i in range(1,n_cores.shape[0]+1) :
  ideal_curve[i-1] = n_cores[0]*1./n_cores[i-1]

#ideal_curve=np.linspace(n_cores[0], n_cores[-1], n_cores.shape[0])
ax.plot(n_cores, real_time, 'bs', n_cores, ideal_curve, 'r--', n_cores, std_dev, 'b--')
#ax.plot(n_cores, real_time, 'r--')

ax.set(xlabel='N cores', ylabel='Normalized time(s)',  title='MN4 scaling curve NEMO4')
ax.grid()
plt.show()
