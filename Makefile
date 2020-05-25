
BUILD_SCRIPT = build.sh
KERNEL       = zen
SHARE_OPTION = -b -c "zstd" -u "alter" -p "alter" -k "${KERNEL}"
DEBUG_OPTION = -t '-Xcompression-level 1' -x -d
ARCH_x86_64  = -a x86_64
ARCH_i686    = -a i686


full:
	@sudo ./fullbuild.sh
	@make clean

xfce-64:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${ARCH_x86_64} xfce
	@make clean

plasma-64:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${ARCH_x86_64} plasma
	@make clean

releng-64:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${ARCH_x86_64} releng
	@make clean

lxde-64:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${ARCH_x86_64} lxde
	@make clean

xfce-32:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${ARCH_i686} xfce
	@make clean

plasma-32:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${ARCH_i686} plasma
	@make clean

releng-32:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${ARCH_i686} releng
	@make clean

lxde-32:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${ARCH_i686} lxde
	@make clean

menuconfig/build/mconf::
	@if [ -d menuconfig/build ];\
	then \
		:;\
	else \
		mkdir menuconfig/build ;\
	fi
	(cd menuconfig/build ; cmake -GNinja .. ; ninja -j4 )

menuconfig:menuconfig/build/mconf menuconfig-script/kernel_choice
	menuconfig/build/mconf menuconfig-script/rootconf
menuconfig-script/kernel_choice:system/kernel_list-x86_64 system/kernel_list-i686
	./kernel-choice-conf-gen.sh 
build_option:
	if [ -f .config ];\
	then \
		:;\
	else \
		make menuconfig ;\
	fi
	./menuconf-to-alterconf.sh ./.build_option
clean:
	@sudo ./${BUILD_SCRIPT} clean
	@rm -rf menuconfig/build
	@rm -f menuconfig-script/kernel_choice
	@rm -f .config
	@rm -f .build_option 
build:build_option
	$(eval BUILD_OPTION := $(shell cat ./.build_option))
	sudo ./${BUILD_SCRIPT} ${BUILD_OPTION}
keyring::
	sudo ./keyring.sh --alter-add --arch-add 
