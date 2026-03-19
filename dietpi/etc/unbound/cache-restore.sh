#!/bin/bash
DUMP=/var/lib/unbound/cache.dump
[ -f "$DUMP" ] || exit 0

for i in 1 2 3 4 5; do
    if unbound-control load_cache < "$DUMP" 2>/dev/null; then
        logger -t unbound-cache "Cache restored from $DUMP"
        exit 0
    fi
    sleep 1
done

rm -f "$DUMP"
logger -t unbound-cache "Failed to restore cache after 5 attempts, removed $DUMP"
