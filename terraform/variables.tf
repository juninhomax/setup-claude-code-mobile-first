# =============================================================================
# variables.tf — Variables for Claude Code multi-agent VM
# =============================================================================

variable "resource_group_name" {
  description = "Azure resource group name"
  type        = string
  default     = "rg-claude-agents"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "vm_name" {
  description = "VM name"
  type        = string
  default     = "vm-claude-agents"
}

variable "vm_size" {
  description = "VM size (B2s=budget, B2ms=comfort, B4ms=perf)"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "SSH admin user"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 30
}

variable "enable_public_ip" {
  description = "true = Option A (public IP), false = Option B (Tailscale only)"
  type        = bool
  default     = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR allowed for SSH (Option A). e.g. your-ip/32 or 0.0.0.0/0"
  type        = string
  default     = "0.0.0.0/0"
}

variable "subscription_id" {
  description = "Azure subscription ID (az account show --query id -o tsv)"
  type        = string
}

variable "web_password" {
  description = "Password for web terminal (ttyd) and code-server. Auto-generated if empty."
  type        = string
  sensitive   = true
  default     = ""
}

variable "tags" {
  description = "Azure tags"
  type        = map(string)
  default = {
    project     = "claude-code-agents"
    environment = "dev"
    managed_by  = "terraform"
  }
}
