
BUILD_SCRIPT := build.sh
KERNEL       := zen
SHARE_OPTION := --boot-splash --comp-type "xz" --user "alter" --password "alter" --kernel "${KERNEL}" --debug
ARCH_x86_64  := --arch x86_64
ARCH_i686    := --arch i686
CURRENT_DIR  := ${shell dirname $(dir $(abspath $(lastword $(MAKEFILE_LIST))))}/${shell basename $(dir $(abspath $(lastword $(MAKEFILE_LIST))))}

full:mkalteriso
	@sudo ${CURRENT_DIR}/tools/fullbuild.sh
	@make clean

xfce-64 xfce-32 lxde-64 lxde-32 plasma-64 releng-32 releng-64 cinnamon-64 cinnamon-32 deepin-64 gnome-64 gnomemac-64 i3-64 i3-32:mkalteriso
	$(eval CHANNEL=${shell echo ${@} | cut -d '-' -f 1})
	$(eval ARCHITECTURE=${shell echo ${@} | cut -d '-' -f 2})
	@case ${ARCHITECTURE} in\
		"32") sudo ${CURRENT_DIR}/${BUILD_SCRIPT} ${SHARE_OPTION} ${ARCH_i686} ${CHANNEL} ;;\
		"64") sudo ${CURRENT_DIR}/${BUILD_SCRIPT} ${SHARE_OPTION} ${ARCH_x86_64} ${CHANNEL};;\
	esac
	@make clean

menuconfig/build/mconf::
	@if [ -d menuconfig/build ];\
	then \
		:;\
	else \
		mkdir menuconfig/build ;\
	fi
	(cd menuconfig/build ; cmake -GNinja .. ; ninja -j4 )

mkalteriso:
	@if [ -d system/cpp-src/mkalteriso/build ];\
	then \
		:;\
	else \
		mkdir system/cpp-src/mkalteriso/build ;\
	fi
	(cd system/cpp-src/mkalteriso/build ; cmake -GNinja .. ; ninja -j4 ; cp -f mkalteriso ../../../)

menuconfig:menuconfig/build/mconf menuconfig-script/kernel_choice
	menuconfig/build/mconf menuconfig-script/rootconf

menuconfig-script/kernel_choice:system/kernel-x86_64 system/kernel-i686
	${CURRENT_DIR}/tools/kernel-choice-conf-gen.sh

build_option:
	if [ -f .config ];\
	then \
		:;\
	else \
		make menuconfig ;\
	fi
	${CURRENT_DIR}/tools/menuconf-to-alterconf.sh ${CURRENT_DIR}/.build_option

clean:
	@sudo ${CURRENT_DIR}/${BUILD_SCRIPT} clean

build:build_option mkalteriso
	$(eval BUILD_OPTION := $(shell cat ${CURRENT_DIR}/.build_option))
	sudo ${CURRENT_DIR}/${BUILD_SCRIPT} ${BUILD_OPTION}

keyring::
	sudo ${CURRENT_DIR}/tools/keyring.sh --alter-add --arch-add

wizard:
	sudo ${CURRENT_DIR}/tools/wizard.sh


