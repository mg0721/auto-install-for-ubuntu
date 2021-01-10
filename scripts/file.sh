check_line_exists() {
    line="$1"
    file=$2
    ret=false
    if grep -q -x -F -e "$line" < $file; then
        ret=true
    fi
    echo $ret
}

add_line() {
    line="$1"
    file=$2
    printf '%s\n' "$line" >> $file
}

check_and_add_line() {
    line="$1"
    file=$2
    ret=$(check_line_exists "$line" $file)
    if [ $ret = false ]; then
        add_line "$line" $file
    fi
    echo $?
}