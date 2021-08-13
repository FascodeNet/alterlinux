
ARGS         :=
BUILD_SCRIPT := build.sh
KERNEL       := zen
SHARE_OPTION := --boot-splash --comp-type "xz" --user "alter" --password "alter" --kernel "${KERNEL}" --debug --noconfirm
ARCH_x86_64  := --arch x86_64
ARCH_i686    := --arch i686
FULLBUILD    := -d -g -e --noconfirm
FULL_x86_64  := xfce cinnamon i3 plasma gnome
FULL_i686    := xfce lxde
CURRENT_DIR  := ${shell dirname $(dir $(abspath $(lastword $(MAKEFILE_LIST))))}/${shell basename $(dir $(abspath $(lastword $(MAKEFILE_LIST))))}

full:
	sudo ${CURRENT_DIR}/tools/fullbuild.sh ${FULLBUILD} -m x86_64 ${FULL_x86_64}
	sudo ${CURRENT_DIR}/tools/fullbuild.sh ${FULLBUILD} -m i686   ${FULL_i686}
	@make clean

basic-64 basic-32  cinnamon-64 cinnamon-32 gnome-64 gnome-32 i3-64 i3-32 lxde-64 lxde-32 plasma-64 releng-32 releng-64 serene-64 serene-32 xfce-64 xfce-32 xfce-pro-64:
	@$(eval ARCHITECTURE=${shell echo ${@} | rev | cut -d '-' -f 1 | rev })
	@$(eval CHANNEL=${shell echo ${@} | sed "s/-${ARCHITECTURE}//g"})
	@[[ -z "${CHANNEL}" ]] && echo "Empty Channel" && exit 1 || :
	@case ${ARCHITECTURE} in\
		"32") sudo ${CURRENT_DIR}/${BUILD_SCRIPT} ${ARGS} ${SHARE_OPTION} ${ARCH_i686} ${CHANNEL} ;;\
		"64") sudo ${CURRENT_DIR}/${BUILD_SCRIPT} ${ARGS} ${SHARE_OPTION} ${ARCH_x86_64} ${CHANNEL};;\
		*   ) echo "Unknown Architecture"; exit 1  ;; \
	esac
	@make clean

menuconfig/build/mconf::
	@mkdir -p menuconfig/build
	(cd menuconfig/build ; cmake -GNinja .. ; ninja -j4 )

menuconfig:menuconfig/build/mconf menuconfig-script/kernel_choice menuconfig-script/channel_choice
	@menuconfig/build/mconf menuconfig-script/rootconf

menuconfig-script/kernel_choice:system/kernel-x86_64 system/kernel-i686
	@${CURRENT_DIR}/tools/kernel-choice-conf-gen.sh
menuconfig-script/channel_choice:
	@${CURRENT_DIR}/tools/channel-choice-conf-gen.sh

build_option:
	@if [ ! -f .config ]; then make menuconfig ; fi
	${CURRENT_DIR}/tools/menuconf-to-alterconf.sh ${CURRENT_DIR}/.build_option

clean:
	@sudo ${CURRENT_DIR}/${BUILD_SCRIPT} --noconfirm clean

build:build_option
	$(eval BUILD_OPTION := $(shell cat ${CURRENT_DIR}/.build_option))
	@sudo ${CURRENT_DIR}/${BUILD_SCRIPT} ${BUILD_OPTION}

keyring::
	@sudo ${CURRENT_DIR}/tools/keyring.sh --alter-add --arch-add

wizard:
	@sudo ${CURRENT_DIR}/tools/wizard.sh

check:
	@bash -c 'shopt -s globstar nullglob; shellcheck -s bash --exclude=SC2068 -S error **/*.{sh,ksh,bash}'
	@bash -c 'shopt -s globstar nullglob; shellcheck -s bash --exclude=SC2068 -S error tools/*.{sh,ksh,bash}'
