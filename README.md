# Terragrunt Setup for Serverless Architecture on AWS

### 1. Local Terragrunt Setup

1. Clone the repo.
2. Edit:

   - **`prod/terragrunt.hcl`**

   Update the `state_prefix` with something unique to your setup.

   - **`prod/env.hcl`**

   Update the `env` variable value with something unique for proper state separation and to avoid duplicate resource errors.

3. Go to `prod/` and run:

   ```bash
   terragrunt init
   ```

   Approve creation of the backend (S3 + DynamoDB).

4. Confirm `.terraform/`, `provider.tf`, and `state.tf` are generated (auto-excluded in `.gitignore`).

---

### 2. GitHub Actions Deployment

- Push changes to a feature branch (e.g., `dev`).
- Create a PR and merge into `main`.
- The **`deploy.yml`** workflow runs automatically to apply infrastructure.

**GitHub Secrets Required:**

```
ACCOUNT_ID
AWS_REGION
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

These belong to the DevOps IAM user and are stored under the `production` environment in repo settings.

---

### 3. Destroy Workflow

- A manual **`destroy.yml`** workflow is provided to safely tear down infrastructure.
- It first runs `terragrunt apply` to refresh outputs, then executes `terragrunt destroy` in the right order.
- Use branch protection to ensure only authorized users can trigger it.

---
