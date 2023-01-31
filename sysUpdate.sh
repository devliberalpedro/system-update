#!/bin/bash
#
# This script performs a full fedora system update. User can update services separated (ex. flatpak, dnf)

# Exit Immediately if a command fails
set -o errexit

ROOT_UID=0
MAX_DELAY=20							# max delay to enter root password
ARGS_COUNT=0                                        		# to avoid more then one argument
tui_root_login=

ALL_STATUS=true                                     		# perform all updates?
DNF_STATUS=false                                    		# perform dnf upgrade?
FLATPAK_STATUS=false                                		# perform flatpak update?
FIRMWARE_STATUS=false                               		# perform firmware update?

# Colors scheme
CDEF=" \033[0m"                                 		# default color
CCIN=" \033[0;36m"                              		# info color
CGSC=" \033[0;32m"                              		# success color
CRER=" \033[0;31m"                              		# error color
CWAR=" \033[0;33m"                              		# waring color
b_CDEF=" \033[1;37m"                            		# bold default color
b_CCIN=" \033[1;36m"                            		# bold info color
b_CGSC=" \033[1;32m"                            		# bold success color
b_CRER=" \033[1;31m"                            		# bold error color
b_CWAR=" \033[1;33m"                            		# bold warning color

# display message colors
prompt () {
	case ${1} in
		"-s"|"--success")
			echo -e "${b_CGSC}${@/-s/}${CDEF}";;          # print success message
		"-e"|"--error")
			echo -e "${b_CRER}${@/-e/}${CDEF}";;          # print error message
		"-w"|"--warning")
			echo -e "${b_CWAR}${@/-w/}${CDEF}";;          # print warning message
		"-i"|"--info")
			echo -e "${b_CCIN}${@/-i/}${CDEF}";;          # print info message
		*)
			echo -e "$@"
		;;
	 esac
}

# welcome message
prompt -s "\n\t********************************************\n\t*         'sysUpdate (by piotrek)'         *\n\t*--                                      --*\n\t*  run ./sysUpdate.sh -h for more options  *\n\t********************************************"

#######################################
#   :::::: F U N C T I O N S ::::::   #
#######################################

# Check command availability
function has_command() {
  command -v $1 &> /dev/null                        # with "&>", all output will be redirected.
}

# how to use
function usage() {
cat << EOF

Usage: $0 [OPTION]...

OPTIONS (assumes '-a' if no parameters is informed):
  -a, --all          run all update system (dnf, flatpal and fwupdmgr) [Default]
  -d, --dnf          run 'dnf upgrade --refresh'
  -f, --flatpak      run 'flatpak update'
  -x, --firmware     run firmware update commands (fwupdmgr)

  -h, --help         Show this help

EOF
}

function install() {
    if [[ "$ALL_STATUS" == true ]]; then
    prompt -i "\n=> Proceeding sudo dnf -y upgrade --refresh..."
    sudo dnf -y upgrade --refresh
    
    prompt -i "\n=> Proceeding flatpak -y update..."
    flatpak -y update
    
    prompt -i "\n=> Proceeding firmware upgrade commands..."
    prompt -i "  * sudo fwupdmgr refresh --force..."
    sudo fwupdmgr refresh --force
    prompt -i "  * sudo fwupdmgr get-updates..."
    sudo fwupdmgr get-updates
    sleep 3
    prompt -i "  * sudo fwupdmgr update..."
    sudo fwupdmgr update
  elif [[ "$DNF_STATUS" == true ]]; then
    prompt -i "\n=> Proceeding sudo dnf -y upgrade --refresh..."
    sudo dnf -y upgrade --refresh
  elif [[ "$FLATPAK_STATUS" == true ]]; then
    prompt -i "\n=> Proceeding flatpak -y update..."
    flatpak -y update
  elif [[ ${FIRMWARE_STATUS} ]]; then
    prompt -i "\n=> Proceeding firmware upgrade commands..."
    prompt -i "  * sudo fwupdmgr refresh --force..."
    sudo fwupdmgr refresh --force
    prompt -i "  * sudo fwupdmgr get-updates..."
    sudo fwupdmgr get-updates
    prompt -i "  * sudo fwupdmgr update..."
    sudo fwupdmgr update
  fi
}

#######################################################
#   :::::: A R G U M E N T   H A N D L I N G ::::::   #
#######################################################

while [[ $# -gt 0 ]]; do
  PROG_ARGS+=("${1}")
  dialog='false'

  if [ $ARGS_COUNT -ge 1 ]; then
    prompt -e "ERROR: Choose just one installation option..."
    prompt -i "Try '$0 --help' for more information.\n"
    exit 1
  else
    case "${1}" in
      -a|--all)
        ARGS_COUNT=$((ARGS_COUNT+1))
        shift
        ;;
      -d|--dnf)
        DNF_STATUS=true
        ALL_STATUS=false
        
        ARGS_COUNT=$((ARGS_COUNT+1))
        shift
        ;;
      -f|--flatpak)
        FLATPAK_STATUS=true
        ALL_STATUS=false

        ARGS_COUNT=$((ARGS_COUNT+1))
        shift
        ;;
      -x|--firmware)
        FIRMWARE_STATUS=true
        ALL_STATUS=false

        ARGS_COUNT=$((ARGS_COUNT+1))
        shift
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        prompt -e "ERROR: Unrecognized installation option '$1'."
        prompt -i "Try '$0 --help' for more information.\n"
        exit 1
        ;;
    esac
  fi     
done

#############################
#   :::::: M A I N ::::::   #
#############################0
# Check for root access and proceed if it is present
if [[ "$UID" -eq "$ROOT_UID" ]]; then
  install
# Check if password is cached (if cache timestamp has not expired yet)
elif sudo -n true 2> /dev/null && echo; then
  install
else
  # Ask for password
  if [[ -n ${tui_root_login} ]] ; then
    install
  else
    prompt -e "\n [ Error! ] -> Run me as root! "
    read -r -p " [ Trusted ] Specify the root password : " -t ${MAX_DELAY} -s
    if sudo -S echo <<< $REPLY 2> /dev/null && echo; then
      #Correct password, use with sudo's stdin
      install
    else
      #block for 3 seconds before allowing another attempt
      sleep 3
      prompt -e "\n [ Error! ] -> Incorrect password!\n"
      exit 1
    fi
  fi
fi

exit 0
