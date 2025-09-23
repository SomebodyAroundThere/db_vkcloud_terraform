variable "db-instance-flavor" {
  type    = string
  default = "STD2-2-8"
}

variable "db_user_password" {
  type      = string
  sensitive = true
}

data "vkcs_compute_flavor" "db" {
  name = var.db-instance-flavor
}
# Блок создания группы безопасности
resource "vkcs_networking_secgroup" "secgroup_test" {
  name        = "Sokolova_secgroup"
  description = "My security group"
}
# Блок создания правила для группы безопасности
resource "vkcs_networking_secgroup_rule" "secgroup_rule_test" {
  direction         = "ingress"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = "${vkcs_networking_secgroup.secgroup_test.id}"
}

resource "vkcs_networking_network" "db" {
  name           = "Sokolova_network"
  admin_state_up = true
}

resource "vkcs_networking_subnet" "db-subnetwork" {
  name            = "Sokolova_subnet"
  network_id      = vkcs_networking_network.db.id
  cidr            = "10.110.0.0/16"
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

data "vkcs_networking_network" "extnet" {
  name = "internet"
}

resource "vkcs_networking_router" "db-router" {
  name                = "Sokolova_router"
  admin_state_up      = true
  external_network_id = data.vkcs_networking_network.extnet.id
}

resource "vkcs_networking_router_interface" "db" {
  router_id = vkcs_networking_router.db-router.id
  subnet_id = vkcs_networking_subnet.db-subnetwork.id
}

resource "vkcs_compute_keypair" "ssh" {
  # Название SSH-ключа. Ключ будет отображаться в настройках аккаунта на вкладке *Ключевые пары*
  name = "terraform_ssh_key"
  # Путь до открытого ключа
  public_key = file("${path.module}/id_rsa.pub")

}

resource "vkcs_db_instance" "db-instance" {
  name        = "Sokolova_db_MYSQL8"
  keypair = "${vkcs_compute_keypair.ssh.name}"
  datastore {
    type    = "mysql"
    version = "8.0"
  }
  floating_ip_enabled = true
  flavor_id   = data.vkcs_compute_flavor.db.id
  size        = 8
  volume_type = "ceph-ssd"
  disk_autoexpand {
    autoexpand    = true
    max_disk_size = 1000
  }
  network {
    uuid = vkcs_networking_network.db.id
    security_groups = [vkcs_networking_secgroup.secgroup_test.id]
  }
}

resource "vkcs_db_database" "db-database" {
  name        = "testdb-Sokolova"
  dbms_id = vkcs_db_instance.db-instance.id
  charset     = "utf8"
}
resource "vkcs_db_user" "db-user" {
  name        = "testuser"
  password    = var.db_user_password
  dbms_id = vkcs_db_instance.db-instance.id
  databases   = [vkcs_db_database.db-database.name]
}

data "vkcs_compute_flavor" "compute" {
  name = var.compute_flavor
}

data "vkcs_images_image" "compute" {
  visibility = "public"
  default    = true
  properties = {
    mcs_os_distro  = "ubuntu"
    mcs_os_version = "22.04"
  }
}

resource "vkcs_compute_instance" "compute" {
  name                    = "Sokolova-ubuntu"
  flavor_id               = data.vkcs_compute_flavor.compute.id
  key_pair                = var.key_pair_name
  security_group_ids      = [vkcs_networking_secgroup.secgroup_test.id]
  availability_zone       = var.availability_zone_name

  block_device {
    uuid                  = data.vkcs_images_image.compute.id
    source_type           = "image"
    destination_type      = "volume"
    volume_type           = "ceph-ssd"
    volume_size           = 10
    boot_index            = 0
    delete_on_termination = true
  }

  network {
    uuid = vkcs_networking_network.db.id
  }

  depends_on = [
    vkcs_networking_network.db,
    vkcs_networking_subnet.db-subnetwork
  ]
}

resource "vkcs_networking_floatingip" "fip" {
  pool = data.vkcs_networking_network.extnet.name
}

resource "vkcs_compute_floatingip_associate" "fip" {
  floating_ip = vkcs_networking_floatingip.fip.address
  instance_id = vkcs_compute_instance.compute.id
}

output "instance_fip" {
  value = vkcs_networking_floatingip.fip.address
}
