#!/bin/bash
unbound-control dump_cache > /var/lib/unbound/cache.dump 2>/dev/null
