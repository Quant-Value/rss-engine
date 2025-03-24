
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
  depends_on=[module.sw_server,aws_secretsmanager_secret_version.rss_engine_imatia_version]

}


module "elastic" {
  source = "../modules/elastic_search"
  aws_region=var.aws_region
  vpc_id=var.vpc_id
  private_key_path=var.private_key_path
  public_key_path=var.public_key_path
  environment=var.environment
  amount= 3
  sg_sw_worker=module.sw_server.sg_id_server #same sg as workers
  depends_on=[module.sw_workers]

}

