#! /bin/sh

cmark-gfm --to commonmark --nobreaks --smart --validate-utf8 \
          --extension table \
          --extension strikethrough \
          --extension autolink \
          --extension tagfilter \
          "$1" \
          > "${1}.tmp" && mv -f "${1}.tmp" "$1"
