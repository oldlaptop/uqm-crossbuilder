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
export BALANCE_GIT_URL="https://github.com/Roisack/Shiver-Balance-Mod.git"

mount /vbox_share

if [ `echo $@ | grep "vanilla"` ]; then
	tar -zxf /usr/src/uqm/uqm*.tgz -C /tmp/uqm
	cd /tmp/uqm/
	cp /etc/skel/cross-build.sh .
	cp /usr/src/uqm/config.state.vanilla ./config.state
	echo "Configuring vanilla" >> /vbox_share/build_log
	sh cross-build.sh uqm reprocess_config 2>&1 >> /vbox_share/build_log
	sh cross-build.sh uqm 2>&1 >> /vbox_share/build_log

	if [ -f *.exe ]; then
		cp *.exe /vbox_share
	else
		echo "No executables found!" >> /vbox_share/build_log
		exit 1
	fi
fi

if [ `echo $@ | grep "balance" $@` ]; then
	cd /tmp
	git clone ${BALANCE_GIT_URL}
	cd Shiver-Balance-Mod
	cp /etc/skel/cross-build.sh .

	git checkout master
	cp /usr/src/uqm/config.state.balance ./config.state
	echo "Configuring balance" >> /vbox_share/build_log
	sh cross-build.sh uqm reprocess_config 2>&1 >> /vbox_share/build_log
	sh cross-build.sh uqm 2>&1 >> /vbox_share/build_log

	git checkout allow-retreat
	cp /usr/src/uqm/config.state.balance-retreat ./config.state
	echo "Configuring balance-retreat" >> /vbox_share/build_log
	sh cross-build.sh uqm reprocess_config 2>&1 >> /vbox_share/build_log
	sh cross-build.sh uqm 2>&1 >> /vbox_share/build_log

	if [ -f *.exe ]; then
		cp *.exe /vbox_share
	else
		echo "No executables found!" >> /vbox_share/build_log
		exit 1
	fi
fi