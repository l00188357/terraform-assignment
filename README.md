# terraform-assignment
Policy-as-Code framework using Terraform and HashiCorp Sentinel for Irish digital sovereignty and IaC supply chain security. 

Student: Cassiana de Oliveira

Student Number: L00188357


# Policy as Code for Digital Sovereignty and IaC Supply Chain Security

Organisation: **ATUL0012345** | HCP Terraform organisation: `l00188357` | Repository: https://github.com/l00188357/terraform-assignment

A Policy-as-Code framework built with Terraform and HashiCorp Sentinel. It enforces digital sovereignty for Ireland (`eu-west-1`), IaC supply chain security and a baseline of infrastructure security **before** a plan can be applied. Nothing was ever deployed: only `terraform plan` was run, with mock credentials.

## 1. Deliverables map

| Deliverable | Where |
|---|---|
| Terraform configuration | `terraform/` (`.tf`, `.terraform.lock.hcl`, `tfplan`, `tfplan-noncompliant`) |
| Sentinel policies and unit tests | `sentinel/` (modular policies, `sentinel.hcl`, `test/`), `sentinel/hcp/` (consolidated policies used in HCP Terraform) |
| This README | `README.md` |
| Evidence of compliant and non-compliant evaluations | `documentation/evidence/` (screenshots, plan files, policy check log, `test-results.md`) |
| Test scenarios | `tests/test-scenarios.md` |
| CI | `.github/workflows/terraform-checks.yml` |
| Technical report (one page) | `documentation/technical-report/` |

```
.
├── README.md
├── .github/workflows/terraform-checks.yml
├── documentation/
│   ├── evidence/            screenshots, policy check log, test-results.md
│   └── technical-report/
├── sentinel/
│   ├── *.sentinel           8 modular policies (one theme each)
│   ├── sentinel.hcl         registers the modular policies
│   ├── test/<policy>/       pass/fail cases and mocks for `sentinel test`
│   └── hcp/                 3 consolidated policies pasted into HCP Terraform
├── terraform/               infrastructure under test
└── tests/test-scenarios.md  description of every scenario
```

`sentinel test` looks for `test/<policy>/` next to the `.sentinel` files, so mocks and test cases live in `sentinel/test/` and `tests/` only describes the scenarios.

## 2. What is deployed (and never applied)

`terraform/` describes a small AWS stack in `eu-west-1`: a VPC, a subnet, a security group, an EC2 instance (IMDSv2 required, encrypted root disk) and an encrypted EBS data volume tagged `DataClass = "sensitive"`.

Three variables (`instance_type`, `allowed_ssh_cidr`, `aws_region`) are enough to turn the compliant plan into a non-compliant one, without changing the code:

| Plan | `instance_type` | `allowed_ssh_cidr` | `aws_region` |
|---|---|---|---|
| Compliant (`tfplan`) | `t3.micro` | `10.0.0.0/16` | `eu-west-1` |
| Non-compliant (`tfplan-noncompliant`) | `m5.large` | `0.0.0.0/0` | `us-east-1` |

`providers.tf` uses mock credentials and skips credential validation, so a plan needs no AWS account. This is acceptable only for this exercise. In a real project credentials come from a secure login and are never written in code.

## 3. How policy enforcement prevents non-compliant deployments

```
terraform code  ->  terraform plan  ->  Sentinel policies  ->  pass: apply may continue
                                                           ->  fail (hard-mandatory): run stops
```

Sentinel does not read the `.tf` files. It evaluates the **plan** (`tfplan/v2`) and the declared configuration (`tfconfig/v2`). The plan holds the final values and nothing has been created yet, so a failing policy stops the run **before** any resource exists.

Enforcement levels in HCP Terraform:

- `hard-mandatory`: a failure stops the run and cannot be overridden.
- `advisory`: a failure is reported but the run continues.

In the non-compliant HCP run (`run-BWvcry5wJT8hqomP`), `infrastructure_security` failed as hard-mandatory and the run ended with **"Apply will not run"**.

## 4. Digital sovereignty

### What the policies enforce

