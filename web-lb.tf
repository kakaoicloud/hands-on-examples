resource "openstack_lb_loadbalancer_v2" "web_lb" {
    name = "${var.prefix}-${var.web_instance_name}-lb"
    vip_network_id = data.openstack_networking_network_v2.public_network.id
}

###### lb-component ######

resource "openstack_lb_pool_v2" "web_lb_pool" {
    name = "${var.prefix}-webs"
    lb_method = "ROUND_ROBIN"
    protocol = "HTTP"
    loadbalancer_id = openstack_lb_loadbalancer_v2.web_lb.id
}

resource "openstack_lb_member_v2" "web_lb_member" {
    count = length(openstack_networking_port_v2.web_port.*.all_fixed_ips.0)
    name = var.web_nodes[count.index]
    address = element(openstack_networking_port_v2.web_port.*.all_fixed_ips.0, count.index)
    pool_id = openstack_lb_pool_v2.web_lb_pool.id
    protocol_port = 80
    subnet_id = data.openstack_networking_subnet_v2.public_subnet.id
}

resource "openstack_lb_monitor_v2" "web_lb_monitor" {
    pool_id = openstack_lb_pool_v2.web_lb_pool.id
    name = "${var.prefix}-web-monitor"
    type = "HTTP"
    delay = 10
    max_retries = 3
    timeout = 5
    url_path = "/"
}

resource "openstack_lb_listener_v2" "web_lb_listener" {
    default_pool_id = openstack_lb_pool_v2.web_lb_pool.id
    loadbalancer_id = openstack_lb_loadbalancer_v2.web_lb.id
    protocol        = "HTTP"
    protocol_port   = 80
}

###### fip ######

resource "openstack_networking_floatingip_associate_v2" "web_fip_associate" {
  floating_ip = openstack_networking_floatingip_v2.web_fip.address
  port_id     = openstack_lb_loadbalancer_v2.web_lb.vip_port_id
}


resource "openstack_networking_floatingip_v2" "web_fip" {
  pool = data.openstack_networking_network_v2.floating_network.name
  port_id = openstack_lb_loadbalancer_v2.web_lb.vip_port_id
}