# Test Results and Evidence

Organisation: ATUL0012345 | HCP Terraform organisation: `l00188357`

All screenshots are in this folder (`documentation/evidence/`). Each screenshot shows the date and time in the taskbar. Local tests were run on 9-11 November 2026 and the HCP Terraform runs on 12 November 2026.

## 1. Environment

| Item | Value |
|---|---|
| Terraform (local) | `terraform 1.17.2.` |
| Terraform (HCP Terraform) | 1.17.2 |
| AWS provider | `hashicorp/aws` pinned to `= 5.82.2` |
| Sentinel CLI (local) | v0.41.0 |
| Sentinel runtime (HCP Terraform, Platform environment) | 0.40.x |
| Approved region | `eu-west-1` (Ireland) |
| Credentials | Mock credentials in `providers.tf`. `terraform apply` was never run |

## 2. Terraform plans (local)

| Plan | Command | Result | Files | Screenshots |
|---|---|---|---|---|
| Compliant | `terraform plan -out=tfplan` | `Plan: 6 to add, 0 to change, 0 to destroy` | `terraform/tfplan`, `tfplan.txt`, `tfplan.json` | `01-compliant-plan-start.png`, `02-compliant-plan-summary.png`, `03-compliant-imdsv2-encryption.png` |
| Non-compliant | `terraform plan -no-color -out=tfplan-noncompliant -var="instance_type=m5.large" -var="allowed_ssh_cidr=0.0.0.0/0" -var="aws_region=us-east-1"` | `Plan: 6 to add, 0 to change, 0 to destroy` | `terraform/tfplan-noncompliant`, `.txt`, `.json` | `12-noncompliant-plan-1.png`, `-2.png`, `-3.png` |

What each screenshot shows:

- `01`: plan command and the data volume (`encrypted = true`, `DataClass = "sensitive"`).
- `02`: plan summary, `Saved the plan to: tfplan`, and the three `tfplan*` files.
- `03`: `tfplan.txt` with `http_tokens = "required"` and `encrypted = true` under `aws_instance.app`.
- `12-1`: the non-compliant command with the three `-var` values, and `availability_zone = "us-east-1a"`.
- `12-2`: `Plan: 6 to add...` and `Saved the plan to: tfplan-noncompliant`.
- `12-3`: `terraform show` output files and a `Select-String` search of `tfplan-noncompliant.txt`: `m5.large` (line 53), `us-east-1a` (lines 11 and 178), `0.0.0.0/0` (lines 133 and 149).

Notes:

- Screenshot `02` was taken when `tfplan.txt` and `tfplan.json` were still in UTF-16 with colour codes (25584 and 31612 bytes). They were regenerated in UTF-8 without colours (10383 and 15808 bytes), and those are the versions in the repository.
- `terraform plan` does not block anything by itself. Blocking is done by Sentinel (sections 3 and 4).

## 3. Sentinel unit tests (local, `sentinel test`)

Each test supplies a mock plan and states the expected value of `main`. A `PASS` on a `fail-*` case means the policy correctly **blocked** the plan. Tests and mocks are in `sentinel/test/<policy>/` because `sentinel test` looks for `test/<policy>/` next to the `.sentinel` files.

