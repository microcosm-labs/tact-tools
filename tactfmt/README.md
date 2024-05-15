# Tactfmt

Tactfmt is a tool for formatting Tact source files in a standard way.

This tool is implemented without using AST/CST.

## Usage

- Make sure you're on a Linux system with *busybox awk*(this is the case for most modern Linux distributions) or *gawk* installed.

- Add in `package.json` `scripts`: `"fmt": "find ./contracts -type f -name '*.tact' -exec sh ./.github/scripts/tactfmt.sh {} \\;"`

- Run `npm run fmt`.
