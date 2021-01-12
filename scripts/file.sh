file_check_line_exists() {
    local -r line="$1"
    local -r file="$2"
    local ret=false
    if grep -q -x -F -e "$line" < "$file"; then
        ret=true
    fi
    echo $ret
}

file_add_line() {
    local -r line="$1"
    local -r file="$2"
    echo -e "${line}" >> "${file}"
}

file_check_and_add_line() {
    local -r line="$1"
    local -r file="$2"
    local res=$(file_check_line_exists "$line" "$file")
    if [ $res = false ]; then
        file_add_line "${line}" "${file}"
    fi
}

file_replace_string() {
    local -r file="$1"
    local -r old="$2"
    local -r new="$3"
    mycmd sudo sed -i "s|${old}|${new}|g" "${file}"
}