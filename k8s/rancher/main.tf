terraform {
  required_providers {
    rancher2 = {
      source = "rancher/rancher2"
      version = "3.2.0"
    }
  }
}

provider "rancher2" {
  api_url    = "https://rancher.admin.local"
  access_key = var.rancher_access_key
  secret_key = var.rancher_secret_key
  insecure   = true
}

variable "rancher_access_key" {
  type = string
}

variable "rancher_secret_key" {
  type = string
}

variable "students" {
  type    = list(string)
  default = ["eric", "sarah", "michael", "jessica"]
}

# Fetch the local cluster ID
data "rancher2_cluster" "local" {
  name = "local"
}

# Create a project for each student
resource "rancher2_project" "student_projects" {
  for_each   = toset(var.students)
  name       = "student-${each.value}-project"
  cluster_id = data.rancher2_cluster.local.id
  
  description = "Project boundary for ${each.key}. They have autonomy inside this project."
  
  # Allow the student to create namespaces within the project
  # (Note: In a real environment, you'd map standard Rancher users to these projects using rancher2_project_role_template_binding)
}

output "project_ids" {
  value = { for k, v in rancher2_project.student_projects : k => v.id }
}
