#!/bin/bash
#
# This script builds UQM in a Virtual Machine for Windows
#
# Parameters:
#
# vanilla:
#       Builds Ur-Quan Masters vanilla code
#
# balance:
#       Builds Shiver's Balance Mod code
#
#
#
# The script first creates a VirtualMachine and sets its properties
# then starts that machine and executes a build script inside it
# The produced executables and build logs are then found in the shared folder
#

SHARED_DIR="uqm-crossbuilder-share"
IMAGE_NAME="uqm-crossbuilder.iso"
CURRENT_DIR=`pwd`
LIVE_USER="fwiffo"
LIVE_PASSWORD="live"
VANILLA_EXE="uqm.exe"
BALANCE_EXE="uqm-improved-netmelee.exe"
#BALANCE_RETREAT_EXE="uqm-balance-retreat.exe"
EFFECTS_PACK="improved-netmelee-effects.zip"
BUILD_VANILLA="false"
BUILD_BMOD="false"
BUILD_SCRIPT_PATH="/usr/bin/auto-uqm-build-vbox.sh"
USEOLDSYNTAX=false	# Old VirtualBox installations use --wait-for stdout instead of wait-stdout, along with other differences
WAITSTDOUT="--wait-stdout"
WAITSTDERR="--wait-stderr"
NET_IFACE_TYPE="nat"
HOST_IFACE="eth0"

cleanup ()
{
    echo "## Shutting down the VM ##"
    vboxmanage controlvm "UQM_crossbuilder_001" poweroff
    sleep 5
    echo "== Deleting the VM"
    vboxmanage unregistervm "UQM_crossbuilder_001" -delete
    echo "== Deleting the temporary hard drive"
    rm ./testhd.vdi
}

if [ `echo $@ | grep "clean"` ]; then
	echo "Cleaning"
	cleanup
	exit 1
fi

if [ `echo $@ | grep "vanilla"` ]; then
    export BUILD_VANILLA="true"
elif [ `echo $@ | grep "balance"` ]; then
    export BUILD_BMOD="true"
else
    echo "!! You must specify build target: either vanilla or balance"
    exit 1
fi

if [ `echo $@ | grep "old_virtualbox"` ]; then
	$USEOLDSYNTAX = true
	$WAITSTDOUT = "--wait-for stdout"
	$WAITSTDERR = "--wait-for stderr"
fi

if [ ! -f ./$IMAGE_NAME ]; then
    echo "!! You need to have the live CD image $IMAGE_NAME in the current directory"
    exit 2
fi

echo "## Found live CD image, all good ##"

if [ ! -d $SHARED_DIR ]; then
    echo "== Shared dir does not exist. Creating it at $CURRENT_DIR/$SHARED_DIR"
    mkdir $SHARED_DIR
    if [ $? -ne 0 ]; then
        echo "!! Problem creating shared directory. Do you have permissions for this folder?"
        exit 3
    else
        echo "== Shared directory created"
    fi
else
    echo "== Shared dir already exists, verifying permissions" 
    touch $SHARED_DIR/testfile
    if [ $? -ne 0 ]; then
        echo "!! Problem testing shared directory. Are the permissions in order?"
        exit 3
    else
        echo "All good"
    fi
fi

echo "## Creating the Virtual Machine ##"
vboxmanage createvm --name "UQM_crossbuilder_001" --register
if [ $? -ne 0 ]; then
    echo "!! vboxmanage returned an error, canceling"
    vboxmanage unregistervm "UQM_crossbuilder_001" -delete
    exit 5
fi

# Give it a hard drive
vboxmanage createhd --filename ./testhd --size 1024
if [ $? -ne 0 ]; then
    echo "!! vboxmanage returned an error while creating a hard drive, canceling"
    rm ./testhd*
    vboxmanage unregistervm "UQM_crossbuilder_001" -delete
    exit 5
fi

# Give it a CD rom drive
vboxmanage storagectl "UQM_crossbuilder_001" --name "cdrom_drive" --add ide --controller PIIX4
if [ $? -ne 0 ]; then
    echo "!! vboxmanage returned an error while creating a cd rom drive, canceling"
    vboxmanage unregistervm "UQM_crossbuilder_001" -delete
    rm ./testhd*
    exit 5
fi

# Set up a virtual NIC
vboxmanage modifyvm "UQM_crossbuilder_001" --nic1 $NET_IFACE_TYPE
if [ $NET_IFACE_TYPE = "bridged" ]; then
    vboxmanage modifyvm "UQM_crossbuilder_001" --bridgeadapter1 $HOST_IFACE
fi

echo "== Giving the live image to the Virtual Machine: $IMAGE_NAME"
vboxmanage storageattach "UQM_crossbuilder_001" --storagectl "cdrom_drive" --port 0 --device 0 --type dvddrive --medium $IMAGE_NAME
if [ $? -ne 0 ]; then
    echo "!! vboxmanage returned an error while inputting the live image, exiting"
    vboxmanage unregistervm "UQM_crossbuilder_001" -delete
    rm ./testhd*
fi

echo "== Creating a shared folder"
vboxmanage sharedfolder add "UQM_crossbuilder_001" --name "uqm-crossbuilder-share" --hostpath $CURRENT_DIR/$SHARED_DIR
if [ $? -ne 0 ]; then
    echo "!! vboxmanage returned an error while creating the shared folder at $CURRENT_DIR/$SHARED_DIR"
    vboxmanage unregistervm "UQM_crossbuilder_001" -delete
    rm ./testhd*
