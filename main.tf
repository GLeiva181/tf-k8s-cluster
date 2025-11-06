resource "aws_security_group" "allow_all" {
  name        = "allow_all_traffic"
  description = "Permite todo el trafico entrante y saliente"

  vpc_id = "vpc-090efc56d33e73285" # Reemplaza con el ID de tu VPC

  # Regla para permitir todo el tráfico entrante
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 significa "todos los protocolos"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Regla para permitir todo el tráfico saliente
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_all"
  }
}

resource "aws_instance" "control_plane" {
  ami           = "ami-04f167a56786e4b09"  # Reemplaza con una AMI de Ubuntu válida
  instance_type = "t2.medium"
  key_name      = "kp-gleiva-ohio"  # Reemplaza con tu clave SSH
  subnet_id     = "subnet-0ab554fb814616587"
  security_groups = [aws_security_group.allow_all.id]

  tags = {
    Name = "k8s-control-plane"
  }
}

resource "aws_instance" "worker" {
  ami           = "ami-04f167a56786e4b09"  # Reemplaza con una AMI de Ubuntu válida
  instance_type = "t2.medium"
  key_name      = "kp-gleiva-ohio"  # Reemplaza con tu clave SSH
  subnet_id     = "subnet-0ab554fb814616587"
  security_groups = [aws_security_group.allow_all.id]

  root_block_device {
    volume_size = 20  # Tamaño del disco en GB
    volume_type = "gp3"  # Puedes usar gp2 o gp3 (gp3 tiene mejor rendimiento y menor costo)
    delete_on_termination = true  # Borra el volumen cuando se elimina la instancia
  }

  tags = {
    Name = "k8s-worker"
  }
}

output "control_plane_ip" {
  value = aws_instance.control_plane.public_ip
}

output "worker_ip" {
  value = aws_instance.worker.public_ip
}

resource "null_resource" "provision_k8s" {
  depends_on = [aws_instance.control_plane, aws_instance.worker]

  provisioner "local-exec" {
    command = "RETRY_INTERVAL=30; ATTEMPTS=5; COUNT=0; while [ $COUNT -lt $ATTEMPTS ]; do ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ${local_file.inventory.filename} setup_k8s.yml -v && exit 0; COUNT=$((COUNT+1)); echo \"Retrying in $RETRY_INTERVAL seconds... (Attempt $COUNT of $ATTEMPTS)\"; sleep $RETRY_INTERVAL; done; echo \"Ansible playbook failed after $ATTEMPTS attempts\"; exit 1"
  }
}

