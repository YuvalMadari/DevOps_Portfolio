#!/bin/bash

BASE_URL="http://$1"
TOOL_NAME="curl"
TOOL_DEF="Client for URLs"

# Check for required argument
if [ -z "$1" ]; then
    echo "Usage: $0 <BASE_URL_IP>"
    exit 1
fi


function check_status {
  if [ $1 -eq 0 ]; then
    echo "$2"
  else
    echo "$2"
    exit 1
  fi
}

echo "Testing index page..."
curl -s "$BASE_URL/" | grep -q "Cowsay Tool Manager"
check_status $? "Index page shows title"

echo "Adding tool: $TOOL_NAME"
curl -s -X POST "$BASE_URL/tools" -d "name=$TOOL_NAME" -d "definition=$TOOL_DEF" | grep -q "added\|already exists"
check_status $? "Add tool"

echo "Getting tool: $TOOL_NAME"
curl -s "$BASE_URL/tool/$TOOL_NAME" | grep -q "$TOOL_NAME"
check_status $? "Get tool"

echo "Updating tool: $TOOL_NAME"
curl -s -X PUT "$BASE_URL/tool/$TOOL_NAME" -d "name=$TOOL_NAME" -d "definition=Updated URL client" | grep -q "updated\|created"
check_status $? "Update tool"

echo "Deleting tool: $TOOL_NAME"
curl -s -X DELETE "$BASE_URL/tool/$TOOL_NAME" | grep -q "deleted\|not found"
check_status $? "Delete tool"

echo "All tests passed successfully!"
