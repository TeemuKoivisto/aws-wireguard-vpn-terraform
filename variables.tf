variable "region" {
  type = string
}
variable "ssh_key_name" {
  type = string
}
variable "whitelisted_ips" {
  type = list(string)
}
variable "client_public_key" {
  type = string
  validation {
    condition     = can(regex("^[A-Za-z0-9+/]{43}=$", var.client_public_key))
    error_message = "client_public_key must be a valid WireGuard public key (44-char base64). Set TF_VAR_client_public_key from `cat /opt/homebrew/etc/wireguard/publickey`."
  }
}