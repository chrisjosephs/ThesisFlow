#!/usr/bin/env bash

for dir in thesisflow-*; do
    echo "Updating $dir..."
    git -C "$dir" pull
done