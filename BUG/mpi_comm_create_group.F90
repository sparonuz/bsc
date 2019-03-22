program mpi_comm_create_grp
  use mpi
  IMPLICIT NONE
 
  INTEGER :: mpi_rank, mpi_size,  mpi_err_code
  INTEGER :: my_comm_dup, mpi_new_comm, &
             mpi_group_world, mpi_new_group
  INTEGER :: rank_index
  INTEGER, DIMENSION(:), ALLOCATABLE :: rank_vec

  CALL mpi_init(mpi_err_code)
  CALL mpi_comm_size(mpi_comm_world, mpi_size, mpi_err_code)
  
  !! allocate and fill the vector for the new group
  allocate(rank_vec(mpi_size/2))
  rank_vec(:) = (/ (rank_index , rank_index=0, mpi_size/2) /)

  !! create the group directly from the comm_world
  ! CALL mpi_comm_group (mpi_comm_world, mpi_group_world, mpi_err_code)
  
  !! duplicating the comm_world
  CALL mpi_comm_dup(mpi_comm_world, my_comm_dup, mpi_err_code)
  !! creatig the group of all processes from the duplicated comm_world
  CALL mpi_comm_group (my_comm_dup, mpi_group_world, mpi_err_code)
 
  
  !! create a new group with just half of processes in comm_world
  CALL mpi_group_incl(mpi_group_world, mpi_size/2, rank_vec, mpi_new_group, mpi_err_code)
  
  !! create a new comm from the comm_world using the new group created
  CALL mpi_comm_create_group(mpi_comm_world, mpi_new_group, 0, mpi_new_comm, mpi_err_code)
  
  !! just some printing for using the new comm created
  if ( mpi_new_comm /= mpi_comm_null ) then
    CALL mpi_comm_rank(mpi_new_comm, mpi_rank, mpi_err_code)
    WRITE(*, *) "Hello from mpi_rank: ",mpi_rank, "in mpi_new_comm"
  else
    CALL mpi_comm_rank(mpi_comm_world, mpi_rank, mpi_err_code)
    WRITE(*, *) "Hello from mpi_rank: ",mpi_rank, "in comm_world"
  end if
   
  !! deallocate and finalize mpi
  if(ALLOCATED(rank_vec)) DEALLOCATE(rank_vec)
  CALL mpi_finalize(mpi_err_code)
end program !mpi_comm_create_grp
  
