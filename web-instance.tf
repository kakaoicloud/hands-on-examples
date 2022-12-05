resource "openstack_compute_instance_v2" "web_instance" {
  count = length(var.web_nodes)

  name = "${var.prefix}-${var.web_nodes[count.index]}"
  flavor_name = var.web_flavor
  key_pair = data.openstack_compute_keypair_v2.sshkey.id
  user_data   = data.template_file.web_init_sh.rendered

  block_device {
    uuid                  = data.openstack_images_image_v2.default_image.id
    source_type           = "image"
    volume_size           = 50
    boot_index            = 0
    destination_type      = "volume"
    delete_on_termination = true
  }
  
  network {
    port = openstack_networking_port_v2.web_port[count.index].id
  }

}

###### scripts ######

data "template_file" "web_init_sh" {
  template = "${file("scripts/web-init.sh")}"
  vars = {
    "endpoint" = "${openstack_networking_floatingip_v2.web_fip.address}"
    "app_lb_ip" = "${openstack_lb_loadbalancer_v2.app_lb.vip_address}"
  }
}


###### port ######

resource "openstack_networking_port_v2" "web_port" {
  count = length(var.web_nodes)
  name = "${var.prefix}-${var.web_nodes[count.index]}"
  network_id = data.openstack_networking_network_v2.public_network.id
  admin_state_up = true
  security_group_ids = [openstack_networking_secgroup_v2.web_sg.id]

  allowed_address_pairs {
    ip_address = openstack_lb_loadbalancer_v2.web_lb.vip_address
  }
}

###### security-group/rules ######

resource "openstack_networking_secgroup_v2" "web_sg" {
    name = "${var.prefix}-web-sg"
    description = "security group for ${var.prefix}-webs"
}

resource "openstack_networking_secgroup_rule_v2" "web-sg-public" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = data.openstack_networking_subnet_v2.public_subnet.cidr
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}

resource "openstack_networking_secgroup_rule_v2" "web-ssh-sg-rule" {
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "${openstack_networking_port_v2.bastion_port.all_fixed_ips.0}/32"
  security_group_id = openstack_networking_secgroup_v2.web_sg.id
}