BUILD_SCRIPT = build.sh
SHARE_OPTION = -b -c "zstd" -u "alter" -p "alter"
DEBUG_OPTION = -t '-Xcompression-level 1' -x


xfce:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} xfce
	@make cleanup

plasma:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} plasma
	@make cleanup

xfce-test:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${DEBUG_OPTION} xfce
	@make cleanup

plasma-test:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${DEBUG_OPTION} plasma
	@make cleanup

cleanup:
	@[[ -d ./work ]] && sudo rm -rf ./work
	# @[[ -d ./out  ]] && sudo rm -rf ./out