| Policy | Case | Scenario | Expected `main` | Screenshot |
|---|---|---|---|---|
| `instance_type` | `pass` | `t3.micro` | true | `04` |
| `instance_type` | `fail` | `m5.large` | false | `04` |
| `encryption` | `fail-ebs` | Data volume unencrypted | false | `05-2` |
| `encryption` | `fail-root` | Root disk unencrypted | false | `05-2` |
| `encryption` | `pass` | Root and data volumes encrypted | true | `05-3` |
| `metadata` | `fail-missing` | `metadata_options` not declared | false | `06-1` |
| `metadata` | `fail-optional` | `http_tokens = "optional"` | false | `06-1`, `06-2` |
| `metadata` | `pass` | `http_tokens = "required"` | true | `06-2` |
| `network` | `fail-all-protocols` | Protocol `-1` from `0.0.0.0/0` | false | `07-1` |
| `network` | `fail-range-open` | Ports 0-65535 from `0.0.0.0/0` | false | `07-1` |
| `network` | `fail-ssh-open` | Port 22 from `0.0.0.0/0` | false | `07-1`, `07-2` |
| `network` | `pass` | SSH from `10.0.0.0/16` | true | `07-2` |
| `sovereignty` | `fail-alias` | Second aws provider (alias) in `us-east-1` | false | `08-1` |
| `sovereignty` | `fail-literal` | Provider region `us-east-1`, variable says `eu-west-1` | false | `08-1` |
| `sovereignty` | `fail-unresolvable` | Region from `local.region` (cannot be proven) | false | `08-1`, `08-2` |
| `sovereignty` | `fail-variable` | Variable `aws_region` = `us-east-1` | false | `08-2` |
| `sovereignty` | `pass-literal` | Provider region written as `eu-west-1` | true | `08-2`, `08-3` |
| `sovereignty` | `pass-variable` | Provider region from `var.aws_region` = `eu-west-1` | true | `08-3`, `08-4` |
| `supply_chain_providers` | `fail-source` | Unknown publisher | false | `09-1` |
| `supply_chain_providers` | `fail-version-empty` | No version | false | `09-1`, `09-2` |
| `supply_chain_providers` | `fail-version-open` | `>= 5.0` | false | `09-2`, `09-3` |
| `supply_chain_providers` | `fail-version-range` | `~> 5.0` | false | `09-3`, `09-4` |
| `supply_chain_providers` | `pass` | `hashicorp/aws`, `= 5.82.2` | true | `09-4`, `09-5` |
| `supply_chain_modules` | `fail-source` | Random GitHub repository | false | `10-1` |
| `supply_chain_modules` | `fail-unpinned` | `~> 5.0` | false | `10-1` |
| `supply_chain_modules` | `fail-version-missing` | Registry module without version | false | `10-2` |
| `supply_chain_modules` | `pass-local` | Local `./` module | true | `10-2`, `10-3`, `10-4` |
| `supply_chain_modules` | `pass` | Trusted registry, `= 5.8.1` | true | `10-3`, `10-4` |
| `data_residency` | `fail-copy-us` | Backup copied to `us-east-1` | false | `11-1` |
| `data_residency` | `fail-sensitive-unencrypted` | `DataClass = sensitive`, not encrypted | false | `11-1`, `11-2` |
| `data_residency` | `pass-copy-in-region` | Snapshot copy within `eu-west-1` | true | `11-2` |
| `data_residency` | `pass-not-sensitive` | No sensitive tag, rule does not apply | true | `11-2`, `11-3` |
| `data_residency` | `pass` | Sensitive and encrypted | true | `11-3`, `11-4` |

Screenshot file names: `04-sentinel-instance-type-test.png`, `05-sentinel-encryption-test-N.png`, `06-sentinel-metadata-test-N.png`, `07-sentinel-network-test-N.png`, `08-sentinel-sovereignty-test-N.png`, `09-sentinel-supply-chain-providers-test-N.png`, `10-sentinel-supply-chain-modules-test-N.png`, `11-sentinel-data-residency-test-N.png`. A trace is often split across two consecutive screenshots, so a case can appear in two of them.

### Coverage limits visible in the traces

- Short-circuit: `main` combines rules with `and`, and Sentinel stops at the first rule that fails. In the `fail-*` cases of `sovereignty`, only `provider_regions_approved` appears. `azs_approved` and `explicit_regions_approved` appear only as `true` in the `pass` cases, so no test makes them fail.
- The same applies to `network`: `standalone_ingress_safe` appears only as `true` in `pass`. No test makes it fail.
- In `supply_chain_providers` and `supply_chain_modules`, each `fail-*` case breaks one rule at a time. No test combines two failures.
- `encryption` and `data_residency` have a case that fails each rule on its own.

## 4. HCP Terraform runs (policy enforcement on real plans)

