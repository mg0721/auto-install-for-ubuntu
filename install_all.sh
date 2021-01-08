#!/bin/bash

base_dir=$(dirname $(realpath $0))
source ${base_dir}/.myenv
source ${base_dir}/scripts/colors.sh
source ${base_dir}/scripts/time.sh

download_dir=${base_dir}/download
old_repo=http://archive.ubuntu.com
new_repo=${new_repo}
is_wsl=false
change_repo=false
curr_time="none"

print() {
    msg="$1" # The entire string including spaces is received into one variable.
    mode=$2
    case $mode in
        TITLE  ) echo -e ${Green}"$msg"${Off} ;;
        SUCCESS) echo -e ${Yellow}"-> SUCCESS: $msg"${Off} ;;
        FAIL   ) echo -e ${Yellow}"-> FAIL: $msg"${Off} ;;
        ERROR  ) echo -e ${Yellow}"-> ERROR: $msg"${Off} ;;
        * )      echo -e "$msg" ;;
    esac
}

check_wsl() {
    ret=false
    if grep -qEi "(Microsoft|WSL)" /proc/version &> /dev/null; then
        ret=true
    fi
    echo $ret
}

title() {
    title_length=76
    length=${#1}
    padding=$(((${title_length}-length)/2))
    sep=$(printf '=%.0s' $(seq 1 $padding))
    print ""
    print "$sep $1 $sep" TITLE
}

ask_yesno() {
    while true; do
        read -rp "$(echo -e "${Cyan}$1 [Y/n]: ${Off}")" yn
        case $yn in
            [Yy]* ) ret=true; break ;;
            ""    ) ret=true; break ;;
            [Nn]* ) ret=false; break ;;
            * ) echo "Please answer yes or no." ;;
        esac
    done
    echo $ret
}

mycmd() {
    command="$@"
    $@ # Do not put another command between this command and the result check.
    if [ $? -eq 0 ]; then
        print "${command}" SUCCESS
    else
        print "${command} (return $?)" FAIL
        exit
    fi
}

backup_file() {
    file=$1
    mycmd sudo cp ${file} ${file}_${curr_time}_bak
}

replace_string() {
    func_name="${FUNCNAME[0]}"
    print "[${func_name}]"
    print " > File        : $1"
    print " > Old string  : $2"
    print " > New string  : $3"
    mycmd sudo sed -i "s|$2|$3|g" $1
}

ready() {
    title "READY"
    mycmd mkdir -p ${download_dir}
}

ready_apt() {
    title "READY APT"
    if [ ${change_repo} ]; then
        if [ ! -z $new_repo ]; then
            sources_file=/etc/apt/sources.list
            backup_file ${sources_file}
            replace_string ${sources_file} ${old_repo} ${new_repo}
        else
            print "Failed to replace strings in sources.list." ERROR
            exit
        fi
    fi
    mycmd sudo apt -y update
    mycmd sudo apt -y upgrade
}

cleanup() {
    title "CLEAN UP"
    mycmd rm -r ${download_dir}
    mycmd sudo apt -y autoremove
}

install_network() {
    title "NETWORK"
    mycmd sudo apt -y install net-tools
    mycmd sudo apt -y install ssh
    mycmd sudo apt -y remove openssh-server
    mycmd sudo apt -y install openssh-server
    mycmd sudo service ssh --full-restart
    if [ ! -f ~/.ssh/id_rsa ]; then
        ssh-keygen -t rsa -N \"\" -f ~/.ssh/id_rsa
    fi
}

install_core() {
    title "CORE"
    mycmd sudo apt -y install dos2unix
    mycmd sudo apt -y install unrar zip unzip
}

install_git() {
    title "GIT"
    mycmd sudo apt -y install git git-lfs
    if [ ! -z "$git_mail" ] || [ ! -z "$git_id" ]; then
        mycmd git config --global user.email ${git_mail}
        mycmd git config --global user.name  ${git_id}
    else
        print "Failed to set git configuration." ERROR
        exit
    fi
}

curr_time=$(get_currtime)
is_wsl=$(check_wsl)
change_repo=$(ask_yesno "Do you want to change Ubuntu repo?")

ready
ready_apt

install_core
install_network
install_git

cleanup
