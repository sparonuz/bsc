program my_mpi_group
  IMPLICIT NONE
  INCLUDE 'mpif.h'

  INTEGER :: mpi_group_word, mpi_group_word1, mpi_group_oce, mpi_comm_oce, code
  INTEGER :: rank, mpisize, mpi_comm_oce1

  mpi_comm_oce = MPI_COMM_NULL

  CALL mpi_init(code)
  CALL MPI_COMM_RANK(MPI_COMM_WORLD, rank, code)
  CALL MPI_COMM_SIZE(MPI_COMM_WORLD, mpisize, code)
  
   call mpi_comm_dup(mpi_comm_world, mpi_comm_oce1, code)
   call mpi_comm_group (mpi_comm_oce1, mpi_group_word, code)
   !call mpi_comm_group (mpi_comm_world, mpi_group_word, code)


  !call mpi_group_range_incl(mpi_group_word, 1, group_range, mpi_group_oce, code)

  call mpi_group_incl(mpi_group_word, 2, (/ 1, 2 /), mpi_group_oce, code)
  call mpi_comm_create_group(mpi_comm_world, mpi_group_oce, 0, mpi_comm_oce, code)
  !call mpi_comm_create_group(mpi_comm_oce1, mpi_group_oce, 0, mpi_comm_oce, code)
  if ( mpi_comm_oce /= MPI_COMM_NULL ) then
    write(*, *) "rank: ",rank
  else
    mpi_comm_oce = MPI_COMM_WORLD 
    CALL MPI_COMM_RANK(mpi_comm_oce, rank, code)
    CALL MPI_COMM_SIZE(mpi_comm_oce, mpisize, code)
    write(*, *) "rank di oce: ",rank
  end if
   
  CALL mpi_finalize(code)
end program
  
