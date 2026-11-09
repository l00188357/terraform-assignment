resource "aws_instance" "app" {
  ami                    = "ami-0c1c30571d2dae5c9" # fixed AMI ID (no data lookup, plan-only)
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.app.id]

  # IMDSv2 mandatory
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required" # IMDSv2 mandatory (assignment: infrastructure security)
  }

  # Encrypted root volume
  root_block_device {
    volume_size = 8
    volume_type = "gp3"
    encrypted   = true
  }

  tags = {
    Name         = "sovereign-app"
    Organisation = "ATUL0012345" # Organisation ID as specified in the assignment brief
  }
}

resource "aws_ebs_volume" "data" {
  availability_zone = "${var.aws_region}a"
  size              = 10
  type              = "gp3"
  encrypted         = true

  tags = {
    Name         = "sovereign-data"
    DataClass    = "sensitive"
    Organisation = "ATUL0012345"
  }
}

resource "aws_volume_attachment" "data" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.data.id
  instance_id = aws_instance.app.id
}