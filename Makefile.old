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

clean:
	@sudo ./${BUILD_SCRIPT} clean
