# Test Scenarios

Organisation: ATUL0012345

This file describes **what each test checks and why**. Results and screenshots are in `documentation/evidence/test-results.md`.

## 1. How the tests are organised

| Layer | Where | What it proves |
|---|---|---|
| Sentinel unit tests | `sentinel/test/<policy>/` | Each policy returns the expected `main` value for a compliant and a non-compliant mock plan |
| Real Terraform plans | `terraform/tfplan`, `terraform/tfplan-noncompliant` | The same configuration produces a compliant or a non-compliant plan by changing three variables |
| HCP Terraform runs | HCP Terraform workspace `terraform-assignment` | The consolidated policies (`sentinel/hcp/`) run on real plans and block the non-compliant one |

The tests and mocks are in `sentinel/test/` and not in `tests/` because `sentinel test` looks for `test/<policy>/` next to the `.sentinel` files. This folder only holds the description of the scenarios.

### Anatomy of a unit test

Each case is one `.hcl` file plus one mock:

- `mock "tfplan/v2"` (or `tfconfig/v2`) points to a hand-written mock plan. The mock contains only the fields the policy reads.
- `test { rules = { main = true|false } }` is the expected result.

A `PASS` on a `fail-*` case means the policy **blocked** the plan, which is the expected outcome. A policy that always returned `true` would pass the `pass` case and fail the `fail-*` cases, so every policy has both kinds.

Run them from `sentinel/`:

```powershell
cd sentinel
sentinel test -verbose                           # all policies
sentinel test -verbose <policy>.sentinel         # one policy
```

## 2. Sentinel unit scenarios

### 2.1 `instance_type` (approved EC2 instance types)

| Case | Mock | Expected `main` | Why |
|---|---|---|---|
| `pass` | `t3.micro` | true | Approved type (`t3.micro`, `t3.small`) |
| `fail` | `m5.large` | false | Type not in the approved list |

### 2.2 `encryption` (encrypted EBS storage)

The root disk is a nested block inside `aws_instance`, not a separate resource. A policy that only filtered `aws_ebs_volume` would miss it, so there are two rules and two failing cases.

| Case | Mock | Expected `main` | Rule that fails |
|---|---|---|---|
| `pass` | Root disk and data volume encrypted | true | none |
| `fail-root` | Root disk `encrypted = false`, data volume encrypted | false | `root_volumes_encrypted` |
| `fail-ebs` | Root disk encrypted, data volume `encrypted = false` | false | `ebs_volumes_encrypted` |

### 2.3 `metadata` (IMDSv2 mandatory)

An undeclared `metadata_options` block cannot prove IMDSv2 (the AWS default allows IMDSv1), so it is treated as non-compliant.

| Case | Mock | Expected `main` | Why |
|---|---|---|---|
| `pass` | `http_tokens = "required"` | true | IMDSv2 enforced |
| `fail-optional` | `http_tokens = "optional"` | false | IMDSv1 still allowed |
| `fail-missing` | no `metadata_options` | false | Not declared, cannot be proven |

### 2.4 `network` (no unrestricted inbound SSH)

The policy checks the port **range** and the protocol, not only `22`.

| Case | Mock | Expected `main` | Why |
|---|---|---|---|
| `pass` | `tcp`, 22-22, `10.0.0.0/16` | true | Restricted source |
| `fail-ssh-open` | `tcp`, 22-22, `0.0.0.0/0` | false | SSH open to the world |
| `fail-range-open` | `tcp`, 0-65535, `0.0.0.0/0` | false | Range includes port 22 |
| `fail-all-protocols` | protocol `-1`, `0.0.0.0/0` | false | All protocols include SSH |

### 2.5 `sovereignty` (approved provider region)

The region is read from the provider configuration, not only from a variable, and the policy fails closed when the region cannot be proven.

| Case | Mock | Expected `main` | Why |
|---|---|---|---|
| `pass-variable` | `region = var.aws_region`, value `eu-west-1` | true | Same pattern as `providers.tf` |
| `pass-literal` | `region = "eu-west-1"` | true | Literal approved region |
| `fail-variable` | `aws_region = us-east-1` | false | Variable outside Ireland |
| `fail-literal` | Provider `region = "us-east-1"`, variable still `eu-west-1` | false | The variable is not used, the provider decides |
| `fail-alias` | Second `aws` provider (alias) in `us-east-1` | false | Checking one provider is not enough |
| `fail-unresolvable` | Region from `local.region` | false | Cannot be proven, so it is blocked |

