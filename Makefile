include .env

PICO8_ARGS="-windowed 1 -width 640 -height 640"
OUTPUT_CART="dist/${PROJECT_NAME}.p8"

run: .build/combined.lua inject-includes
	${PICO8} ${PICO_ARGS} -run cartridge.p8

inject-includes: src/*.lua
	.dev/inject_includes.sh

run-dist:
	${PICO8} ${PICO_ARGS} -run ${OUTPUT_CART}

start:
	${PICO8} ${PICO_ARGS} cartridge.p8

build: ${OUTPUT_CART}

.build/combined.lua: src/*.lua
	@mkdir -p .build
	.dev/combine_lua.sh > .build/combined.lua

${OUTPUT_CART}: .build/combined.lua cartridge.p8
	@mkdir -p dist
	.dev/inject_lua.py cartridge.p8 .build/combined.lua ${OUTPUT_CART}

make clean:
	rm -rf .build
	rm -rf dist