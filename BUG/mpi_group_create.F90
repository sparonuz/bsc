program my_mpi_group
  IMPLICIT NONE
  INCLUDE 'mpif.h'

  INTEGER :: mpi_group_world, mpi_new_group, mpi_new_comm, mpi_err_code
  INTEGER :: mpi_rank, my_comm_copy

  mpi_new_comm = mpi_comm_null

  CALL mpi_init(mpi_err_code)
  CALL mpi_comm_rank(mpi_comm_world, mpi_rank, mpi_err_code)
  
  CALL mpi_comm_dup(mpi_comm_world, my_comm_copy, mpi_err_code)
  CALL mpi_comm_group (my_comm_copy, mpi_group_world, mpi_err_code)
  !CALL mpi_comm_group (mpi_comm_world, mpi_group_world, mpi_err_code)

  CALL mpi_group_incl(mpi_group_world, 2, (/ 1, 2 /), mpi_new_group, mpi_err_code)

  CALL mpi_comm_create_group(mpi_comm_world, mpi_new_group, 0, mpi_new_comm, mpi_err_code)
  
  if ( mpi_new_comm == mpi_comm_null ) then
    WRITE(*, *) "Hello from mpi_rank: ",mpi_rank, "in comm_world"
  else
    CALL mpi_comm_rank(mpi_new_comm, mpi_rank, mpi_err_code)
    WRITE(*, *) "Hello from mpi_rank: ",mpi_rank, "in mpi_new_comm"
  end if
   
  CALL mpi_finalize(mpi_err_code)
end program
  
