set positional-arguments
set shell := ["bash", "-cue"]
root_dir := justfile_directory()

build:
	cd "{{root_dir}}" && mkdir -p build \
		 && cd build && cmake .. && \
		 NIX_DEBUG=1 make -j && \
		 ./test
