terraform {
  required_providers {
    rancher2 = {
      source  = "rancher/rancher2"
      version = "3.2.0"
    }
  }
}

# ── Provider ────────────────────────────────────────────────────────────────
# Set RANCHER_URL and RANCHER_TOKEN env vars, or pass via -var flags.
# Do NOT hard-code credentials here.
provider "rancher2" {
  api_url   = var.rancher_url
  token_key = var.rancher_token
  insecure  = false # cert-manager provides a valid cert — keep this false!
}

# ── Variables ────────────────────────────────────────────────────────────────
variable "rancher_url" {
  type        = string
  description = "The HTTPS URL of the Rancher server (e.g., https://rancher.your-domain.com)"
}

variable "rancher_token" {
  type        = string
  sensitive   = true
  description = "Rancher API token (Bearer token). Generate from Rancher UI → Account → API Keys."
}

variable "students" {
  type        = list(string)
  description = "List of student usernames. Loaded from students.tfvars."
  default     = []
  # Example: ["tanaka", "yamamoto", "sato", "suzuki"]
}

variable "student_password_prefix" {
  type        = string
  description = "Password prefix. Final password will be <prefix>-<username>. Change before seminar!"
  default     = "AdmiralBash"
  sensitive   = true
}

# ── Data Sources ─────────────────────────────────────────────────────────────
# Fetch the local (single-node) cluster managed by Rancher
data "rancher2_cluster" "local" {
  name = "local"
}

# ── Local Users ───────────────────────────────────────────────────────────────
# Creates one Rancher local user per student.
# Username: sailor-<name>, e.g. sailor-tanaka
resource "rancher2_user" "students" {
  for_each = toset(var.students)

  name     = "Sailor ${title(each.value)}"
  username = "sailor-${each.value}"
  password = "${var.student_password_prefix}-${each.value}"
  enabled  = true
}

# ── Rancher Projects ──────────────────────────────────────────────────────────
# Each student gets their own isolated Project (= RBAC boundary in Rancher).
resource "rancher2_project" "student_projects" {
  for_each = toset(var.students)

  name       = "crew-${each.value}"
  cluster_id = data.rancher2_cluster.local.id
  description = "⚓ ${title(each.value)}'s crew quarters. Full autonomy inside these bulkheads."

  # ResourceQuota — prevent any one student from sinking the whole ship
  resource_quota {
    project_limit {
      limits_cpu       = "2000m"
      limits_memory    = "2048Mi"
      requests_storage = "5Gi"
    }
    namespace_default_limit {
      limits_cpu       = "500m"
      limits_memory    = "512Mi"
      requests_storage = "1Gi"
    }
  }
}

# ── Project Role Bindings ────────────────────────────────────────────────────
# Bind each student user to their own project as "project-member".
# They get full control inside their project but cannot see others'.
resource "rancher2_project_role_template_binding" "student_bindings" {
  for_each = toset(var.students)

  name             = "sailor-${each.value}-binding"
  project_id       = rancher2_project.student_projects[each.value].id
  role_template_id = "project-member"
  user_id          = rancher2_user.students[each.value].id
}

# ── Namespaces ───────────────────────────────────────────────────────────────
# Create the primary student namespace inside their project.
resource "rancher2_namespace" "student_namespaces" {
  for_each = toset(var.students)

  name       = "student-${each.value}"
  project_id = rancher2_project.student_projects[each.value].id

  labels = {
    "admiral-bash/student" = each.value
    "admiral-bash/type"    = "crew-quarters"
  }
}

# ── Outputs ───────────────────────────────────────────────────────────────────
output "student_credentials" {
  description = "Print credentials summary. Pipe to a file for distribution: terraform output -json student_credentials"
  sensitive   = true
  value = {
    for s in var.students : s => {
      username  = "sailor-${s}"
      password  = "${var.student_password_prefix}-${s}"
      namespace = "student-${s}"
      project   = "crew-${s}"
    }
  }
}
