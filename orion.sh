#!/bin/bash
#=========================================
#Build script for OrionOS

#Give command line argument for the device :  ./orion.sh <flags> <device>. 

#=========================================
#FLAGS - 
# s = sync | f= force sync | r=repair sync
# c = clean 
# d = default (dirty)
#=========================================

#COLORS -
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
end=$'\e[0m'

#=========================================

#SET THE HOME DIRECTORY
if  [ -d ".repo" ] && [ -d "vendor/orion" ] ; then
	printf "\n$blu Setting ORION_HOME to `pwd` $end\n"
	ORION_HOME=$(pwd)
else
	printf "\n$red execute the script from home directory $end"
	exit 1
fi
#=========================================

eval ". build/envsetup.sh"

if [ "$2" == "" ]; then			#No device name
	
	printf "\n$red No device name entered.$end $grn Select from the foll:\n$end"
	cat  $ORION_HOME/vendor/orion/orion.devices
	
elif [ "$2" != "" ]; then		#Device name given. Check flags

	while getopts "s:f:r:c:d" opt; do
		case $opt in 
			s)					# sync
				printf "\n$blu Syncing repo$end\n"
				eval "repo sync --force-sync --no-clone-bundle"
				printf "\n$blu Repo sync done$end\n"
				;;
				
			f)					# force sync 
				printf "\n$blu Force syncing repo$end\n"
				eval "repo sync --force-sync --no-clone-bundle"
				printf "\n$blu Repo sync done$end\n"
				;;
			
			r)				#Fixed force sync 
				printf "\n$blu Fixing broken sync and syncing\n$end"
				printf " $red This step will remove your .repo/repo folder and resync repo projects. Continue (y/n)?$end"
				read ch
				if [ "$ch" == "y" ]; then
					printf "$blu removing .repo/repo\n$end"
					rm -rf ".repo/repo"
					eval "repo init -u git://github.com/TeamOrion/platform_manifest.git -b 6.0.1"
					eval "repo sync --force-sync --no-clone-bundle"


	
				elif [ "$ch" == "n" ]; then
					printf "$yel Aborted$end"
				else
					echo "$red Wrong option. Aborted$end"
				fi
				;;
			
			c)				#clean
				make clobber && make clean
				;;
			
			d)				#default
				printf "$blu building dirty (default)$end\n"
				make dirty
				;;
			
			\?) 
				echo "$yel Usage ./orion.sh -[s][f][r][c][d] [device name]$end"
				exit 1
				;;
				
		esac
	done
	
	#Check official support
		if grep -Fxq $2 `pwd`/vendor/orion/orion.devices
			then
				
				printf "\n$blu $2 is officially supported$end\n"
				export ORION_RELEASE=true
			else
				printf "$grn\ndevice is not supported officially; building unofficially$end\n"
		fi
		
	#Snap
	if [ "$2" == "oneplus3" ]; then			#OnePlus 3
		printf "$grn\nSetting Snap OnePlus 3$end\n"
		eval "cd packages/apps/Snap"
		eval "git checkout op3"
		eval "cd ../../.."
		eval "./op3.sh"
	else
		printf "$grn\nSetting Snap TO$end\n"
		eval "cd packages/apps/Snap"
		eval "git checkout 6.0.1"
		eval "git pull orion 6.0.1"
		eval "cd ../../.."
	fi

	# ccache
	printf "$grn\nSetting CCache$end\n"
	eval "export USE_CCACHE=1"
	eval "mkdir -p $HOME/.ccache/$2"
	eval "export CCACHE_DIR=$HOME/.ccache/$2"
	eval "prebuilts/misc/linux-x86/ccache/ccache -M 20G"
	
	# compile
	printf "$grn\nBuild Started$end\n"
	eval "brunch $2 2>&1 | tee $(date +%Y%m%d)-$device.log"
	
else 
	echo "$red Error$end"
fi
