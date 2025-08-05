include .env

PICO8_ARGS="-windowed 1 -width 640 -height 640"
OUTPUT_CART="dist/${PROJECT_NAME}.p8"

run:
	${PICO8} ${PICO_ARGS} -run cartridge.p8

run-dist:
	${PICO8} ${PICO_ARGS} -run ${OUTPUT_CART}

start:
	${PICO8} ${PICO_ARGS} cartridge.p8

build: ${OUTPUT_CART}

${OUTPUT_CART}: src/*.lua cartridge.p8
	@mkdir -p dist
	@mkdir -p .build
	.dev/preprocess_lua_includes.py src/main.lua > .build/combined.lua
	.dev/inject_lua.py cartridge.p8 .build/combined.lua ${OUTPUT_CART}

make clean:
	rm -rf .build
	rm -rf dist