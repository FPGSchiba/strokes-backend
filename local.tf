locals {
  data = jsondecode(file("${path.module}/files/data.json"))
}