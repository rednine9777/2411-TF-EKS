terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-northeast-2"
}

# 최신 Ubuntu 22.04 LTS AMI 조회
data "aws_ami" "ubuntu_22_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical (Ubuntu 공식 계정)
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# 최신 Amazon Linux 2 AMI 조회
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"] # Amazon 공식 계정
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 변수 선언
variable "key_name" {
  description = "EC2 인스턴스에 사용할 키 페어 이름"
  type        = string
}

variable "security_group_ids" {
  description = "EC2 인스턴스에 적용할 보안 그룹 ID 목록"
  type        = list(string)
}

variable "nodes" {
  type = map(object({
    name = string
    type = string
    size = number
  }))
  default = {
    "k8smaster" = {
      name = "k8smaster"
      type = "t3.medium"
      size = 20
    }
    # "k8sworker1" = {
    #   name = "k8sworker1"
    #   type = "t3.xlarge"
    #   size = 40
    # },
    # "k8sworker2" = {
    #   name = "k8sworker2"
    #   type = "t3.xlarge"
    #   size = 40
    # }
  }
}

resource "aws_instance" "instances" {
  for_each = var.nodes

  availability_zone = "ap-northeast-2a"
  # ami                    = data.aws_ami.ubuntu_22_04.id # 최신 Ubuntu 22.04 LTS AMI ID를 사용
  ami                    = data.aws_ami.amazon_linux_2.id # Amazon Linux 2 AMI ID 사용
  instance_type          = each.value.type
  key_name               = var.key_name
  user_data              = file("./user-data/node-install.sh")
  vpc_security_group_ids = var.security_group_ids

  # 스팟 인스턴스 설정 추가
  instance_market_options {
    market_type = "spot"
    spot_options {
      max_price                      = "0.08"
      spot_instance_type             = "one-time"
      instance_interruption_behavior = "terminate"
    }
  }

  root_block_device {
    volume_type = "gp3"
    volume_size = 20 # GiB
  }

  tags = {
    Name     = each.value.name
    provider = "terraform"
  }
}

resource "aws_ebs_volume" "volumes" {
  for_each = var.nodes

  availability_zone = "ap-northeast-2a"
  size              = each.value.size
  type              = "gp3"

  tags = {
    Name     = "${each.value.name}-vol"
    provider = "terraform"
  }
}

resource "aws_volume_attachment" "attachments" {
  for_each = var.nodes

  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.volumes[each.key].id
  instance_id = aws_instance.instances[each.key].id
}

resource "aws_eip" "master_ip" {
  instance = aws_instance.instances["k8smaster"].id
  domain   = "vpc"

  tags = {
    Name     = "k8smaster_ip"
    provider = "terraform"
  }
}
