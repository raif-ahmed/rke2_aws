locals {

}

data "aws_region" "current" {}

data "template_file" "dev_hosts" {
  template = "${file("${path.module}/templates/dev_hosts.cfg")}"
  depends_on = [
    "aws_instance.dev-api-gateway",
    "aws_instance.dev-api-gateway-internal",
    
  ]
  vars {
    api_public = "${aws_instance.dev-api-gateway.private_ip}"
    api_internal = "${aws_instance.dev-api-gateway-internal.private_ip}"
  }
}

resource "null_resource" "dev-hosts" {
  triggers {
    template_rendered = "${data.template_file.dev_hosts.rendered}"
  }
  provisioner "local-exec" {
    command = "echo '${data.template_file.dev_hosts.rendered}' > dev_hosts"
  }
}


