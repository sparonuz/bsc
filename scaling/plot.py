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

  proc = np.genfromtxt(f_proc[i_rep] )
  if not proc.shape : proc = np.array([proc])
  n_cores.append(proc)
  
  time = np.genfromtxt(f_time_step[i_rep])
  if len(time.shape) == 1 :
    time =  time.reshape((1,time.shape[0])) 
  time_step.append(time)

  if( min_ncores == 0 ) : min_ncores = n_cores[i_rep][0]  

  min_ncores = min(min_ncores, n_cores[i_rep][0])
  max_ncores = max(max_ncores, n_cores[i_rep][-1])

min_ncores = int(min_ncores)
max_ncores = int(max_ncores)

n_max_pts = 15 
n_cores_id = np.linspace(min_ncores, max_ncores, n_max_pts)

ideal_first_pt = 0
n_first_pt = 0

for i_rep in range(0 , repetition):
  for i_ts in range(0, (time_step[i_rep].shape)[-1]-1):
    time_step[i_rep][:, i_ts] = time_step[i_rep][ :, i_ts+1] - time_step[i_rep][ :, i_ts]
  
  real_time =  np.mean(time_step[i_rep][ :, 5:-5], axis=1)

  #CONVERSION 
  real_time = factor_sec_2_SYPD/real_time  

  if (int(np.amin(n_cores[i_rep][0])) == min_ncores) :
    ideal_first_pt = ideal_first_pt + factor_sec_2_SYPD/np.mean(time_step[i_rep][0][5:-5])
    n_first_pt = n_first_pt + np.count_nonzero(n_cores[i_rep][:] == min_ncores)

  if i_rep > len(colors)-1 :
    colors.append('%06X' % randint(0, 0xFFFFFF))
    colors[i_rep] = '#'+ colors[i_rep] 
   
  line, =   ax.plot(n_cores[i_rep], real_time, colors[i_rep], label=f_proc[i_rep])
ideal_first_pt = 0.82690  #ideal_first_pt / n_first_pt

ideal_curve = np.zeros(len(n_cores_id))

for i_core in range(0, len(ideal_curve)):
  ideal_curve[i_core] = ideal_first_pt*(n_cores_id[i_core]/n_cores_id[0]) 

line, = ax.plot(n_cores_id, ideal_curve, 'r--', label='Ideal Scaling')

ax.legend()
ax.set(xlabel='N cores', ylabel='SYPD',  title='NEMO4 on MN4 with Orca025')
ax.grid()

plt.show()
