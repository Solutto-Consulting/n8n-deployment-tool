#!/bin/bash

# Test script to verify template generation works correctly
# This script creates test files from templates without affecting production

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/test-output"

echo "Testing template generation..."

# Create test directory
mkdir -p "$TEST_DIR"

# Test configuration
TEST_CONFIG='{
  "domain": "test.example.com",
  "email": "test@example.com", 
  "postgres_password": "test_postgres_password",
  "n8n_basic_auth_user": "testuser",
  "n8n_basic_auth_password": "test_n8n_password",
  "timezone": "America/New_York",
  "project_name": "test-n8n"
}'

echo "$TEST_CONFIG" > "$TEST_DIR/setup.json"

# Function to process template
process_template() {
    local template_file="$1"
    local output_file="$2"
    
    if [ ! -f "$template_file" ]; then
        echo "Template not found: $template_file"
        return 1
    fi
    
    sed -e "s/{{DOMAIN}}/test.example.com/g" \
        -e "s/{{EMAIL}}/test@example.com/g" \
        -e "s/{{POSTGRES_PASSWORD}}/test_postgres_password/g" \
        -e "s/{{N8N_BASIC_AUTH_USER}}/testuser/g" \
        -e "s/{{N8N_BASIC_AUTH_PASSWORD}}/test_n8n_password/g" \
        -e "s/{{TIMEZONE}}/America\/New_York/g" \
        -e "s/{{PROJECT_NAME}}/test-n8n/g" \
        "$template_file" > "$output_file"
    
    echo "✓ Generated: $output_file"
}

# Test template generation
echo "Generating test files from templates..."

process_template "$SCRIPT_DIR/.env.template" "$TEST_DIR/.env"
process_template "$SCRIPT_DIR/vhost.conf.template" "$TEST_DIR/vhost.conf"
process_template "$SCRIPT_DIR/vhost-ssl.conf.template" "$TEST_DIR/vhost-ssl.conf"
process_template "$SCRIPT_DIR/backup-db.sh.template" "$TEST_DIR/backup-db.sh"
process_template "$SCRIPT_DIR/restore-db.sh.template" "$TEST_DIR/restore-db.sh"

echo ""
echo "Template generation test completed!"
echo "Test files created in: $TEST_DIR"
echo ""
echo "Sample generated .env file:"
echo "----------------------------"
head -10 "$TEST_DIR/.env"
echo ""
echo "To clean up test files: rm -rf $TEST_DIR"
