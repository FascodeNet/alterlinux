BUILD_SCRIPT = build.sh


linux:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter"

ck :
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k ck

lts:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lts

lqx:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lqx

rt:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k rt

zen:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k zen


test-linux:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -t '-Xcompression-level 1'

test-ck:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k ck -t '-Xcompression-level 1'

test-lts:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lts -t '-Xcompression-level 1'

test-lqx:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lqx -t '-Xcompression-level 1'

test-rt:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k rt -t '-Xcompression-level 1'

test-zen:
	@./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k zen -t '-Xcompression-level 1'