Three consolidated policies in one policy set (`digital-sovereignty-baseline`), because the Free edition allows one policy set with up to five policies. Workspace `terraform-assignment`, Auto-apply off, source: GitHub, branch `main`, commit `6e5903f` (merge of PR #10). Both runs used the same commit, so the only difference between them is the three variables.

### 4.1 Compliant run

| Item | Value |
|---|---|
| Run | `run-gVUc3Qwv2RxGAC4y` (12/11/2026) |
| Variables | `instance_type = t3.micro`, `allowed_ssh_cidr = 10.0.0.0/16`, `aws_region = eu-west-1` |
| Plan | 6 to add, 0 to change, 0 to destroy |
| `infrastructure_security` | Passed |
| `digital_sovereignty` | Passed |
| `supply_chain` | Passed |
| Apply | Discarded |

| Screenshot | Shows |
|---|---|
| `13-hcp-compliant-variables.png` (04:44) | The three compliant variables |
| `14-hcp-compliant-run-1.png` (04:09) | `3 of 3 passed`, commit, `Plan finished: 6 to add` |
| `14-hcp-compliant-run-2.png` (04:07) | Three policies **Passed** and `Apply pending` |

The variables screenshot (04:44) was taken after the run (04:05-04:09). The values did not change in between, and the plan log of the run shows the values used.

### 4.2 Non-compliant run

| Item | Value |
|---|---|
| Run | `run-BWvcry5wJT8hqomP` (12/11/2026) |
| Variables | `instance_type = m5.large`, `allowed_ssh_cidr = 0.0.0.0/0`, `aws_region = us-east-1` |
| Plan | 6 to add, 0 to change, 0 to destroy |
| `infrastructure_security` | **Failed** (hard-mandatory). Rule `instance_type_allowed` = false |
| `digital_sovereignty` | **Advisory failed**. Rule `provider_regions_approved` = false |
| `supply_chain` | Passed (all four rules true) |
| Result | `Sentinel policies hard failed`, `Apply will not run` |

| Screenshot | Shows |
|---|---|
| `15-hcp-noncompliant-variables.png` (04:47) | The three non-compliant variables, taken before the run |
| `16-hcp-noncompliant-run-1-top.png` (04:53) | Run name, `Errored`, `1 of 3 passed`, commit |
| `16-hcp-noncompliant-run-2-hard-failed.png` (04:50) | `1 hard failed, 1 advisory failed`, `infrastructure_security` Failed, `Apply will not run` |
| `16-hcp-noncompliant-run-3-all.png` (04:54) | The three policies with their status |
| `16-hcp-noncompliant-run-4a-plan-instance-type.png` (06:16) | `instance_type: "m5.large"` in the expanded `aws_instance.app` |
| `16-hcp-noncompliant-run-4b-plan-ssh.png` (09:13) | `ingress` rule of `sovereign-app-sg`: port 22, `tcp`, `cidr_blocks: "0.0.0.0/0"`. Its description still says "SSH from trusted network only" |
| `16-hcp-noncompliant-run-4c-plan-region.png` (06:15) | `aws_subnet.main` with `availability_zone: "us-east-1a"` |
| `16-hcp-noncompliant-run-5-trace-infrastructure.png` (06:44) | `hard-mandatory`, `main` false, `instance_type_allowed` false |
| `16-hcp-noncompliant-run-6-trace-sovereignty.png` (06:44) | `advisory`, `main` false, `provider_regions_approved` false |
| `17-hcp-variables-restored.png` (06:50) | Variables restored to `t3.micro`, `10.0.0.0/16`, `eu-west-1` |
| `run-BWvcry5wJT8hqomP-policy-check-log.txt` | Full policy check log of the run |

Screenshots `4a` to `6` and `17` were taken later than the run, from the same run page (`4b` at 09:13 p. m.). The log file contains the same results as the traces.

### 4.3 Violation to evidence

| Violation | Variable | Where it appears in the plan | Policy that reacted | Evidence |
|---|---|---|---|---|
| Instance type not approved | `instance_type = m5.large` | `instance_type: "m5.large"` | `infrastructure_security` (blocked) | `16-...-4a`, `16-...-5`, log |
| SSH open to the world | `allowed_ssh_cidr = 0.0.0.0/0` | `ingress` rule on port 22 | Not evaluated in this run (see section 5) | `16-...-4b`, `tfplan-noncompliant.txt`, `network` unit tests (`07`) |
| Region outside Ireland | `aws_region = us-east-1` | `availability_zone: "us-east-1a"` | `digital_sovereignty` (advisory) | `16-...-4c`, `16-...-6`, log |

## 5. Observations

- **Short-circuit confirmed by the log.** `infrastructure_security` lists only `main` and `instance_type_allowed`, and `digital_sovereignty` lists only `main` and `provider_regions_approved`. The open SSH rule and the `us-east-1a` availability zones were in the same plan, but `sg_ingress_safe` and `azs_approved` were not evaluated, because an earlier rule had already failed. They are covered separately by the unit tests in section 3.
- **Enforcement levels.** The Free edition did not allow more than one hard-mandatory policy, so only `infrastructure_security` blocks the run. `digital_sovereignty` and `supply_chain` are advisory. A run that violated only the sovereignty policy would continue to the apply stage. In production all three would be hard-mandatory.
- **Real data confirmed the fail-closed design.** `tfplan.raw` and the `tfconfig/v2` fields had only been tested with hand-written mocks. In HCP Terraform the compliant run passed all three policies, and the non-compliant run detected `us-east-1` through the provider configuration.
- **Runtime difference.** Local tests use Sentinel v0.41.0 and HCP Terraform uses 0.40.x.
- **Policy sets.** VCS-backed policy sets are not available in the Free edition. Policies were pasted as individually managed policies, and the source files are in `sentinel/hcp/`. The consolidated files have no dedicated local tests. Their rule logic is the same as in the modular policies that were tested.
- **Log header.** The log shows `<empty policy set name>` as the policy set name. This is how HCP Terraform labels individually managed policies.
