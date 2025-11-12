#!/bin/bash
set -e

echo "Running release tasks..."

# Run regular migrations
echo "Running database migrations..."
bin/rails db:migrate

# Setup Solid Queue tables (only if they don't exist)
echo "Setting up Solid Queue tables..."
bin/rails solid_queue:setup

echo "Release tasks completed!"
