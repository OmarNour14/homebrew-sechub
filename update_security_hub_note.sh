#!/bin/bash

function show_help {
    cat << EOF
Usage: ${0##*/} add-note <finding-id> <note-text> [product-type]

This script updates a note in AWS Security Hub for a specified finding.

Arguments:
  finding-id      The ID of the finding to update.
  note-text       The text of the note to attach to the finding.
  product-type    The type of product (optional, default: default). Accepted values: snyk, securityhub, default.

EOF
}

# Check if help is requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] || [ "$#" -eq 0 ]; then
    show_help
    exit 0
fi

# Check command correctness and whether it's 'add-note'
if [ "$1" != "add-note" ]; then
    echo "Unknown command: $1"
    show_help
    exit 1
fi

# Check if the correct number of arguments are provided for the 'add-note' command
if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
    show_help
    exit 1
fi

# Remove the 'add-note' command from the arguments list
shift

# Assign input arguments to variables
FINDING_ID=$1
NOTE_TEXT=$2
PRODUCT_TYPE=${3:-"default"}  # Default product type is "default" if not provided

# Get the AWS region and account ID from the configured profile
REGION=$(aws configure get region)
ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

if [ -z "$REGION" ]; then
    echo "AWS region not configured. Please configure your AWS CLI."
    exit 1
fi

if [ -z "$ACCOUNT_ID" ]; then
    echo "Unable to retrieve AWS account ID. Please check your AWS CLI configuration."
    exit 1
fi

# Determine the ProductArn based on the product type
case "$PRODUCT_TYPE" in
    snyk)
        PRODUCT_ARN="arn:aws:securityhub:$REGION::product/snyk/snyk"
        ;;
    securityhub)
        PRODUCT_ARN="arn:aws:securityhub:$REGION::product/aws/securityhub"
        ;;
    default|*)
        PRODUCT_ARN="arn:aws:securityhub:$REGION:$ACCOUNT_ID:product/$ACCOUNT_ID/default"
        ;;
esac

# Check if the finding exists
FINDING_EXISTS=$(aws securityhub get-findings --filters "{\"Id\": [{\"Comparison\": \"EQUALS\", \"Value\": \"$FINDING_ID\"}]}")

# Use jq to check if the findings array is empty
if echo "$FINDING_EXISTS" | jq -e '.Findings | length == 0' > /dev/null; then
    echo "Finding with ID $FINDING_ID not found."
    exit 1
fi

# If finding exists, proceed to update it
echo "Finding with ID $FINDING_ID found, updating note..."

# Create the JSON payload for the AWS CLI command
PAYLOAD=$(jq -n \
    --arg id "$FINDING_ID" \
    --arg productArn "$PRODUCT_ARN" \
    --arg noteText "$NOTE_TEXT" \
    --arg updatedBy "securityhub-cli" \
    '{
        FindingIdentifiers: [
            {
                Id: $id,
                ProductArn: $productArn
            }
        ],
        Note: {
            Text: $noteText,
            UpdatedBy: $updatedBy
        }
    }'
)

# Update the finding in AWS Security Hub
RESPONSE=$(aws securityhub batch-update-findings --cli-input-json "$PAYLOAD")

# Parse the response to check for errors
PROCESSED_COUNT=$(echo "$RESPONSE" | jq '.ProcessedFindings | length')
UNPROCESSED_COUNT=$(echo "$RESPONSE" | jq '.UnprocessedFindings | length')

if [ "$PROCESSED_COUNT" -gt 0 ]; then
    echo "Note updated successfully for finding ID $FINDING_ID."
else
    ERROR_CODE=$(echo "$RESPONSE" | jq -r '.UnprocessedFindings[0].ErrorCode')
    ERROR_MESSAGE=$(echo "$RESPONSE" | jq -r '.UnprocessedFindings[0].ErrorMessage')
    echo "Failed to update note for finding ID $FINDING_ID. Error: $ERROR_CODE - $ERROR_MESSAGE"
fi