| Requirement | Policy | Rule |
|---|---|---|
| Deployments only in approved regions | `sovereignty` | The region of every `aws` provider (including aliases) must resolve to `eu-west-1`. Region from a variable or a literal is accepted. A region that cannot be proven blocks the plan (fail closed). Explicit availability zones and `region` attributes must also be approved |
| Data residency for sensitive data | `data_residency` | Resources tagged `DataClass = "sensitive"` must be encrypted |
| Replication and backups | `data_residency` | `aws_ebs_snapshot_copy` and `aws_ami_copy` must have source and destination in approved regions |

The region is read from the provider configuration and not only from `var.aws_region`. A variable can say Ireland while the provider is written with `us-east-1`, so checking only the variable would prove nothing. The test `fail-literal` covers this, and `fail-alias` covers a second provider in another region.

### How jurisdictional restrictions contribute to digital sovereignty

Digital sovereignty is the ability of a state or organisation to keep control over its data and systems under its own legal framework. Restricting deployments to an approved region is the first technical step: the data is stored and processed in a place where EU and Irish law apply and where the organisation can name the location. Writing that restriction as code makes it repeatable, reviewable in Git and enforced for every deployment, instead of depending on each engineer remembering it.

### Replication, backups and administrative access

- **Replication and backups** are where data leaves a jurisdiction without anyone moving the primary resource. The policy checks the destination region of snapshot and AMI copies. S3 replication and RDS backup replication are not covered (see section 8).
- **Administrative access** is not visible in a plan. Who can reach the data (cloud provider staff, IAM roles, support access) is controlled by identity policies, key management and contracts, not by a region setting. Sentinel cannot check it.

## 5. IaC supply chain security

### What the policies enforce

| Requirement | Policy | Rule |
|---|---|---|
| Providers from approved sources | `supply_chain_providers` | `full_name` must be `registry.terraform.io/hashicorp/aws` |
| Approved provider versions | `supply_chain_providers` | The version constraint must be exact (`5.82.2` or `= 5.82.2`). `~> 5.0`, `>= 5.0` and an empty version are rejected |
| Trusted modules with pinned versions | `supply_chain_modules` | Source must start with `terraform-aws-modules/` or `./`, and registry modules need an exact version |
| Provider integrity | `.terraform.lock.hcl` and CI | The lock file stores provider hashes for Linux, Windows and macOS, and the CI runs `terraform init -lockfile=readonly` |

`~> 5.0` is not pinning: it accepts any 5.x release, so a new and possibly compromised version could enter without anyone deciding it. Only an exact version counts.

The project uses no modules today, so the real plan passes this check trivially. The mocks prove the policy would block an untrusted or unpinned module.

### Provider integrity in practice

The first CI run failed because of this protection: `terraform init -lockfile=readonly` rejected the provider package downloaded on the Linux runner, because the lock file had only the hash of the Windows machine where it was generated. Hashes for the other platforms were added with `terraform providers lock` and the run then passed. This showed that version pinning (checked by Sentinel) and hash verification (checked by `terraform init`) are different controls.

### Risks that Sentinel alone cannot address

| Risk | Why Sentinel cannot see it | Mitigation |
|---|---|---|
| Provider or module package replaced | Sentinel sees the declared version, not the downloaded bytes | Lock file hashes, `-lockfile=readonly` in CI |
| Signature and provenance | No signature or attestation check | Verify signatures, use a private registry or mirror |
| Content of a module | Sentinel sees source and version, not the code | Code review, scanning, vendoring |
| Transitive dependencies | Only direct declarations are checked | Dependency scanning, SBOM |
| Policies changed by the same person who deploys | The policy code lives in the same repository | Branch protection, required reviews, separate policy repository |
| CI actions referenced by tag | `actions/checkout@v4` and `setup-terraform@v3` can move | Pin actions to a commit SHA |
| Sentinel CLI download | Checked against `SHA256SUMS`, but not the GPG signature | Verify the signature of the checksum file |

## 6. Infrastructure security policies