### 2.6 `supply_chain_providers` (provider source and exact version)

| Case | Mock | Expected `main` | Rule that fails |
|---|---|---|---|
| `pass` | `registry.terraform.io/hashicorp/aws`, `= 5.82.2` | true | none |
| `fail-source` | Unknown publisher | false | `providers_from_approved_sources` |
| `fail-version-range` | `~> 5.0` | false | `providers_pinned` |
| `fail-version-open` | `>= 5.0` | false | `providers_pinned` |
| `fail-version-empty` | no version | false | `providers_pinned` |

`~> 5.0` and `>= 5.0` accept any matching release, so a new (possibly compromised) version could enter without a decision. Only an exact version counts as pinned.

### 2.7 `supply_chain_modules` (module source and pinned version)

The project does not use modules, so the real plan passes trivially. These mocks prove the policy would block an untrusted or unpinned module.

| Case | Mock | Expected `main` | Rule that fails |
|---|---|---|---|
| `pass` | `terraform-aws-modules/vpc/aws`, `= 5.8.1` | true | none |
| `pass-local` | `./modules/network`, no version | true | none (local modules are reviewed with the repository) |
| `fail-source` | `git::https://github.com/random-user/vpc.git` | false | `modules_from_trusted_sources` |
| `fail-unpinned` | trusted registry, `~> 5.0` | false | `modules_pinned` |
| `fail-version-missing` | trusted registry, no version | false | `modules_pinned` |

### 2.8 `data_residency` (sensitive data and cross-region copies)

| Case | Mock | Expected `main` | Rule that fails |
|---|---|---|---|
| `pass` | `DataClass = sensitive`, encrypted | true | none |
| `pass-not-sensitive` | no sensitive tag, not encrypted | true | none (the rule does not apply) |
| `pass-copy-in-region` | snapshot copy `eu-west-1` to `eu-west-1` | true | none |
| `fail-sensitive-unencrypted` | `DataClass = sensitive`, `encrypted = false` | false | `sensitive_encrypted` |
| `fail-copy-us` | snapshot copy to `us-east-1` | false | `copies_in_approved_regions` |

## 3. Real Terraform plans

The same code (`terraform/`) produces both plans. Only the variables change.

| Plan | `instance_type` | `allowed_ssh_cidr` | `aws_region` | File |
|---|---|---|---|---|
| Compliant | `t3.micro` | `10.0.0.0/16` | `eu-west-1` | `terraform/tfplan` |
| Non-compliant | `m5.large` | `0.0.0.0/0` | `us-east-1` | `terraform/tfplan-noncompliant` |

Encryption and IMDSv2 are fixed in `main.tf`, so they stay compliant in both plans. Their non-compliant cases are covered only by the unit scenarios above.

## 4. HCP Terraform scenarios

Three consolidated policies in `sentinel/hcp/`, one policy set.

| Policy | Groups | Enforcement |
|---|---|---|
| `infrastructure_security` | `instance_type`, `encryption`, `metadata`, `network` | hard-mandatory |
| `digital_sovereignty` | `sovereignty`, `data_residency` | advisory |
| `supply_chain` | `supply_chain_providers`, `supply_chain_modules` | advisory |

| Scenario | Variables | Expected result |
|---|---|---|
| Compliant run | `t3.micro`, `10.0.0.0/16`, `eu-west-1` | Three policies pass, apply waits for confirmation (not confirmed) |
| Non-compliant run | `m5.large`, `0.0.0.0/0`, `us-east-1` | `infrastructure_security` fails (hard), `digital_sovereignty` fails (advisory), `supply_chain` passes, `Apply will not run` |

## 5. Known gaps in the scenarios

- `sovereignty`: no case makes `azs_approved` or `explicit_regions_approved` fail. Failing cases stop at `provider_regions_approved`.
- `network`: no case makes `standalone_ingress_safe` fail (a standalone `aws_security_group_rule`).
- `supply_chain_*`: each failing case breaks one rule, none combines two failures.
- `data_residency`: only `aws_ebs_snapshot_copy` and `aws_ami_copy` are covered. S3 replication and RDS backups are not.
- The consolidated policies in `sentinel/hcp/` have no dedicated unit tests. Their rule logic is the same as in the modular policies and was validated by the two HCP runs.
- Mocks are written by hand and contain only the fields each policy reads. The compliant HCP run is the check that real plans match those fields.
