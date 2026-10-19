
locals {
  owner       = trimspace(var.owner)
  managedby   = "terraform"
  projectname = trimspace(var.projectname)
  costcenter  = trimspace(var.costcenter)

  common_tags = {
    owner       = local.owner
    managedby   = local.managedby
    projectname = local.projectname
    costcenter  = local.costcenter

    environment = var.environment
    application = var.application_name
    repository  = var.repository
  }

  name_prefix = "${local.projectname}-${var.environment}"

  required_tag_values = {
    owner       = local.owner
    managedby   = local.managedby
    projectname = local.projectname
    costcenter  = local.costcenter
  }
}
