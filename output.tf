output "steam-init" {
  value = data.template_file.bastion_init_sh.rendered
}