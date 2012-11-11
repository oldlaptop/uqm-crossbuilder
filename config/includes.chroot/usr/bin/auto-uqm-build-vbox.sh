#! /bin/bash
#
# Automatically builds UQM and copies to the standard shared folder.
# 
# Paramaters:
#
# vanilla
#	Build vanilla
#
# balance
#	Build balance mod from git

# envvar: BALANCE_GIT_URL
#
# The URL of the network repository to get Balance Mod git from,
# as passed to git-clone.
BALANCE_GIT_URL="git://github.com/Roisack/Shiver-Balance-Mod.git"

mount /vbox_share

if [ `echo $@ | grep "vanilla"` ]; then
	mkdir /tmp/uqm
	tar -zxf /usr/src/uqm/uqm*.tgz -C /tmp/uqm
	cd /tmp/uqm/uqm-0.7.0
	cp /etc/skel/cross-build.sh .
	cp /usr/src/uqm/config.state.vanilla ./config.state
	echo "Configuring vanilla"
	sh cross-build.sh uqm reprocess_config
	sh cross-build.sh uqm

	if [ -f *.exe ]; then
		cp *.exe /vbox_share
	else
		echo "No executables found!"
		exit 1
	fi
fi

if [ `echo $@ | grep "balance"` ]; then
	cd /tmp
	git clone $BALANCE_GIT_URL
	cd Shiver-Balance-Mod
	cp /etc/skel/cross-build.sh .

	git checkout master
	cp /usr/src/uqm/config.state.balance ./config.state
	echo "Configuring balance"
	sh cross-build.sh uqm reprocess_config
	sh cross-build.sh uqm

	git checkout allow-retreat
	cp /usr/src/uqm/config.state.balance-retreat ./config.state
	echo "Configuring balance-retreat"
	sh cross-build.sh uqm reprocess_config
	sh cross-build.sh uqm

	if [ -f *.exe ]; then
		cp *.exe /vbox_share
	else
		echo "No executables found!"
		exit 1
	fi
fi
