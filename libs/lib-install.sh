# Design constraint: shell must not depend on working directory.
# Use 'ls "${REPO_DIR}/file"' instead of bare 'ls file'.
#
# Do not use "cd" directly. Use subshells instead:
#   ( cd some_dir && do_stuff ) or $( cd .. && do_stuff )

###############################################################################
#                                VARIABLES                                    #
###############################################################################

source "${REPO_DIR}/libs/lib-core.sh"
MACTAHOE_SOURCE+=("lib-install.sh")

###############################################################################
#                              DEPENDENCIES                                   #
###############################################################################

# Be careful of some distro mechanism, some of them use rolling-release
# based installation instead of point-release, e.g., Arch Linux

# Rolling-release based distro doesn't have a seprate repo for each different
# build. This can cause a system call error since an app require the compatible
# version of dependencies. In other words, if you install an new app (which you
# definitely reinstall/upgrade the dependency for that app), but your other
# dependencies are old/expired, you'll end up with broken system.

# That's why we need a full system upgrade there

#---------------------SWUPD--------------------#
# 'swupd' bundles just don't make any sense. It takes about 30GB of space only
# for installing a util, e.g. 'sassc' (from 'desktop-dev' bundle, or
# 'os-utils-gui-dev' bundle, or any other 'sassc' provider bundle)

# Manual package installation is needed for that, but please don't use 'dnf'.
# The known worst impact of using 'dnf' is you install 'sassc' and then you
# remove it, and you run 'sudo dnf upgrade', and boom! Your 'sudo' and other
# system utilities have gone!

#----------------------APT---------------------#
# Some apt version doesn't update the repo list before it install some app.
# It may cause "unable to fetch..." when you're trying to install them

#--------------------PACMAN--------------------#
# 'Syu' (with a single y) may causes "could not open ... decompression failed"
# and "target not found <package>". We got to force 'pacman' to update the repos

#--------------------OTHERS--------------------#
# Sometimes, some Ubuntu distro doesn't enable automatic time. This can cause
# 'Release file for ... is not valid yet'. This may also happen on other distros

#============================================#

#-------------------Prepare------------------#
installation_sorry() {
  prompt -w "Your distro is not officially supported yet."
  prompt -i "Ensure all required dependencies are installed. Continuing in 15 seconds..."
  prompt -i "Press Ctrl+C to cancel if dependencies are missing."
  start_animation; sleep 15; stop_animation
}

prepare_deps() {
  local remote_time=""
  local local_time=""

  prompt -i "Checking internet connection..."
 
  local_time="$(date -u "+%s")"
 
  if ! remote_time="$(get_utc_epoch_time)"; then
    prompt -e "Internet connection issue detected.\n"; exit 1
  fi
 
  # 5 minutes is the maximum reasonable time delay, so we choose '4' here just
  # in case
  if (( local_time < remote_time-(4*60) )); then
    prompt -w "System clock is incorrect."
    prompt -i "Updating system clock..."
    # Add "+ 25" here to accomodate potential time delay by sudo prompt
    sudo date -s "@$((remote_time + 25))"
 
    if has_command hwclock; then
      sudo hwclock --systohc
    fi
  fi
}

prepare_swupd() {
  [[ "${swupd_prepared}" == "true" ]] && return 0

  local remove=""
  local ver=""
  local conf=""
  local dist=""

  if has_command dnf; then
    prompt -w "Clear Linux: 'dnf' is installed and may cause conflicts."
    confirm remove "Clear Linux: remove 'dnf'?"; echo
  fi
 
  if ! sudo swupd update -y; then
    ver="$(curl -s -o - "${swupd_ver_url}")"
    dist="NAME=\"Clear Linux OS\"\nVERSION=1\nID=clear-linux-os\nID_LIKE=clear-linux-os\n"
    dist+="VERSION_ID=${ver}\nANSI_COLOR=\"1;35\"\nSUPPORT_URL=\"https://clearlinux.org\"\nBUILD_ID=${ver}"
 
    prompt -w "\n  Clear Linux: 'swupd' is broken."
    prompt -i "Clear Linux: Patching version detection and retrying...\n"
    sudo rm -rf "/etc/os-release"; echo -e "${dist}" | sudo tee                         "/usr/lib/os-release" > /dev/null
    sudo ln -s "/usr/lib/os-release" "/etc/os-release"

    sudo swupd update -y
  fi

  if ! has_command bsdtar; then sudo swupd bundle-add libarchive; fi
  if [[ "${remove}" == "y" ]]; then sudo swupd bundle-remove -y dnf; fi

  swupd_prepared="true"
}

