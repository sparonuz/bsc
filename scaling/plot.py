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
time_step_length = 900.
factor_sec_2_SYPD = time_step_length / 365.

time_step = []
n_cores = []
max_ncores = 0
i_rep_max = 0 
for i_rep in range(0 , repetition):
  f_proc.append(sys.argv[i_rep + 1])
  f_time_step.append(sys.argv[repetition + i_rep + 1])

  n_cores.append( np.genfromtxt(f_proc[i_rep]))
  time_step.append( np.genfromtxt(f_time_step[i_rep]))

  if (len(n_cores[i_rep]) > max_ncores) :
    max_ncores = max(max_ncores, len(n_cores[i_rep]))
    i_rep_max = i_rep

n_cores = np.asarray(n_cores)
time_step = np.asarray(time_step)

for i_rep in range(0 , repetition):
  for i in range(0, (time_step[i_rep].shape)[1]-1):
    time_step[i_rep][:, i] = time_step[i_rep][ :, i+1] - time_step[i_rep][ :, i]

  real_time =  np.mean(time_step[i_rep][ :, 5:-5], axis=1)
  #CONVERSION 
  real_time = factor_sec_2_SYPD/real_time  
  

  if i_rep > len(colors)-1 :
    colors.append('%06X' % randint(0, 0xFFFFFF))
    colors[i_rep] = '#'+ colors[i_rep] 
   
  ax.plot(n_cores[i_rep], real_time, colors[i_rep])
  
ideal_curve = np.zeros(max_ncores)
for i in range(0, max_ncores):
  ideal_curve[i] = real_time[0] * (i+1)

line, = ax.plot(n_cores[i_rep_max], ideal_curve, 'r--', label='Ideal Scaling')

ax.legend()
ax.set(xlabel='N cores', ylabel='SYPD',  title='MN4 scaling curve NEMO4')
ax.grid()

plt.show()
