# Nebari CI AMI Image

This repository contains the infrastructure code for building custom Amazon Machine Images (AMIs) used by cirun.io to spin up on-demand and spot runners on AWS for Nebari's CI pipeline.

## Overview

We use Packer to create standardized AMIs based on Ubuntu 24.04 that come pre-installed with all the tools needed for Nebari's integration tests. This approach significantly reduces CI build times by avoiding repeated installation of dependencies when cirun launches new runner instances.

## What's Included

The AMI includes:
- Docker and Docker Compose
- Kubernetes tools (kubectl, kind, k9s)
- Node.js 20 and npm
- Python 3 with pip
- Miniconda (latest)
- Playwright for browser testing
- AWS CLI v2
- Common utilities (jq, hub, git, curl, wget)

## Repository Structure

```
 packer/
    nebari-runner.pkr.hcl          # Main Packer configuration
    scripts/
        disable-upgrades.sh        # Disables automatic system updates
        install-docker.sh          # Docker installation
        setup-runner.sh            # Basic runner tools
        preinstall-tools.sh        # CI-specific tools
 .github/workflows/
    build-ami.yml                  # GitHub Actions workflow
 .gitignore
```

## Building AMIs

### Prerequisites

1. AWS IAM role configured for GitHub Actions with EC2 permissions
2. GitHub repository secrets:
   - `AWS_ROLE_ARN`: ARN of the IAM role for building AMIs
   - `NEBARI_PAT`: Personal Access Token for nebari repository (for auto-updates)

### Manual Build

```bash
cd packer
packer init .
packer validate .
packer build .
```

### Automated Build

**Linting:** Runs automatically on push/PR to main branch for `packer/` changes

**Building:** Only runs on manual trigger via workflow dispatch

## How to Build and Deploy a New AMI

### Step 1: Build the AMI

1. Go to the [Actions tab](../../actions) in this repository
2. Click on "Build AMI" workflow
3. Click "Run workflow" button
4. Wait for the build to complete (~10-15 minutes)
5. Note the AMI ID from the build summary

### Step 2: Deploy to Nebari

**Option A: Automatic Update (Recommended)**
1. Go to the [Actions tab](../../actions) in this repository
2. Click on "Update Nebari AMI" workflow
3. Click "Run workflow" button
4. Either:
   - Leave AMI ID empty (will use latest built AMI)
   - Or enter specific AMI ID from Step 1
5. This will create a PR in the nebari repository

**Option B: Manual Update**
1. Go to the [nebari repository](https://github.com/nebari-dev/nebari)
2. Edit the `.cirun.yml` file
3. Update the `machine_image` field with the new AMI ID:
   ```yaml
   machine_image: ami-xxxxxxxxx  # Replace with new AMI ID
   ```
4. Create a pull request with your changes

### Step 3: Monitor and Test

1. Once the PR is merged in nebari repository
2. New CI runs will use the updated AMI
3. Monitor the first few CI runs to ensure everything works correctly

### Step 4: Clean Up (Optional)

Old AMIs are automatically cleaned up weekly, keeping only the 5 most recent images. To manually trigger cleanup:

1. Go to the [Actions tab](../../actions) in this repository
2. Click on "Cleanup Old AMIs" workflow
3. Click "Run workflow" button
4. Optionally adjust the number of AMIs to keep (default: 5)

## IAM Permissions

The GitHub Actions workflow requires these EC2 permissions:
- `ec2:DescribeRegions`, `ec2:DescribeImages`, `ec2:DescribeInstances`
- `ec2:RunInstances`, `ec2:TerminateInstances`, `ec2:StopInstances`
- `ec2:CreateImage`, `ec2:CreateTags`, `ec2:CreateSecurityGroup`
- `ec2:DeleteKeyPair`, `ec2:DeleteSecurityGroup`
- Additional EC2 permissions for AMI creation

## AMI Naming

AMIs are named using the format: `nebari-cirun-runner-ubuntu24-YYYYMMDD-HHMM`

Example: `nebari-cirun-runner-ubuntu24-20240716-1430`

## Integration with cirun.io

Once built, these AMIs are used by cirun.io to launch EC2 instances (both on-demand and spot) that serve as GitHub Actions runners for Nebari's CI workflows. The pre-installed tools ensure fast startup times and consistent environments across all CI runs.

## Customization

To add new tools or modify the AMI:

1. Update the appropriate script in `packer/scripts/`
2. Test locally with `packer build`
3. Create a pull request

The build process automatically disables system auto-updates to prevent interference with CI jobs.
