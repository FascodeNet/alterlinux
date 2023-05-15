#!/usr/bin/env bash
# shellcheck disable=SC2154

make_profiledef(){
    local _base="${template_dir}/profiledef.sh" _args=()
    

    parse_template "$_base" \
        iso_name iso_label iso_publisher iso_application \
        iso_version install_dir arch noiso noefi \
    > "$work_dir/profile/profiledef.sh"
}


