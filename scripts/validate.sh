Runs formatting, initialization, validation, and security checks. Checkov is optional and must be installed separately.


bash

#!/usr/bin/env bash

set -euo pipefail

echo "==> Formatting Terraform"
terraform fmt -recursive -check

echo "==> Initializing Terraform"
terraform init -backend=false

echo "==> Validating configuration"
terraform validate

echo "==> Running Terraform tests"
terraform test

if command -v checkov >/dev/null 2>&1; then
  echo "==> Running Checkov"
  checkov -d . --framework terraform
else
  echo "Checkov not installed; skipping security scan."
fi

echo "==> Validation completed"
Make the script executable:
