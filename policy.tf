resource "azurerm_policy_definition" "deny_public_ip" {
  name         = "deny-public-ip"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Deny Public IP Creation"

  policy_rule = jsonencode({
    if = {
      field = "type"
      equals = "Microsoft.Network/publicIPAddresses"
    }
    then = {
      effect = "deny"
    }
  })
}
resource "azurerm_subscription_policy_assignment" "assign_deny_public_ip" {
  name                 = "deny-public-ip-assignment"
  policy_definition_id = azurerm_policy_definition.deny_public_ip.id
  subscription_id      = data.azurerm_subscription.current.id
}
data "azurerm_subscription" "current" {}

