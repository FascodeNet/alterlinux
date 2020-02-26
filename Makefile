BUILD_SCRIPT = build.sh


linux:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter"

ck :
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k ck

lts:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lts

lqx:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lqx

rt:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k rt

zen:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k zen


test-linux:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -t '-Xcompression-level 1'

test-ck:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k ck -t '-Xcompression-level 1'

test-lts:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lts -t '-Xcompression-level 1'

test-lqx:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k lqx -t '-Xcompression-level 1'

test-rt:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k rt -t '-Xcompression-level 1'

test-zen:
	sudo @./${BUILD_SCRIPT} -b -c "zstd" -p "alter" -k zen -t '-Xcompression-level 1'