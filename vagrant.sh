#!/bin/bash

readonly DATE=`date +%Y/%m/%d-%H:%M:%S`
readonly LOG=/var/log/ee/build_setup/$DATE/setup.log
readonly LOGDIR=/var/log/ee/build_setup/$DATE/
readonly ee_distro_version=$(lsb_release -si)
readonly arch=$(uname -p)
box_list=(wheesy32 \
    wheesy64 \
    jessie32 \
    jessie64 \
    precise32 \
    precise64 \
    trusty32 \
    trusty64 \
    xenial32 \
    xenial64)

# Define echo function
# Blue color
function ee_lib_echo()
{
    echo $(tput setaf 4)$@$(tput sgr0)
}
# White color
function ee_lib_echo_info()
{
    echo $(tput setaf 7)$@$(tput sgr0)
}
# Red color
function ee_lib_echo_fail()
{
    echo $(tput setaf 1)$@$(tput sgr0)
}

# Capture errors
function ee_lib_error()
{
    echo "[ `date` ] $(tput setaf 1)$@$(tput sgr0)"
    exit $2
}

# Checking permissions
if [[ $EUID -ne 0 ]]; then
    ee_lib_echo_fail "Sudo privilege required..."
    exit 100
fi

# Execute: apt-get update
ee_lib_echo "Executing apt-get update, please wait..."
apt-get update &>> /dev/null

function install_tools() {

    if hash virtualbox 2> /dev/null; then
        echo
        ee_lib_echo "Virtualbox Installed. Continuing..."
        echo
    else
        echo
        ee_lib_echo "Virtualbox not found. Installing..."
        sudo apt-get install virtualbox -y &>> $LOG || ee_lib_error "Unable to create log directory $LOGDIR, exit status " $?
        echo
    fi
    if hash vagrant 2> /dev/null; then
        echo
        ee_lib_echo "Vagrant Installed. Continuing..."
        echo
    else
        echo
        ee_lib_echo "Vagrant not found. Installing..."
        echo
        case $arch in
            i686)
                wget -cq https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_i686.deb -O /tmp/vagrant.deb \
                || ee_lib_error "Failed to get Vagrant. Please check your Internet connection, Exit status " $? | tee -ai $LOG
                dpkg -i /tmp/vagrant.deb &>> $LOG \
                || ee_lib_error "Failed to install Vagrant. Please check $LOG for more information, Exit status " $?
                ;;
            x86_64)
                wget -cq https://releases.hashicorp.com/vagrant/1.8.1/vagrant_1.8.1_x86_64.deb -O /tmp/vagrant.deb \
                || ee_lib_error "Failed to get Vagrant. Please check your Internet connection, Exit status " $? | tee -ai $LOG
                dpkg -i /tmp/vagrant.deb &>> $LOG \
                || ee_lib_error "Failed to install Vagrant. Please check $LOG for more information, Exit status " $?
                ;;
            *)
                echo ee_lib_error "Sorry, Your platform is not supported now. Exit status " $? | tee -ai $LOG
                ;;
        esac
    fi
}

function install_box() {

    if hash vagrant 2> /dev/null; then
        echo
        ee_lib_echo "Adding boxes to vagrant. Please wait"
        for vbox in ${box_list[@]}; do
            vagrant box add $vbox | tee -ai $LOG || ee_lib_error "Unable to add wirtual machines to vagrant, exit status " $?
        done
        echo
    else
        echo
        ee_lib_echo "Vagrant not found. Please fix the error in $LOG and re-run the script. Exit status " $?
        echo
    fi
}

function main() {

	if [ ! -d $LOGDIR ]; then

	    ee_lib_echo "Creating log directory, please wait..."
	    mkdir -p $LOGDIR || ee_lib_error "Unable to create log directory $LOGDIR, exit status " $?

	    # Create log files
	    touch $LOG

	    # Keep log folder accessible to root only
	    chmod -R 700 $LOGDIR || ee_lib_error "Unable to change permissions for log folder, exit status " $?
	fi
    install_tools
    install_box
}

main