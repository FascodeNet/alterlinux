BUILD_SCRIPT = build.sh


linux:
	@./${build} -b -c "zstd" -p "alter"

ck :
	@./${build} -b -c "zstd" -p "alter" -k ck

lts:
	@./${build} -b -c "zstd" -p "alter" -k lts

lqx:
	@./${build} -b -c "zstd" -p "alter" -k lqx

rt:
	@./${build} -b -c "zstd" -p "alter" -k rt

zen:
	@./${build} -b -c "zstd" -p "alter" -k zen


test-linux:
	@./${build} -b -c "zstd" -p "alter" -t '-Xcompression-level 1'

test-ck:
	@./${build} -b -c "zstd" -p "alter" -k ck -t '-Xcompression-level 1'

test-lts:
	@./${build} -b -c "zstd" -p "alter" -k lts -t '-Xcompression-level 1'

test-lqx:
	@./${build} -b -c "zstd" -p "alter" -k lqx -t '-Xcompression-level 1'

test-rt:
	@./${build} -b -c "zstd" -p "alter" -k rt -t '-Xcompression-level 1'

test-zen:
	@./${build} -b -c "zstd" -p "alter" -k zen -t '-Xcompression-level 1'