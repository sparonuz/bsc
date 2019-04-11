#!/usr/bin/python
import sys
from random import randint
import numpy as np
from matplotlib import pyplot as plt


repetition= int(len(sys.argv)/2)
f_proc=[]
f_time_step = []
colors = []
colors=['bs','gs','cs','ms','ys' ]

fig, ax = plt.subplots()

for i_rep in range(0 , repetition):
  f_proc.append(sys.argv[i_rep+1])
  f_time_step.append(sys.argv[repetition + i_rep + 1])
  
  n_cores = np.genfromtxt(f_proc[i_rep])
  time_step = np.genfromtxt(f_time_step[i_rep])
  for i in range(0, time_step.shape[1]-1):
    time_step[:, i] = time_step[:, i+1] - time_step[:, i]
  
  real_time =  np.mean(time_step[:,5:-5], axis=1)
  real_time = real_time/real_time[0]
  
  std_dev = np.std(time_step[:,5:-5], axis=1)
  std_dev = std_dev / std_dev[0]
  
  ideal_curve =np.zeros(n_cores.shape[0])
  for i in range(1, n_cores.shape[0]+1):
    ideal_curve[i-1] = n_cores[0]*1./n_cores[i-1]

  if i_rep > len(colors)-1 :
    colors.append('%06X' % randint(0, 0xFFFFFF))
    colors[i_rep] = '#'+ colors[i_rep] 
 
  ax.plot(n_cores, real_time, colors[i_rep])


line, = ax.plot(n_cores, ideal_curve, 'r--', label='Ideal Scaling')

ax.legend()
ax.set(xlabel='N cores', ylabel='Normalized time(s)',  title='MN4 scaling curve NEMO4')
ax.grid()

plt.show()
