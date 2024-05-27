#!/bin/bash

function show_help {
    cat << EOF
Usage: ${0##*/} [command] [arguments]

Commands:
  add-note <finding-id> <note-text> [product-type]
    Updates a note in AWS Security Hub for a specified finding.

  download-report [local-path]
    Downloads the findings report from an S3 bucket. Saves to the specified local path, or current directory by default.

  update-status <finding-id> <status> [product-type]
    Updates the workflow status of a finding in AWS Security Hub.
    Allowed status values: NEW, NOTIFIED, SUPPRESSED, RESOLVED

Arguments:
  finding-id      The ID of the finding to update.
  note-text       The text of the note to attach to the finding.
  status          The new status to set for the finding's workflow.
  product-type    The type of product (optional, default: default). Accepted values: snyk, securityhub, default.
  local-path      The local path to save the downloaded report (optional).
EOF
}

function check_aws_config {
    REGION=$(aws configure get region)
    ACCOUNT_ID=$(aws sts get-caller-identity --query "Account" --output text)

    if [ -z "$REGION" ] || [ -z "$ACCOUNT_ID" ]; then
        echo "AWS configuration is incomplete."
        exit 1
    fi
}

function get_product_arn {
    case "$1" in
        snyk)
            echo "arn:aws:securityhub:$REGION::product/snyk/snyk"
            ;;
        securityhub)
            echo "arn:aws:securityhub:$REGION::product/aws/securityhub"
            ;;
        default|*)
            echo "arn:aws:securityhub:$REGION:$ACCOUNT_ID:product/$ACCOUNT_ID/default"
            ;;
    esac
}

function check_finding_exists {
    local finding_id=$1
    FINDING_EXISTS=$(aws securityhub get-findings --filters "{\"Id\": [{\"Comparison\": \"EQUALS\", \"Value\": \"$finding_id\"}]}")
    if echo "$FINDING_EXISTS" | jq -e '.Findings | length == 0' > /dev/null; then
        echo "Finding with ID $finding_id not found."
        exit 1
    fi
}

function handle_command {
    local command=$1
    local finding_id=$2
    local second_arg=$3
    local third_arg=${4:-"default"}

    check_aws_config
    check_finding_exists "$finding_id"
    local product_arn=$(get_product_arn "$third_arg")

    case "$command" in
        add-note)
            local note_text="$second_arg"
            local payload=$(jq -n \
                --arg id "$finding_id" \
                --arg productArn "$product_arn" \
                --arg noteText "$note_text" \
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
            ;;
        update-status)
            local new_status="$second_arg"
            local payload=$(jq -n \
                --arg id "$finding_id" \
                --arg productArn "$product_arn" \
                --arg status "$new_status" \
                '{
                    FindingIdentifiers: [
                        {
                            Id: $id,
                            ProductArn: $productArn
                        }
                    ],
                    Workflow: {
                        Status: $status
                    }
                }'
            )
            ;;
        *)
            echo "Invalid command."
            exit 1
            ;;
    esac

    local response=$(aws securityhub batch-update-findings --cli-input-json "$payload")
    local processed_count=$(echo "$response" | jq '.ProcessedFindings | length')
    if [ "$processed_count" -gt 0 ]; then
        echo "$command executed successfully for finding ID $finding_id."
    else
        local error_code=$(echo "$response" | jq -r '.UnprocessedFindings[0].ErrorCode')
        local error_message=$(echo "$response" | jq -r '.UnprocessedFindings[0].ErrorMessage')
        echo "Failed to execute $command for finding ID $finding_id. Error: $error_code - $error_message"
    fi
}

# Check if help is requested
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]] || [ "$#" -eq 0 ]; then
    show_help
    exit 0
fi

# Main command dispatch
case "$1" in
    add-note|update-status)
        handle_command "$1" "$2" "$3" "$4"
        ;;
    download-report)
        local local_path=${2:-"./FindingsReport.xlsx"}
        echo "Downloading report to $local_path..."
        aws s3 cp "s3://tf-security-hub-reports-fdrpsyqv/WeeklyReports/FindingsReport.xlsx" "$local_path" && echo "Download complete." || echo "Failed to download the report."
        ;;
    *)
        echo "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
