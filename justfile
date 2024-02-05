set positional-arguments
set shell := ["bash", "-cue"]
root_dir := justfile_directory()

build:
	cd "{{root_dir}}" && rm -rf build && \
		mkdir -p build && \
		cd build && cmake .. && \
		 NIX_DEBUG=1 make -j && \
		 ./test

package:
	nix build "./?submodules=1" --print-build-logs

run:
	nix run "./?submodules=1" --print-build-logs
