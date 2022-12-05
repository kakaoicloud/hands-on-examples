resource "openstack_compute_instance_v2" "bastion_instance" {
  name = "${var.prefix}-${var.bastion_instance_name}"
  flavor_name = var.bastion_flavor
  key_pair = data.openstack_compute_keypair_v2.sshkey.id
  user_data = data.template_file.bastion_init_sh.rendered

  block_device {
    uuid                  = data.openstack_images_image_v2.default_image.id
    source_type           = "image"
    volume_size           = 50
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  
  network {
    port = openstack_networking_port_v2.bastion_port.id
  }

}

###### scripts ######

data "template_file" "bastion_init_sh" {
  template = file("./scripts/bastion-init.sh")
  vars = {
    "web1" = openstack_networking_port_v2.web_port[0].all_fixed_ips.0
    "web2" = openstack_networking_port_v2.web_port[1].all_fixed_ips.0
    "app1" = openstack_networking_port_v2.app_port[0].all_fixed_ips.0
    "app2" = openstack_networking_port_v2.app_port[1].all_fixed_ips.0
  }
}

###### port ######

resource "openstack_networking_port_v2" "bastion_port" {
  name = "${var.prefix}-${var.bastion_instance_name}"
  network_id = data.openstack_networking_network_v2.public_network.id
  admin_state_up = true
  security_group_ids = [openstack_networking_secgroup_v2.bastion_sg.id]

  allowed_address_pairs {
    ip_address = openstack_lb_loadbalancer_v2.app_lb.vip_address
  }
}

###### security-group/rules ######

resource "openstack_networking_secgroup_v2" "bastion_sg" {
    name = "${var.prefix}-bastion-sg"
    description = "security group for ${var.prefix}-${var.bastion_instance_name}"
}

resource "openstack_networking_secgroup_rule_v2" "bastion-ssh-sg-rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "bastion-nginx-sg-rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 81
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "bastion-tunnel-sg-rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 10000
  port_range_max    = 10100
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = openstack_networking_secgroup_v2.bastion_sg.id
}

###### fip ######

resource "openstack_networking_floatingip_associate_v2" "bastion_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.bastion_fip.address
  port_id     = openstack_networking_port_v2.bastion_port.id
}


resource "openstack_networking_floatingip_v2" "bastion_fip" {
  pool = data.openstack_networking_network_v2.floating_network.name
  port_id = openstack_networking_port_v2.bastion_port.id
}