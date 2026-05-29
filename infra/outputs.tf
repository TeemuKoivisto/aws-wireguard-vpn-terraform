output "ec2_ip" {
  value = module.ec2_instance.public_ip
}
output "cidr_blocks" {
  value = jsonencode([for r in aws_vpc_security_group_ingress_rule.vpn_ingress : r.cidr_ipv4])
}