install_swupd_packages() {
  if [[ ! "${swupd_packages}" ]]; then
    swupd_packages=$(curl -s -o - "${swupd_url}" | awk -F '"' '/-bin-|-lib-/{print $2}')
  fi

  for key in "${@}"; do
    for pkg in $(echo "${swupd_packages}" | grep -F "${key}"); do
      curl -s -o - "${swupd_url}/${pkg}" | sudo bsdtar -xf - -C "/"
    done
  done
}

prepare_install_apt_packages() {
  local status="0"

  # sudo apt update -y
  sudo apt install -y "${@}" || status="${?}"

  if [[ "${status}" == "100" ]]; then
    prompt -w "\n  APT: Repository lists may be corrupted."
    prompt -i "APT: Cleaning repository lists and retrying...\n"
    sudo apt clean -y; sudo rm -rf /var/lib/apt/lists
    sudo apt update -y; sudo apt install -y "${@}"
  fi
}

prepare_xbps() {
  [[ "${xbps_prepared}" == "true" ]] && return 0

  # 'xbps-install' requires 'xbps' to be always up-to-date
  sudo xbps-install -Syu xbps

  # System upgrading can't remove the old kernel files by it self. It eats the
  # boot partition and may cause kernel panic when there is no enough space
  sudo vkpurge rm all; sudo xbps-install -Syu

  xbps_prepared="true"
}

#-----------------Deps-----------------#

install_theme_deps() {
  if ! has_command sassc; then
    prompt -w "Required dependency 'sassc' is missing."
    prepare_deps

    if has_command zypper; then
      sudo zypper in -y sassc
    elif has_command swupd; then
      prepare_swupd && install_swupd_packages sassc libsass
    elif has_command apt; then
      prepare_install_apt_packages sassc
    elif has_command dnf; then
      sudo dnf install -y sassc
    elif has_command yum; then
      sudo yum install -y sassc
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed sassc
    elif has_command xbps-install; then
      prepare_xbps && sudo xbps-install -Sy sassc
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y install sassc
    else
      installation_sorry
    fi
  fi

  if ! has_command glib-compile-resources; then
    prompt -w "Required dependency 'glib2.0' is missing."
    prepare_deps

    if has_command zypper; then
      sudo zypper in -y glib2-devel
    elif has_command swupd; then
      prepare_swupd && sudo swupd bundle-add libglib
    elif has_command apt; then
      prepare_install_apt_packages libglib2.0-dev-bin
    elif has_command dnf; then
      sudo dnf install -y glib2-devel
    elif has_command yum; then
      sudo yum install -y glib2-devel
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed glib2
    elif has_command xbps-install; then
      prepare_xbps && sudo xbps-install -Sy glib-devel
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y install glib2
    else
      installation_sorry
    fi
  fi

  if ! has_command xmllint; then
    prompt -w "Required dependency 'xmllint' is missing."
    prepare_deps

    if has_command zypper; then
      sudo zypper in -y libxml2-tools
    elif has_command swupd; then
      prepare_swupd && sudo swupd bundle-add libxml2
    elif has_command apt; then
      prepare_install_apt_packages sassc libxml2-utils
    elif has_command dnf; then
      sudo dnf install -y libxml2
    elif has_command yum; then
      sudo yum install -y libxml2
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed libxml2
    elif has_command xbps-install; then
      prepare_xbps && sudo xbps-install -Sy libxml2
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y install libxml2
    else
      installation_sorry
    fi
  fi
}

install_beggy_deps() {
  if ! has_command magick; then
    prompt -w "Required dependency 'ImageMagick' is missing."
    prepare_deps; stop_animation

    if has_command zypper; then
      sudo zypper in -y ImageMagick
    elif has_command swupd; then
      prepare_swupd && sudo swupd bundle-add ImageMagick
    elif has_command apt; then
      prepare_install_apt_packages imagemagick
    elif has_command dnf; then
      sudo dnf install -y ImageMagick
    elif has_command yum; then
      sudo yum install -y ImageMagick
    elif has_command pacman; then
      sudo pacman -Syyu --noconfirm --needed imagemagick
    elif has_command xbps-install; then
      prepare_xbps && sudo xbps-install -Sy ImageMagick
    elif has_command eopkg; then
      sudo eopkg -y upgrade; sudo eopkg -y install imagemagick
    else
      installation_sorry
    fi
  fi
}

