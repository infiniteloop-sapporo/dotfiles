#!/bin/bash

while read -r line; do
    src=${0%/*}/$line
    dest=~/$line

    [[ -f $src ]] || continue
    [[ $src -nt $dest ]] || continue

    perm=755
    [[ $(file --mime-type "$(realpath $src)") = */x-shellscript ]] || perm=644

    install -Dvm$perm $src $dest
done < ${0%/*}/files.txt
