resource "openstack_compute_instance_v2" "app_instance" {
  count = length(var.app_nodes)

  name = "${var.prefix}-${var.app_nodes[count.index]}"
  flavor_name = var.app_flavor
  key_pair = data.openstack_compute_keypair_v2.sshkey.id
  user_data   = file("scripts/app-init.sh")

  block_device {
    uuid                  = data.openstack_images_image_v2.default_image.id
    source_type           = "image"
    volume_size           = 50
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  
  network {
    port = openstack_networking_port_v2.app_port[count.index].id
  }

}


###### port ######

resource "openstack_networking_port_v2" "app_port" {
  count = length(var.app_nodes)
  name = "${var.prefix}-${var.app_nodes[count.index]}"
  network_id = data.openstack_networking_network_v2.public_network.id
  admin_state_up = true
  security_group_ids = [openstack_networking_secgroup_v2.app_sg.id]

  allowed_address_pairs {
    ip_address = openstack_lb_loadbalancer_v2.app_lb.vip_address
  }
}

###### security-group/rules ######

resource "openstack_networking_secgroup_v2" "app_sg" {
    name = "${var.prefix}-app-sg"
    description = "security group for ${var.prefix}-apps"
}

resource "openstack_networking_secgroup_rule_v2" "app-sg-public" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = data.openstack_networking_subnet_v2.public_subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.app_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "app-ssh-sg-rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "${openstack_networking_port_v2.bastion_port.all_fixed_ips.0}/32"
  security_group_id = openstack_networking_secgroup_v2.app_sg.id
}