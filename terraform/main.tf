
module "sw_server" {
  source = "../modules/sw_server"
  vpc_id=var.vpc_id
  aws_region=var.aws_region
  private_key_path=var.private_key_path
  public_key_path=var.public_key_path
  environment=var.environment
}

module "sw_workers" {
  source = "../modules/sw_worker"
  sg_group_server=module.sw_server.sg_id_server
  dns_name_server=module.sw_server.dns_name_server
  aws_region=var.aws_region
  vpc_id=var.vpc_id
  private_key_path=var.private_key_path
  public_key_path=var.public_key_path
  environment=var.environment
  amount= 3
  depends_on=[module.sw_server]

}

