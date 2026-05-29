module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  name = "${var.project}-ec2"

  instance_type          = "t2.micro"
  key_name               = var.ssh_key_name
  create_security_group  = false
  vpc_security_group_ids = [module.vpn_sg.security_group_id]
  # Ubuntu 22.04
  ami       = "ami-04e601abe3e1a910f"
  user_data = replace(file("${path.module}/wireguard.sh"), "$CLIENT_PUBLIC_KEY", var.client_public_key)

  monitoring = true

  tags = {
    Project = "${var.project}"
  }
}

module "vpn_sg" {
  source = "terraform-aws-modules/security-group/aws"

  name        = "${var.project}-sg"
  description = "VPN SG"

  egress_rules = ["all-all"]
}

resource "aws_vpc_security_group_ingress_rule" "vpn_ingress" {
  for_each = toset(var.whitelisted_ips)

  description       = "Restrict access to only whitelisted IPs"
  security_group_id = module.vpn_sg.security_group_id
  cidr_ipv4         = "${each.value}/32"
  ip_protocol       = "-1"
}

resource "aws_key_pair" "ec2_ssh_key" {
  key_name   = var.ssh_key_name
  public_key = file("~/.ssh/${var.ssh_key_name}.pub")
}
