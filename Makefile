BUILD_SCRIPT = build.sh
SHARE_OPTION = -b -c "zstd" -p "alter"
DEBUG_OPTION = -t '-Xcompression-level 1' -x



linux:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION}
	@make cleanup

ck :
	@sudo ./${BUILD_SCRIPT} -k ck ${SHARE_OPTION}
	@make cleanup

lts:
	@sudo ./${BUILD_SCRIPT} -k lts ${SHARE_OPTION}
	@make cleanup

lqx:
	@sudo ./${BUILD_SCRIPT} -k lqx ${SHARE_OPTION}
	@make cleanup

rt:
	@sudo ./${BUILD_SCRIPT} -k rt ${SHARE_OPTION}
	@make cleanup

rt-lts:
	@sudo ./${BUILD_SCRIPT} -k rt-lts ${SHARE_OPTION}
	@make cleanup

zen:
	@sudo ./${BUILD_SCRIPT} -k zen ${SHARE_OPTION}
	@make cleanup

test-linux:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${DEBUG_OPTION}
	@make cleanup

test-ck:
	@sudo ./${BUILD_SCRIPT} -k ck ${SHARE_OPTION} ${DEBUG_OPTION}
	@make cleanup

test-lts:
	@sudo ./${BUILD_SCRIPT} -k lts ${SHARE_OPTION} ${DEBUG_OPTION}
	@make cleanup

test-lqx:
	@sudo ./${BUILD_SCRIPT} -k lqx ${SHARE_OPTION} ${DEBUG_OPTION}
	@make cleanup

test-rt:
	@sudo ./${BUILD_SCRIPT} -k rt ${SHARE_OPTION} ${DEBUG_OPTION}
	@make cleanup

test-rt-lts:
	@sudo ./${BUILD_SCRIPT} -k rt-lts ${SHARE_OPTION} ${DEBUG_OPTION}
	@make cleanup

test-zen:
	@sudo ./${BUILD_SCRIPT} -k zen ${SHARE_OPTION} ${DEBUG_OPTION}
	@make cleanup

cleanup:
	@sudo rm -rf ./work