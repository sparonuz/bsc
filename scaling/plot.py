#!/usr/bin/python

import numpy as np
from matplotlib import pyplot as plt

pts = np.genfromtxt('pts.txt')

fig, ax = plt.subplots()
ax.plot(pts[:, 0], pts[:, 1])

ax.set(xlabel='N cores', ylabel='time(s)',  title='MN4 scaling curve NEMO4')
ax.grid()
plt.show()
