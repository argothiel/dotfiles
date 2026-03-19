#!/bin/bash
DUMP=/var/lib/unbound/cache.dump
if unbound-control dump_cache > "$DUMP.tmp" 2>/dev/null; then
    mv "$DUMP.tmp" "$DUMP"
    logger -t unbound-cache "Cache saved to $DUMP"
else
    rm -f "$DUMP.tmp"
    logger -t unbound-cache "Failed to save cache"
fi
