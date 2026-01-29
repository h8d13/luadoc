#!/usr/bin/awk -f
# stats.awk — Autodocs readme statistics
# Usage: awk -f stats.awk readme.md

/^## / {
    sec = $0
    sub(/^## /, "", sec)
    ns++
}

/^### / {
    ne++
    se[sec]++
}

/^```/ {
    if (!ic) { ic = 1; nb++ }
    else ic = 0
    next
}

ic { nc++ }

/^> \[!/ { na++ }

END {
    printf "\n"
    printf "  sections     %d\n", ns
    printf "  entries      %d\n", ne
    printf "  code blocks  %d (%d lines)\n", nb, nc
    printf "  admonitions  %d\n", na
    printf "\n"
    split("Asserts (@ass),Setters (@set),Callers (@cal),Raisers (@rai)", order, ",")
    for (i = 1; i <= 4; i++)
        if (se[order[i]])
            printf "    %-24s %3d\n", order[i], se[order[i]]
    printf "\n"
}
