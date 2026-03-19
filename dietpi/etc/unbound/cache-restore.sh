#!/bin/bash
if [ -f /var/lib/unbound/cache.dump ]; then
    sleep 2
    unbound-control load_cache < /var/lib/unbound/cache.dump 2>/dev/null || true
fi
exit 0
