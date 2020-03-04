BUILD_SCRIPT = build.sh


linux:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter"
	@make cleanup

ck :
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k ck
	@make cleanup

lts:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lts
	@make cleanup

lqx:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lqx
	@make cleanup

rt:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k rt
	@make cleanup

rt-lts:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k rt-lts
	@make cleanup

zen:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k zen
	@make cleanup

test-linux:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -t '-Xcompression-level 1' -x
	@make cleanup

test-ck:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k ck -t '-Xcompression-level 1' -x
	@make cleanup

test-lts:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lts -t '-Xcompression-level 1' -x
	@make cleanup

test-lqx:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lqx -t '-Xcompression-level 1' -x
	@make cleanup

test-rt:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k rt -t '-Xcompression-level 1' -x
	@make cleanup

test-rt-lts:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k rt-lts -t '-Xcompression-level 1' -x
	@make cleanup

test-zen:
	@sudo ./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k zen -t '-Xcompression-level 1' -x
	@make cleanup

cleanup:
	@sudo rm -rf ./work