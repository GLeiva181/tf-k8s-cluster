resource "local_file" "inventory" {
  content = <<-EOT
  [control_plane]
  control_plane ansible_host=${aws_instance.control_plane.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../kp/kp-gleiva-ohio.pem

  [worker]
  worker ansible_host=${aws_instance.worker.public_ip} ansible_user=ubuntu ansible_ssh_private_key_file=../kp/kp-gleiva-ohio.pem
  EOT

  filename = "${path.module}/hosts.ini"
}