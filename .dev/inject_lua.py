#!/usr/bin/env python3
import sys

def inject_lua(asset_file, lua_file, output_file):
    with open(lua_file, 'r', encoding='utf-8') as f:
        lua_code = f.read()

    in_lua = False
    with open(asset_file, 'r', encoding='utf-8') as fin, \
         open(output_file, 'w', encoding='utf-8') as fout:
        for line in fin:
            stripped = line.strip()
            if stripped == '__lua__':
                fout.write(line)
                fout.write(lua_code)
                if not lua_code.endswith('\n'):
                    fout.write('\n')
                in_lua = True
                continue
            if in_lua and stripped.startswith('__'):
                fout.write(line)
                in_lua = False
                continue
            if not in_lua:
                fout.write(line)

def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} asset_cart.p8 combined.lua output_cart.p8", file=sys.stderr)
        sys.exit(1)

    asset_cart = sys.argv[1]
    combined_lua = sys.argv[2]
    output_cart = sys.argv[3]

    inject_lua(asset_cart, combined_lua, output_cart)

if __name__ == "__main__":
    main()
