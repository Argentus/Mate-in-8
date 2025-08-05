#!/usr/bin/env python3
import sys
import os

included_files = set()

def preprocess_file(filepath):
    if filepath in included_files:
        return  # avoid duplicate includes
    included_files.add(filepath)

    base_dir = os.path.dirname(filepath)

    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            for line in f:
                line_strip = line.strip()
                if line_strip.startswith('#include '):
                    # Parse included filename inside quotes
                    start = line_strip.find('"')
                    end = line_strip.rfind('"')
                    if start != -1 and end != -1 and end > start:
                        inc_path = line_strip[start+1:end]
                        # Resolve relative path
                        inc_full_path = os.path.normpath(os.path.join(base_dir, inc_path))
                        if os.path.isfile(inc_full_path):
                            preprocess_file(inc_full_path)
                        else:
                            print(f'-- Warning: included file not found: {inc_full_path}', file=sys.stderr)
                    else:
                        print(line, end='')  # output line as-is if malformed include
                else:
                    print(line, end='')
    except FileNotFoundError:
        print(f'-- Error: file not found: {filepath}', file=sys.stderr)

def main():
    if len(sys.argv) != 2:
        print(f'Usage: {sys.argv[0]} path/to/main.lua', file=sys.stderr)
        sys.exit(1)

    preprocess_file(sys.argv[1])

if __name__ == "__main__":
    main()
