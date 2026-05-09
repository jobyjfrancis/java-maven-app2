variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
}

# variable "my_ip" {
#   description = "Public IP address allowed to SSH into the instance"
#   type        = string
# }

variable "key_pair_name" {
  description = "Existing EC2 key pair name to use for SSH access"
  type        = string
}

data "aws_ami" "ubuntu" {
  most_recent = true

  owners = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_security_group" "ssh_access" {
  name        = "allow-ssh-from-my-ip"
  description = "Allow SSH access from configured IP"

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ubuntu_docker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.micro"
  key_name               = var.key_pair_name
  vpc_security_group_ids = [aws_security_group.ssh_access.id]

  user_data = <<-EOF
                #!/bin/bash
                apt-get update
                apt-get install -y docker.io
                systemctl enable docker
                systemctl start docker
                sudo usermod -aG docker ubuntu
                EOF

  tags = {
    Name = "ubuntu-docker-instance"
  }
}

resource "local_file" "ec2_public_ip" {
  filename   = "ec2_public_ip"
  content    = aws_instance.ubuntu_docker.public_ip
  depends_on = [aws_instance.ubuntu_docker]
}
