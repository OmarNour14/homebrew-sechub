#!/bin/bash

function show_help {
    cat << EOF
Usage: ${0##*/} [command] [arguments]

Commands:
  add-note <finding-id|batch> <note-text> [product-type]
    Updates a note in AWS Security Hub for a specified finding or a batch of findings.

  download-report [local-path]
    Downloads the findings report from an S3 bucket. Saves to the specified local path, or current directory by default.

  update-status <finding-id|batch> <status> [product-type]
    Updates the workflow status of a finding or a batch of findings in AWS Security Hub.
    Allowed status values: NEW, NOTIFIED, SUPPRESSED, RESOLVED

  update-status-add-note <finding-id|batch> <status> <note-text> [product-type]
    Updates the workflow status and adds a note to a finding or a batch of findings in AWS Security Hub.

Arguments:
  finding-id      The ID of the finding to update.
  batch           A comma-separated list of finding IDs to update.
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
    local product_type=$(echo "$1" | tr '[:upper:]' '[:lower:]')
    case "$product_type" in
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
    local finding_ids=$2
    local second_arg=$3
    local third_arg=$4
    local fourth_arg=${5:-"default"}

    check_aws_config

    finding_ids=$(echo "$finding_ids" | tr -d '[:space:]')
    IFS=',' read -r -a finding_id_array <<< "$finding_ids"

    for finding_id in "${finding_id_array[@]}"; do
        check_finding_exists "$finding_id"
    done

    local product_arn=$(get_product_arn "$fourth_arg")

    local identifiers=()
    for finding_id in "${finding_id_array[@]}"; do
        identifiers+=("{\"Id\": \"$finding_id\", \"ProductArn\": \"$product_arn\"}")
    done
    local identifiers_json=$(echo "${identifiers[@]}" | jq -s '.')

    case "$command" in
        add-note)
            local note_text="$second_arg"
            local current_date=$(date +"%d/%m/%Y")
            local full_note_text="$current_date - \"$note_text\""
            local payload=$(jq -n \
                --argjson identifiers "$identifiers_json" \
                --arg noteText "$full_note_text" \
                --arg updatedBy "securityhub-cli" \
                '{
                    FindingIdentifiers: $identifiers,
                    Note: {
                        Text: $noteText,
                        UpdatedBy: $updatedBy
                    }
                }'
            )
            ;;
        update-status)
            local new_status=$(echo "$second_arg" | tr '[:lower:]' '[:upper:]')
            local allowed_statuses=("NEW" "NOTIFIED" "SUPPRESSED" "RESOLVED")
            if [[ ! " ${allowed_statuses[@]} " =~ " ${new_status} " ]]; then
                echo "Invalid status value: $new_status. Allowed values are: ${allowed_statuses[*]}"
                exit 1
            fi
            local payload=$(jq -n \
                --argjson identifiers "$identifiers_json" \
                --arg status "$new_status" \
                '{
                    FindingIdentifiers: $identifiers,
                    Workflow: {
                        Status: $status
                    }
                }'
            )
            ;;
        update-status-add-note)
            local new_status=$(echo "$second_arg" | tr '[:lower:]' '[:upper:]')
            local note_text="$third_arg"
            local allowed_statuses=("NEW" "NOTIFIED" "SUPPRESSED" "RESOLVED")
            if [[ ! " ${allowed_statuses[@]} " =~ " ${new_status} " ]]; then
                echo "Invalid status value: $new_status. Allowed values are: ${allowed_statuses[*]}"
                exit 1
            fi
            local current_date=$(date +"%d/%m/%Y")
            local full_note_text="$current_date - \"$note_text\""
            local payload=$(jq -n \
                --argjson identifiers "$identifiers_json" \
                --arg status "$new_status" \
                --arg noteText "$full_note_text" \
                --arg updatedBy "securityhub-cli" \
                '{
                    FindingIdentifiers: $identifiers,
                    Workflow: {
                        Status: $status
                    },
                    Note: {
                        Text: $noteText,
                        UpdatedBy: $updatedBy
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
        echo "$command executed successfully for findings: $finding_ids."
    else
        local error_code=$(echo "$response" | jq -r '.UnprocessedFindings[0].ErrorCode')
        local error_message=$(echo "$response" | jq -r '.UnprocessedFindings[0].ErrorMessage')
        echo "Failed to execute $command for findings: $finding_ids. Error: $error_code - $error_message"
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
    update-status-add-note)
        handle_command "update-status-add-note" "$2" "$3" "$4" "$5"
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
