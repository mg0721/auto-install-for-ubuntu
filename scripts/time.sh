get_currtime() {
    curr_date=$(date +'%Y%m%d')
    curr_time=$(date +'%H%M%S')
    curr_nano=$(date +'%N')
    curr_nano=${curr_nano::3}
    echo "${curr_date}_${curr_time}_${curr_nano}"
}