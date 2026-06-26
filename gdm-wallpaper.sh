#! /usr/bin/env bash
#
# gdm-wallpaper.sh — MacTahoe GDM Wallpaper Engine
# Copyright (c) 2026 eprahemi. All rights reserved.
#
# Fedora MacTahoe — Eprahemi Edition
# https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi
#
# This file is part of the MacTahoe GDM Theme (Fedora MacTahoe Edition).
# Licensed under the GPL v2.0.
#
# Design constraint: shell must not depend on working directory.
# Use 'ls "${REPO_DIR}/file"' instead of bare 'ls file'.
#
# Do not use "cd" directly. Use subshells instead:
#   ( cd some_dir && do_stuff ) or $( cd .. && do_stuff )
#
# Dependency installation should not be placed in this script.

###############################################################################
#                             VARIABLES & HELP                                #
###############################################################################

readonly REPO_DIR="$(dirname "$(readlink -m "${0}")")"
source "${REPO_DIR}/libs/lib-install.sh"

usage() {
  helpify_title

  helpify "" "" "GDM Wallpaper Options" "gdm"
  sec_title "-g, --gdm"                  ""                                          "  Apply login screen wallpaper"                        ""
  sec_helpify "1. -b, -background"       "[default|blank|IMAGE_PATH]"                "  Set login screen background image"                   "Default: macOS wallpaper"
  sec_helpify "2. -nd, -nodarken"        ""                                          "  Skip darken effect on background"                    ""
  sec_helpify "3. -nb, -noblur"          ""                                          "  Skip blur effect on background"                      ""

  helpify "-h, --help"    ""                                                         "  Show this help message"                              ""
}

###############################################################################
#                                  MAIN                                       #
###############################################################################

echo

while [[ $# -gt 0 ]]; do
  # Do not show dialogs here. This loop only checks for errors and shows help.
  #
  # Avoid exiting on errors here; collect them and display all at once.

  case "${1}" in
    -h|--help)
      need_help="true"; shift ;;
    -g|--gdm)
      gdm="true"; full_sudo "${1}"
      background="default"
      shift
      for variant in "${@}"; do
        case "${variant}" in
          -b|-background)
            check_param "${1}" "${1}" "${2}" "must" "must" "must" "false" && shift 2 || shift ;;
          -nd|-nodarken)
            no_darken="true"; shift ;;
          -nb|-noblur)
            no_blur="true"; shift ;;
        esac
      done

      if ! has_command gdm && ! has_command gdm3 && [[ ! -e /usr/sbin/gdm3 ]]; then
        prompt -e "'${1}' error: GDM is not installed on this system."
        has_any_error="true"
      fi ;;
    *)
      prompt -e "Unknown option: '${1}'. Use -h for help."
      has_any_error="true"; shift ;;
  esac
done

finalize_argument_parsing

#---------------------------APPLY WALLPAPER------------------------------------#

if [[ "${gdm}" == 'true' ]]; then
  prompt -i "Applying login screen wallpaper...\n"

  prompt -i "Processing background image...\n"
  install_beggy "${MACTAHOE_TMP_DIR}" "${colors[0]}"

  install_only_gdm_theme

  prompt -s "Done. Login screen wallpaper has been applied.\n"
fi

if [[ "${gdm}" == "false" ]]; then
  prompt -e "No component selected. Use -h to see available options."
  prompt -i "Example: ./gdm-wallpaper.sh --gdm --background /path/to/image.jpg\n"
  exit 1
fi

###############################################################################
#                              COPYRIGHT                                      #
###############################################################################
#
#  MacTahoe GDM Theme — Fedora MacTahoe Edition
#  Copyright (c) 2026 eprahemi
#  https://github.com/eprahemi/Fedora-MacTahoe-Eprahemi
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
###############################################################################
