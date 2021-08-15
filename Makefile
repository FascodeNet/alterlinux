
ARGS         :=
BUILD_SCRIPT := build.sh
KERNEL       := zen
SHARE_OPTION := --boot-splash --comp-type "xz" --user "alter" --password "alter" --kernel "${KERNEL}" --noconfirm
ARCH_x86_64  := --arch x86_64
ARCH_i686    := --arch i686
FULLBUILD    := -d -g -e --noconfirm
DEBUG_OPTION := --debug --log
DEBUG        := false
FULL_x86_64  := xfce cinnamon i3 plasma gnome
FULL_i686    := xfce lxde
CURRENT_DIR  := ${shell dirname $(dir $(abspath $(lastword $(MAKEFILE_LIST))))}/${shell basename $(dir $(abspath $(lastword $(MAKEFILE_LIST))))}

ifeq (${DEBUG},true)
	ARGS += ${ARGS} ${DEBUG_OPTION}
endif

full:
	sudo ${CURRENT_DIR}/tools/fullbuild.sh ${FULLBUILD} -m x86_64 ${FULL_x86_64}
	sudo ${CURRENT_DIR}/tools/fullbuild.sh ${FULLBUILD} -m i686   ${FULL_i686}
	@make clean

basic-ja-64    basic-en-64    basic-ja-32     basic-en-32    \
cinnamon-ja-64 cinnamon-en-64 cinnamon-ja-32  cinnamon-en-32 \
gnome-ja-64    gnome-en-64    gnome-ja-32     gnome-en-32    \
i3-ja-64       i3-en-64       i3-ja-32        i3-en-32       \
lxde-ja-64     lxde-en-64     lxde-ja-32      lxde-en-32     \
plasma-ja-64   plasma-en-64                                  \
releng-ja-64   releng-en-64   releng-ja-32    releng-en-32   \
serene-ja-64   serene-en-64   serene-ja-32    serene-en-32   \
xfce-ja-64     xfce-en-64     xfce-ja-32      xfce-en-32     \
xfce-pro-ja-64 xfce-pro-en-64                                \
:
	@$(eval ARCHITECTURE=${shell echo ${@} | rev | cut -d '-' -f 1 | rev })
	@$(eval LOCALE=${shell echo ${@} | rev | cut -d '-' -f 2 | rev })
	@$(eval CHANNEL=${shell echo ${@} | sed "s/-${LOCALE}-${ARCHITECTURE}//g"})
	@[[ -z "${CHANNEL}" ]] && echo "Empty Channel" && exit 1 || :
	@case ${ARCHITECTURE} in\
		"32") sudo ${CURRENT_DIR}/${BUILD_SCRIPT} ${ARGS} ${SHARE_OPTION} ${ARCH_i686} -l ${LOCALE} ${CHANNEL} ;;\
		"64") sudo ${CURRENT_DIR}/${BUILD_SCRIPT} ${ARGS} ${SHARE_OPTION} ${ARCH_x86_64} -l ${LOCALE} ${CHANNEL};;\
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
	@sudo ${CURRENT_DIR}/${BUILD_SCRIPT} --noconfirm --debug clean

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