| Requirement | Policy | Rule |
|---|---|---|
| Approved EC2 instance types | `instance_type` | `t3.micro` or `t3.small` |
| Encrypted EBS storage | `encryption` | Standalone `aws_ebs_volume` encrypted, and every EC2 root disk declared and encrypted |
| Mandatory IMDSv2 | `metadata` | `metadata_options` declared with `http_tokens = "required"` |
| Network security and no open SSH | `network` | No ingress rule open to `0.0.0.0/0` or `::/0` that reaches port 22 |

Design points:

- The root disk is a nested block inside `aws_instance`, not a separate resource. A policy that only filtered `aws_ebs_volume` would miss an unencrypted root disk, so there are two rules and two failing tests.
- An undeclared `metadata_options` or `root_block_device` is treated as non-compliant. An absent block cannot prove the control, and the AWS default allows IMDSv1.
- In Sentinel, `all` over an empty collection is `true`, so these rules also require the block to exist (`length(...) > 0`).
- The SSH rule checks the port range and the protocol: ports 0-65535 and protocol `-1` also expose SSH.

## 7. Implementation and testing

### Three layers of evidence

| Layer | What it proves | Evidence |
|---|---|---|
| Sentinel unit tests (`sentinel test`, v0.41.0) | Each policy passes a compliant mock and blocks a non-compliant one: 33 cases across 8 policies | `documentation/evidence/04` to `11`, `tests/test-scenarios.md` |
| Real Terraform plans | The same code gives a compliant and a non-compliant plan | `terraform/tfplan`, `terraform/tfplan-noncompliant`, evidence `01` to `03` and `12` |
| HCP Terraform runs | The consolidated policies block the non-compliant plan on real data | evidence `13` to `17`, `run-BWvcry5wJT8hqomP-policy-check-log.txt` |
| GitHub Actions | `fmt`, `validate`, lock file check and `sentinel test` on every change | evidence `18` |

A `PASS` in a `fail-*` unit test means the policy blocked the plan. Full results and the screenshot behind each case are in `documentation/evidence/test-results.md`.

### HCP Terraform results

| Run | Variables | `infrastructure_security` | `digital_sovereignty` | `supply_chain` | Outcome |
|---|---|---|---|---|---|
| `run-gVUc3Qwv2RxGAC4y` | `t3.micro`, `10.0.0.0/16`, `eu-west-1` | Passed | Passed | Passed | Apply waiting, not confirmed |
| `run-BWvcry5wJT8hqomP` | `m5.large`, `0.0.0.0/0`, `us-east-1` | **Failed** (hard) | **Advisory failed** | Passed | `Apply will not run` |

Both runs used the same commit (`6e5903f`), so the difference comes only from the three variables.

### Why three consolidated policies in HCP Terraform

The Free edition allows one policy set with up to five policies, and the repository has eight modular policies. The same rules are grouped by theme in `sentinel/hcp/`:

| HCP policy | Groups | Enforcement |
|---|---|---|
| `infrastructure_security` | `instance_type`, `encryption`, `metadata`, `network` | hard-mandatory |
| `digital_sovereignty` | `sovereignty`, `data_residency` | advisory |
| `supply_chain` | `supply_chain_providers`, `supply_chain_modules` | advisory |

The Free edition also did not allow more than one hard-mandatory policy, and VCS-backed policy sets need a paid plan. The policies were therefore pasted as individually managed policies. The consolidated files have no dedicated unit tests: their rule logic is the same as in the modular policies, and the two HCP runs validated them on real plans. Local tests use Sentinel v0.41.0 and HCP Terraform runs 0.40.x.

### Observed behaviour worth knowing

- **Short-circuit.** `main` combines rules with `and` and Sentinel stops at the first failure. In the non-compliant run the trace lists only `instance_type_allowed`, although the plan also contained the open SSH rule and `us-east-1a`. Those rules are covered by the unit tests.
- **Advisory is not blocking.** A run that violated only the sovereignty policy would continue to the apply stage. Because of the plan limit, the central sovereignty policy cannot block. In production all three would be hard-mandatory.
- **The description lies, the value does not.** The open SSH rule still has the description "SSH from trusted network only". A human reviewer could be misled, while the policy evaluates the actual value.

