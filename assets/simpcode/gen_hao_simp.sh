
cat schemas/hao/leopard.dict.yaml | \
    sed 's/^\(.*\)\t\(.*\)\t\(.*\)/\1\t\2/g' | \
    sed 's/\t/{TAB}/g' | \
    grep '.*{TAB}[a-z]\{1,2\}$' | \
    sed 's/{TAB}/\t/g' | \
    sed 's/$/1/g' \
    > deploy/hao/hao_simp.txt