install_beggy() {
  local TARGET_DIR="${1}"
  local color="$(destify ${2})"
  local CONVERT_OPT=""
  local IM_CMD=""

  if [[ "${color}" == '-Light' ]]; then
    local IMG_COLOR='-day'
  elif [[ "${color}" == '-Dark' ]]; then
    local IMG_COLOR='-night'
  fi

  [[ "${no_blur}" == "false" ]] && CONVERT_OPT+=" -scale 1280x -blur 0x50 "
  [[ "${no_darken}" == "false" ]] && CONVERT_OPT+=" -fill black -colorize 45% "

  mkdir -p                                                                                     "${TARGET_DIR}"

  # Resolve ImageMagick command: prefer 'magick' (ImageMagick 7+), fallback to 'convert' (ImageMagick 6)
  IM_CMD="$(command -v magick || command -v convert || true)"
  if [[ -z "${IM_CMD}" ]]; then
    # Try to install imagemagick via distro package helpers
    install_beggy_deps
    IM_CMD="$(command -v magick || command -v convert || true)"
  fi

  if [[ -z "${IM_CMD}" ]]; then
    prompt -e "ImageMagick not found after installation attempt.\n"
    exit 1
  fi

  case "${background}" in
    blank)
      ;;
    default)
      install_beggy_deps
      "${IM_CMD}" ${REPO_DIR}/wallpaper/MacTahoe${IMG_COLOR}.jpeg ${CONVERT_OPT} ${TARGET_DIR}/background.png
      ;;
    *)
      if [[ "${no_blur}" == "false" || "${no_darken}" == "false" ]]; then
        install_beggy_deps
        "${IM_CMD}" ${background} ${CONVERT_OPT} ${TARGET_DIR}/background.png
      else
        cp -r "${background}"                                                                  "${TARGET_DIR}/background.png"
      fi
      ;;
  esac
}

install_only_gdm_theme() {
  local TARGET=

  if check_theme_file "$POP_OS_GR_FILE"; then
    TARGET="${POP_OS_GR_FILE}"
  elif check_theme_file "$YARU_GR_FILE"; then
    TARGET="${YARU_GR_FILE}"
  elif check_theme_file "$ZORIN_GR_DARK_FILE"; then
    TARGET="${ZORIN_GR_DARK_FILE}"
  elif check_theme_file "$ZORIN_GR_LIGHT_FILE"; then
    TARGET="${ZORIN_GR_LIGHT_FILE}"
  elif check_theme_file "$MISC_GR_FILE"; then
    TARGET="${MISC_GR_FILE}"
  else
    prompt -e "\n  GDM theme file not found. Aborting."; exit 1
  fi

  install_theme_deps; install_beggy "${MACTAHOE_TMP_DIR}" "${colors[0]}"

  local GDM_TMP_DIR="${MACTAHOE_TMP_DIR}/gdm"

  mkdir -p                                                                                    "${GDM_TMP_DIR}"
  cp -r "${REPO_DIR}/other/gdm/theme"                                                         "${GDM_TMP_DIR}"
  cp -r "${MACTAHOE_TMP_DIR}/background.png"                                                  "${GDM_TMP_DIR}/theme/background.png"

  # For Kali Linux GDM >>>
  local KALI_BACKGROUND_FOLDER="/usr/share/desktop-base/kali-theme/login"

  if [[ -f "${KALI_BACKGROUND_FOLDER}/background-blurred" ]]; then
    backup_file "${KALI_BACKGROUND_FOLDER}/background-blurred"
    cp -rf "${MACTAHOE_TMP_DIR}/background.png"                                               "${KALI_BACKGROUND_FOLDER}/background-blurred"
  fi
  # For Kali Linux GDM <<<

  backup_file "${TARGET}"
  glib-compile-resources --sourcedir="${GDM_TMP_DIR}/theme" --target="${TARGET}" "${GDM_GR_XML_FILE}"
}