fi

echo "## Starting the Virtual Machine ##"
vboxmanage startvm "UQM_crossbuilder_001" --type headless
if [ $? -ne 0 ]; then
    echo "!! vboxmanage returned an error while starting the VM, canceling"
    cleanup
    exit 5
fi

echo "== Waiting 10 seconds to make sure the boot menu has time to load"
sleep 10

# Send keyboard key "enter" to pass the boot menu
echo "== Sending enter to boot menu"
vboxmanage controlvm "UQM_crossbuilder_001" keyboardputscancode 1c
if [ $? -ne 0 ]; then
    echo "!! vboxmanage returned an error while sending enter to the VM, canceling"
    cleanup
    exit 5
fi

echo "## Waiting 30 seconds for the system to load ##"
echo " "
echo "##################################################"
echo "After this the build will begin                   "
echo "The build probably takes a while, so wait warmly  "
echo "##################################################"

sleep 30

echo "## Mounting shared folder ##"
vboxmanage guestcontrol "UQM_crossbuilder_001" execute "/usr/bin/sudo" --username $LIVE_USER --password LIVE_PASSWORD --verbose $WAITSTDOUT $WAITSTDERR "/bin/mkdir" "/vbox_share"
if [ $? -ne 0 ]; then
    echo "!! Error at creating shared folder on guest"
    cleanup
    exit 6
fi

echo "== Folder created on guest"

vboxmanage guestcontrol "UQM_crossbuilder_001" execute "/usr/bin/sudo" --username $LIVE_USER --password LIVE_PASSWORD --verbose $WAITSTDOUT $WAITSTDERR -- "/bin/mount" "-tvboxsf" $SHARED_DIR "/vbox_share"
if [ $? -ne 0 ]; then
    echo "!! Error at mounting shared folder on guest"
    cleanup
    exit 6
fi

echo "== Shared folder mounted successfully"

echo "== Testing shared folder"
vboxmanage guestcontrol "UQM_crossbuilder_001" execute "/usr/bin/sudo" --username $LIVE_USER --password LIVE_PASSWORD --verbose $WAITSTDOUT $WAITSTDERR -- "/bin/touch" "/vbox_share/touched_file"
if [ $? -ne 0 ]; then
	echo "!! Error at testing shared directory. This is probably an error with your VirtualBox version"
	cleanup
	exit 6
fi

if [ ! -f $SHARED_DIR/touched_file ]; then
	echo "!! The Virtual Machine was able to create a file in the shared folder, but it wasn't received in the master OS"
	echo "!! This probably means that the guest OS didn't properly mount the shared directory"
	cleanup
	exit 7
fi

echo "== Shared folder works"

echo "## Sending the build command to the Virtual Machine ##"

if [ $BUILD_VANILLA = "true" ]; then
    vboxmanage guestcontrol "UQM_crossbuilder_001" execute "/usr/bin/sudo" --username $LIVE_USER --password LIVE_PASSWORD --verbose $WAITSTDOUT $WAITSTDERR -- "/bin/sh" "$BUILD_SCRIPT_PATH" "vanilla"
    if [ $? -ne 0 ]; then
        echo "!! VirtualBox returned an error while sending the build command, canceling"
        cleanup
        exit 6
    else
        echo "== All good"
        cleanup
    fi
fi

if [ $BUILD_BMOD = "true" ]; then
    vboxmanage guestcontrol "UQM_crossbuilder_001" execute "/usr/bin/sudo" --username $LIVE_USER --password LIVE_PASSWORD --verbose $WAITSTDOUT $WAITSTDERR -- "/bin/sh" "$BUILD_SCRIPT_PATH" "balance"
    if [ $? -ne 0 ]; then
        echo "!! VirtualBox returned an error while sending the build command, canceling"
        cleanup
        exit 6
    else
        echo "== All good"
        cleanup
    fi
fi

if [ $BUILD_VANILLA = "true" ]; then
    if [ -f $SHARED_DIR/$VANILLA_EXE ]; then
        echo "== Copying the binaries to the current directory"
        cp $SHARED_DIR/$VANILLA_EXE $CURRENT_DIR
    else
        echo "!! Binary not found. Something went wrong :("
    fi
fi

if [ $BUILD_BMOD = "true" ]; then
    if [ -f $SHARED_DIR/$BALANCE_EXE ]; then
        echo "== Copying the Balance Mod exe to current dir: $BALANCE_EXE"
        cp $SHARED_DIR/$BALANCE_EXE $CURRENT_DIR
    else
        echo "!! Balance Mod exe not found. Something went wrong :("
    fi
#     if [ -f $SHARED_DIR/$BALANCE_RETREAT_EXE ]; then
#         echo "== Copying the balance mod retreat exe to the current dir: $BALANCE_RETREAT_EXE"
#         cp $SHARED_DIR/$BALANCE_RETREAT_EXE $CURRENT_DIR
#     else
#         echo "!! Balance Mod Retreat exe not found. Something went wrong :("
#    fi
    if [ -f $SHARED_DIR/$EFFECTS_PACK ]; then
        echo "== Copying the effects pack to current dir: $EFFECTS_PACK"
        cp $SHARED_DIR/$EFFECTS_PACK $CURRENT_DIR
    else
        echo "!! Effecting pack not found. Something went wrong :("
    fi
fi

echo "-- All done! =)"

