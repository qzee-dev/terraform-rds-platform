
run "mandatory_tags_are_present" {
  command = plan

  assert {
    condition = (
      contains(keys(local.common_tags), "owner") &&
      contains(keys(local.common_tags), "managedby") &&
      contains(keys(local.common_tags), "projectname") &&
      contains(keys(local.common_tags), "costcenter")
    )

    error_message = (
      "All four mandatory lowercase tag keys must be present."
    )
  }
}
This is a configuration-level test, not proof that every AWS resource is tagged or that an organization policy is active. Additional tests and policy scanning are needed to establish those contro
