BUILD_SCRIPT = build.sh
SHARE_OPTION = -b -c "zstd" -p "alter"
DEBUG_OPTION = -t '-Xcompression-level 1' -x


basic:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION}
	@make cleanup

core:
	@sudo ./${BUILD_SCRIPT} -k core ${SHARE_OPTION}
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

# xanmod:
	# @sudo ./${BUILD_SCRIPT} -k xanmod ${SHARE_OPTION}
	# @make cleanup

xanmod-lts:
	@sudo ./${BUILD_SCRIPT} -k xanmod-lts ${SHARE_OPTION}
	@make cleanup


test-basic:
	@sudo ./${BUILD_SCRIPT} ${SHARE_OPTION} ${DEBUG_OPTION}
	@make cleanup

test-core:
	@sudo ./${BUILD_SCRIPT} -k core ${SHARE_OPTION} ${DEBUG_OPTION}
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

# test-xanmod:
	# @sudo ./${BUILD_SCRIPT} -k xanmod ${SHARE_OPTION} ${DEBUG_OPTION}
	# @make cleanup

test-xanmod-lts:
	@sudo ./${BUILD_SCRIPT} -k xanmod-lts ${SHARE_OPTION} ${DEBUG_OPTION}
	@make cleanup


cleanup:
	@sudo rm -rf ./work