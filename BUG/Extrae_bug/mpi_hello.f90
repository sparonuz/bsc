program main

#ifdef EXTRAE
  USE EXTRAE_MODULE
#endif
  
  implicit none 
  include "mpif.h"
  integer ( kind = 4 ) :: error
  integer ( kind = 4 ) :: rank, mpi_size
  integer ( kind = 4 ) :: p
  real ( kind = 8 ) :: wtime
!
!  Initialize MPI.
!
  call MPI_Init ( error )
#ifdef EXTRAE
  CALL Extrae_shutdown()
#endif
  call mpi_comm_size(MPI_COMM_WORLD, mpi_size, error)
  call mpi_comm_rank(MPI_COMM_WORLD, rank, error)
#ifdef EXTRAE
  call Extrae_restart()
#endif
  write(0, *) "my rank: ", rank
  call MPI_Finalize ( error )

end program
