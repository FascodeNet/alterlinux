BUILD_SCRIPT = build.sh
KERNEL       = zen
SHARE_OPTION = -b -c "zstd" -u "alter" -p "alter" -k "${KERNEL}"
DEBUG_OPTION = -t '-Xcompression-level 1' -x


xfce:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} xfce
	@make clean

plasma:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} plasma
	@make clean

releng:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} plasma
	@make clean

clean:
	@sudo ./${BUILD_SCRIPT} clean
