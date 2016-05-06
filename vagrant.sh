#!/bin/bash

readonly DATE=$(date +%Y-%m-%d-%H:%M)
readonly LOG=/var/log/ee/build_setup/$DATE/setup.log
readonly LOGDIR=/var/log/ee/build_setup/$DATE/
readonly ee_distro_version=$(lsb_release -si)
readonly arch=$(uname -p)
box_list=('box-cutter/debian79-i386' \
    'debian/wheezy64' \
    'boxcutter/debian80-i386' \
    'debian/jessie64' \
    'ubuntu/precise32' \
    'ubuntu/precise64' \
    'ubuntu/trusty32' \
    'ubuntu/trusty64' \
    'ubuntu/xenial32' \
    'ubuntu/xenial64')

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
        sudo apt-get install virtualbox -y &>> $LOG || ee_lib_fail "Unable to create log directory $LOGDIR, exit status " $?
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
        ee_lib_echo "vagrant will be initialized in current directory(`pwd`). Do you wish to continue[Y/n]: "
        read ans1
	case $ans1 in
	    n|N)
	    ee_lib_error "Exiting now... " $?
	    ;;
	esac
	echo
        ee_lib_echo "Would you like to use our Vagrantfile[Y/n]: "
	read ans2
	if [ -z $ans2 ] || [ $ans2 = "Y" ] || [ $ans2 = "y" ]; then
            wget -cq https://raw.githubusercontent.com/EasyEngine/build-test/master/res/Vagrantfile -O ./Vagrantfile
        fi
	if [ ! -e "./Vagrantfile" ]; then
	    ee_lib_echo "Initializing with default Vagrantfile..."
            vagrant init	
	fi
	ee_lib_echo "Adding boxes to vagrant. Please wait..."
        for vbox in ${box_list[@]}; do
	    if grep --quiet -Re "$vbox" $HOME/.vagrant.d/boxes/ &> /dev/null; then
		ee_lib_echo "$vbox already present, Skipping..."
	    else
	        vagrant box add $vbox --provider virtualbox | tee -ai $LOG || ee_lib_error "Unable to add $vbox to vagrant, exit status " $?
	    fi
        done
        echo
    else
        echo
        ee_lib_echo "Vagrant not found. Please fix the error in $LOG and re-run the script. Exit status " $?
        echo
   fi
   chown -R $SUDO_USER:$SUDO_USER ./.vagrant/ &>> /dev/null
   chown -R $SUDO_USER:$SUDO_USER $HOME/.vagrant.d/ &>> /dev/null
   chown -R $SUDO_USER:$SUDO_USE ./Vagrantfile
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
