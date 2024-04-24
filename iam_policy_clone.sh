#!/bin/bash

# Source IAM role name and destination IAM role name
source_role_name="abc_service_account_role"
destination_role_name="cba_service_account_role"

# Get a list of inline policy names attached to the source IAM role
policy_names=$(aws iam list-role-policies --role-name $source_role_name --query "PolicyNames[]" --output text)

# Loop through each policy name
for policy_name in $policy_names; do
    # Retrieve the policy document for the current policy name
    policy_document=$(aws iam get-role-policy --role-name $source_role_name --policy-name $policy_name --query "PolicyDocument")
    
    # Attach the policy to the destination IAM role
    aws iam put-role-policy --role-name $destination_role_name --policy-name $policy_name --policy-document "$policy_document"
done
