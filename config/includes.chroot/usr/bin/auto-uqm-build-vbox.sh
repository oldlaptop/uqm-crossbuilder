#! /bin/bash
#
# Automatically builds UQM and copies to the standard shared folder.
# 
# Paramaters:
#
#	1: 'vanilla' to build vanilla, 'balance' to build balance
#	2: If building balance, the git revision to check out (legal to git-checkout)

# envvar: BALANCE_GIT_URL
#
# The URL of the network repository to get Balance Mod git from,
# as passed to git-clone.
BALANCE_GIT_URL="git://github.com/Roisack/Shiver-Balance-Mod.git"

# envvar: EFFECTS_PACK_NAME
#
# The name for our balance mod effects pack.
EFFECTS_PACK_NAME="improved-netmelee-effects.zip"

# envvar: SHARED_FOLDER
#
# Path to the VirtualBox shared folder
SHARED_DIR="/vbox_share"

case ${1} in
	vanilla)
		mkdir /tmp/uqm
		tar -zxf /usr/src/uqm/uqm*.tgz -C /tmp/uqm
		cd /tmp/uqm/uqm-0.7.0
		cp /etc/skel/cross-build.sh .
		cp /usr/src/uqm/config.state.vanilla ./config.state

		echo "Configuring vanilla"
		# TODO: Find some way of doing this that isn't a horrible, horrible hack.
		yes '
		' | sh cross-build.sh uqm config

		echo "Building vanilla"
		sh cross-build.sh uqm

		if [ -f *.exe ]
		then
			cp *.exe ${SHARED_DIR}
		else
			echo "No executables found!"
			exit 1
		fi
		;;
	balance)
		cd /tmp
		git clone $BALANCE_GIT_URL
		cd Shiver-Balance-Mod
		cp /etc/skel/cross-build.sh .

		git checkout master
		cp /usr/src/uqm/config.state.balance ./config.state
		echo "Configuring balance"

		# Make sure embedded icons are set up

		# TODO: make this more robust
		sed -i 's/.o)/.o) uqm.res/' Makefile.build

		i686-w64-mingw32-windres src/res/UrQuanMasters.rc -O coff -o uqm.res

		# TODO: Find some way of doing this that isn't a horrible, horrible hack.
		yes '
		' | sh cross-build.sh uqm config

		echo "Building balance"
		sh cross-build.sh uqm

		echo "Building effects pack"
		sh generate-effects-pack.sh

		if [ -f *.exe ]; then
			cp *.exe /vbox_share
		else
			echo "No executables found!"
			exit 1
		fi

		if [ -f content/addons/$EFFECTS_PACK_NAME ]; then
			cp content/addons/$EFFECTS_PACK_NAME /vbox_share
		else
			echo "Effects pack not found!"
			exit 1
		fi
		;;
	*)
		echo "Invalid UQM flavor; choose from vanilla or balance"
		exit 1
		;;
esac
