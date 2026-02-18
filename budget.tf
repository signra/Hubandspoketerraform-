resource "azurerm_consumption_budget_subscription" "budget" {
  name            = "monthly-budget"
  subscription_id = data.azurerm_subscription.current.id
  amount          = 100
  time_grain      = "Monthly"

  time_period {
    start_date = "2026-02-01T00:00:00Z"
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    contact_emails = ["mshariff844@gmail.com"]
  }
}