## 8. Decision justification

### Effectiveness of Policy as Code for digital sovereignty

Policy as Code is effective at making a rule **consistent, early and auditable**: the rule is written once, versioned, tested with pass and fail cases, and applied to every plan before anything is created. The compliant and non-compliant runs show a violation being stopped before deployment.

Its effectiveness is limited to what a plan can show. It controls **where infrastructure is deployed**, not **who controls the data**. It is a strong preventive control for location and configuration, and a weak one for legal and operational control.

### Limitations of region-based data residency controls

- A region is a location, not a jurisdiction. A provider headquartered outside the EU can be subject to foreign law (for example the US CLOUD Act) even for data stored in Ireland.
- Administrative and support access, and the identity of whoever holds the encryption keys, are not part of a region setting.
- Encryption with provider-managed keys gives less control than customer-managed keys. Key IDs are often known only after apply.
- Global services (IAM, CloudFront, Route 53) have no region and are excluded from the region checks.
- Replication, backups and logs can move data outside the region. Only EBS snapshot and AMI copies are checked here. S3 replication and RDS backup replication are not.
- The strongest guarantee is on the cloud side: an AWS Organizations service control policy using `aws:RequestedRegion` blocks creation outside the approved regions even if Terraform or Sentinel is bypassed.

### Importance of supply chain integrity

An IaC pipeline downloads and executes code from providers and modules with the permissions of the deployment. If a package is replaced or a new release is compromised, it runs inside the infrastructure. Exact versions decide **which** release is used. Lock file hashes decide that the downloaded package is **the expected one**. The CI failure in this project is a real example of the second control doing its job.

### Limitations of Sentinel and plan-time enforcement

- Sentinel sees the plan, not the running environment. Drift, manual changes in the console and resources created outside Terraform are not covered.
- Values that are `(known after apply)`, such as the availability zone of an instance or key IDs, cannot be checked at plan time.
- Rules that depend on a field only protect against what they read. For example, the AZ rule ignores an instance without an explicit zone, so the provider region check must carry the weight.
- Short-circuit evaluation hides later failures in a trace.
- The policy code sits in the same repository as the infrastructure, so someone with write access could weaken it. Branch protection and review are needed.
- Mocks are hand-written and contain only the fields each policy reads. The compliant HCP run is the check that real plans match them.

### Challenges of maintaining policies as cloud environments evolve

- Providers add resource types and attributes. A policy written for `aws_instance` does not cover a new resource type that does the same thing.
- Provider schema changes can break a policy silently or make it fail closed (for example a renamed field).
- Approved regions, instance types and module sources change with the organisation, and every change needs a reviewed and tested update.
- Tooling differs between environments (Sentinel 0.41.0 locally and 0.40.x in HCP Terraform).
- Plan limits and licences shape the design: here they forced the consolidation into three policies and left two of them advisory.
- Policies need an owner, tests that grow with each incident, and regular review, or they become a false sense of security.

## 9. Reproduce

```powershell
# Terraform plans (no apply, mock credentials)
cd terraform
terraform init
terraform plan -out=tfplan
terraform plan -no-color -out=tfplan-noncompliant -var="instance_type=m5.large" -var="allowed_ssh_cidr=0.0.0.0/0" -var="aws_region=us-east-1"
terraform show -no-color tfplan | Out-File -Encoding utf8 tfplan.txt

# Sentinel unit tests
cd ../sentinel
sentinel test -verbose
```

**Never run `terraform apply` in this project.**

## 10. Declaration of AI tool use

Tool: Claude

Model: Claude Sonnet 5.5

Prompt on 9th November 2026: "I don't even know where to start..." (with the assignment PDF attached) and "Let's do it together because I want to learn and understand what we are doing."


Tool: DeepSeek

Model: DeepSeek-V3

Used as a learning aid to clarify concepts (e.g., Sentinel logic, HCP Terraform integration, supply chain security) and to outline the next steps of the assignment.
