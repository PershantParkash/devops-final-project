variable "location" {
  description = "Azure region where resources will be created"
  default     = "East US"
}

variable "admin_username" {
  description = "Username for the VM"
  default     = "azureuser"
}

variable "vm_size" {
  description = "Size of the virtual machine"
  default     = "Standard_B1s"  # Small, cheap VM
}