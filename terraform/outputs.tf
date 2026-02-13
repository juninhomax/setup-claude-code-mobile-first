# =============================================================================
# outputs.tf — Outputs after terraform apply
# =============================================================================

output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "vm_name" {
  description = "VM name"
  value       = azurerm_linux_virtual_machine.main.name
}

output "vm_private_ip" {
  description = "VM private IP"
  value       = azurerm_network_interface.main.private_ip_address
}

output "vm_public_ip" {
  description = "VM public IP (null if Tailscale-only)"
  value       = var.enable_public_ip ? azurerm_public_ip.main[0].ip_address : "None (Tailscale mode)"
}

output "ssh_command" {
  description = "SSH command to connect"
  value       = var.enable_public_ip ? "ssh -i ~/.ssh/id_ed25519 ${var.admin_username}@${azurerm_public_ip.main[0].ip_address}" : "ssh ${var.admin_username}@<Tailscale-IP>"
}

output "web_terminal_url" {
  description = "Web terminal URL"
  value       = var.enable_public_ip ? "https://${azurerm_public_ip.main[0].ip_address}/" : "https://<Tailscale-IP>/"
}

output "code_server_url" {
  description = "VS Code web URL"
  value       = var.enable_public_ip ? "https://${azurerm_public_ip.main[0].ip_address}:8080/" : "https://<Tailscale-IP>:8080/"
}

output "web_password" {
  description = "Web password for ttyd and code-server (login: user)"
  value       = local.web_password
  sensitive   = true
}

output "next_steps" {
  description = "Next steps"
  value       = <<-EOT

    ============================================
    VM DEPLOYED! Setup is automatic.
    ============================================

    1. Wait 3-5 min for cloud-init to finish:
       ${var.enable_public_ip ? "ssh -i ~/.ssh/id_ed25519 ${var.admin_username}@${azurerm_public_ip.main[0].ip_address}" : "ssh ${var.admin_username}@<IP>"} 'test -f ~/.cloud-init-complete && echo OK || echo IN PROGRESS'

    2. Web terminal:
       URL: ${var.enable_public_ip ? "https://${azurerm_public_ip.main[0].ip_address}/" : "https://<Tailscale-IP>/"}
       Login: user
       Password: terraform output -raw web_password

    3. VS Code web:
       URL: ${var.enable_public_ip ? "https://${azurerm_public_ip.main[0].ip_address}:8080/" : "https://<Tailscale-IP>:8080/"}

    4. Configure your API key:
       nano ~/.claude-env

    5. Launch multi-agent workspace:
       bash scripts/07-launch-agents.sh --project ~/workspace/my-project

  EOT
}
