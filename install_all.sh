#!/bin/bash

BASE_PATH=$(dirname $(realpath $0))
source ${BASE_PATH}/.myenv
source ${BASE_PATH}/scripts/colors.sh
source ${BASE_PATH}/scripts/time.sh
source ${BASE_PATH}/scripts/file.sh

DOWNLOAD_PATH=${BASE_PATH}/download
OLD_REPO=http://archive.ubuntu.com
NEW_REPO=${NEW_REPO}
GIT_MAIL=${GIT_MAIL}
GIT_ID=${GIT_ID}
IS_WSL=false
CHANGE_REPO=false
CURR_TIME="none"
PY_VERSION=3.7

VERBOSE=true

print() {
    msg="$1" # The entire string including spaces is received into one variable.
    mode=$2
    case $mode in
        TITLE  ) res=${Green}"$msg"${Off} ;;
        SUCCESS) res=${Yellow}"-> SUCCESS: $msg"${Off} ;;
        FAIL   ) res=${Yellow}"-> FAIL: $msg"${Off} ;;
        WARNING) res=${Yellow}"-> WARNING: $msg"${Off} ;;
        ERROR  ) res=${Yellow}"-> ERROR: $msg"${Off} ;;
        * )      res="$msg" ;;
    esac
    printf "$res\n"
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

ask_version() {
    msg="$1"
    default=$2
    while true; do
        read -rp "$(echo -e "${Cyan}$1 [default:${default}]: ${Off}")" ver
        case $ver in
            "") ret=${default}; break ;;
            * ) ret=${ver}; break ;;
        esac
    done
    echo $ret
}

ask_yesno() {
    msg="$1"
    while true; do
        read -rp "$(echo -e "${Cyan}${msg} [Y/n]: ${Off}")" yn
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
    if [ ${VERBOSE} = true ]; then
        "$@"
    else
        "$@" &> /dev/null
    fi
    # Don't put another command between a command and the result check.
    if [ $? -eq 0 ]; then
        print "${command}" SUCCESS
    else
        print "${command} (return $?)" FAIL
        exit
    fi
}

backup_file() {
    file=$1
    mycmd sudo cp ${file} ${file}_${CURR_TIME}_bak
}

replace_string() {
    if [ ${VERBOSE} = true ]; then
        func_name="${FUNCNAME[0]}"
        print "[${func_name}]"
        print " > File        : $1"
        print " > Old string  : $2"
        print " > New string  : $3"
    fi
    mycmd sudo sed -i "s|$2|$3|g" $1
}

ready() {
    title "READY"
    mycmd mkdir -p ${DOWNLOAD_PATH}
}

ready_apt() {
    title "READY APT"
    if [ ${CHANGE_REPO} = true ]; then
        if [ ! -z $NEW_REPO ]; then
            sources_file=/etc/apt/sources.list
            backup_file ${sources_file}
            replace_string ${sources_file} ${OLD_REPO} ${NEW_REPO}
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
    mycmd rm -r ${DOWNLOAD_PATH}
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
        # Empty string will be represented as white space when printing command.
        mycmd ssh-keygen -t rsa -N '' -f ~/.ssh/id_rsa
    else
        print "'~/.ssh/id_rsa' file is already exist." WARNING
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
    if [ ! -z "$GIT_MAIL" ] || [ ! -z "$GIT_ID" ]; then
        mycmd git config --global user.email ${GIT_MAIL}
        mycmd git config --global user.name  ${GIT_ID}
    else
        print "Failed to set git configuration." ERROR
        exit
    fi
}

install_python() {
    title "PYTHON${PY_VERSION}"
    major=${PY_VERSION::1}
    mycmd sudo apt -y install python${PY_VERSION} \
                                python${major}-pip \
                                python${PY_VERSION}-venv
    mycmd python${PY_VERSION} -m pip install --upgrade pip
}

install_bash() {
    title "BASHRC"
    if [ $(check_wsl) = true ]; then
        display="export DISPLAY=\$(cat /etc/resolv.conf | grep nameserver | awk '{print \$2}'):0.0"
        mycmd check_and_add_line "${display}" ~/.bashrc
    fi
}

CURR_TIME=$(get_currtime)
IS_WSL=$(check_wsl)
CHANGE_REPO=$(ask_yesno "Do you want to change Ubuntu repo?")
PY_VERSION=$(ask_version "Which python vers do you want to install?" ${PY_VERSION})

ready
ready_apt

install_core
install_bash
install_network
install_git
install_python

cleanup