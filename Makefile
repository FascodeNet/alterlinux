BUILD_SCRIPT = build.sh
KERNEL       = zen
SHARE_OPTION = -b -c "zstd" -u "alter" -p "alter" -k "${KERNEL}"
DEBUG_OPTION = -t '-Xcompression-level 1' -x


xfce:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} xfce
	@make cleanup

plasma:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} plasma
	@make cleanup

releng:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} plasma
	@make cleanup

cleanup:
	@[[ -d ./work ]] && sudo rm -rf ./work
