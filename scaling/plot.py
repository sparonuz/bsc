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
min_ncores = 0
i_rep_max = 0 
for i_rep in range(0 , repetition):
  f_proc.append(sys.argv[i_rep + 1])
  f_time_step.append(sys.argv[repetition + i_rep + 1])

  n_cores.append( np.genfromtxt(f_proc[i_rep]))
  time_step.append( np.genfromtxt(f_time_step[i_rep]))

n_cores    = np.asarray(n_cores)
time_step  = np.asarray(time_step)
min_ncores = int(np.amin(n_cores[:][0]))
max_ncores = int(np.amax(n_cores[:][-1]))
n_max_pts = 15
n_cores_id = np.linspace(min_ncores, max_ncores, n_max_pts)
#print (n_cores_id)
#print (np.amin(n_cores[:][0]))
#print(np.amax(n_cores[:][-1]))

#exit()
ideal_first_point = 0
for i_rep in range(0 , repetition):
  for i_ts in range(0, (time_step[i_rep].shape)[1]-1):
    time_step[i_rep][:, i_ts] = time_step[i_rep][ :, i_ts+1] - time_step[i_rep][ :, i_ts]
  
  real_time =  np.mean(time_step[i_rep][ :, 1:-1], axis=1)
  #CONVERSION 
  real_time = factor_sec_2_SYPD/real_time  
  
  ideal_first_point = ideal_first_point + factor_sec_2_SYPD/np.mean(time_step[i_rep][0][1:-1])
  if i_rep > len(colors)-1 :
    colors.append('%06X' % randint(0, 0xFFFFFF))
    colors[i_rep] = '#'+ colors[i_rep] 
   
  ax.plot(n_cores[i_rep], real_time, colors[i_rep])

ideal_first_point = ideal_first_point/repetition
#print(factor_sec_2_SYPD/ideal_first_point, real_time[0])
ideal_curve = np.zeros(n_max_pts)

for i_core in range(0, len(ideal_curve)):
  ideal_curve[i_core] = ideal_first_point * (i_core+1)

line, = ax.plot(n_cores_id, ideal_curve, 'r--', label='Ideal Scaling')

ax.legend()
ax.set(xlabel='N cores', ylabel='SYPD',  title='MN4 scaling curve NEMO4')
ax.grid()

plt.show()
