#! /bin/bash

if [ -f "source/go.mod" ]; then
    echo "test pass"
    exit 0
fi

echo "source code not found"
exit 1
