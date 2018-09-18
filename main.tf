resource "hcloud_ssh_key" "nixos-terraform" {
	name = "Terraform public key"
	public_key = "${file("${var.ssh_pubkey}")}"
}

resource "null_resource" "prepare-installer" {
	provisioner "local-exec" {
		command = "nix-build default.nix -A installer"
	}
}

resource "hcloud_server" "node1" {
	name = "node1"
	image = "debian-9"
	server_type = "cx11"
	ssh_keys = ["${hcloud_ssh_key.nixos-terraform.id}"]

	depends_on = [
		"null_resource.prepare-installer",
		"hcloud_ssh_key.nixos-terraform",
	]

	connection {
		type = "ssh"
		user = "root"
		private_key = "${file("${var.ssh_privkey}")}"
	}

	provisioner file {
		source      = "./result/bzImage"
		destination = "/root/bzImage"
	}

	provisioner file {
    source      = "./result/initrd.gz"
		destination = "/root/initrd.gz"
	}

	provisioner file {
		source      = "./result/kexec-installer"
		destination = "/root/kexec-installer"
	}

	provisioner "remote-exec" {
		inline = [
			"apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -qy kexec-tools",
			"chmod +x /root/kexec-installer",
			"wall kexec-ing into nixos installer",
			"/root/kexec-installer",
		]
	}
}



