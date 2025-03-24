
module "sw_server" {
  source = "../modules/sw_server"

  vpc_id=var.vpc_id
  aws_region=var.aws_region
  private_key_path=var.private_key_path
  public_key_path=var.public_key_path
  environment=var.environment

  subnet_ids=data.aws_subnets.public_subnets.ids
  hosted_zone_arn=data.aws_route53_zone.my_hosted_zone.arn
  hosted_zone_id=data.aws_route53_zone.my_hosted_zone.id
  aws_secret_arn=data.aws_secretsmanager_secret.my_secret.arn
  ami_id=data.aws_ami.ubuntu_latest.id
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
  subnet_ids=data.aws_subnets.public_subnets.ids

  amount= 3

  num_availability_zones=local.num_availability_zones

  hosted_zone_arn=data.aws_route53_zone.my_hosted_zone.arn
  hosted_zone_id=data.aws_route53_zone.my_hosted_zone.id
  aws_secret_arn=data.aws_secretsmanager_secret.my_secret.arn
  ami_id=data.aws_ami.ubuntu_latest.id

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

  num_availability_zones=local.num_availability_zones

  hosted_zone_arn=data.aws_route53_zone.my_hosted_zone.arn
  hosted_zone_id=data.aws_route53_zone.my_hosted_zone.id
  aws_secret_arn=data.aws_secretsmanager_secret.my_secret.arn
  ami_id=data.aws_ami.ubuntu_latest.id
  subnet_ids=data.aws_subnets.public_subnets.ids

  efs_id=aws_efs_file_system.this.id
  sg_default_id=data.aws_security_group.default.id

  
  depends_on=[module.sw_workers]

}

module "prometheus" {
  source = "../modules/prometheus_opentelemetry"
  vpc_id=var.vpc_id
  private_key_path=var.private_key_path
  public_key_path=var.public_key_path
  environment=var.environment
  sg_wk=module.sw_server.sg_id_server #same sg as workers
  hosted_zone_arn=data.aws_route53_zone.my_hosted_zone.arn
  hosted_zone_id=data.aws_route53_zone.my_hosted_zone.id
  ami_id=data.aws_ami.ubuntu_latest.id
  subnet_ids=data.aws_subnets.public_subnets.ids
  efs_id=aws_efs_file_system.this.id
  sg_default_id=data.aws_security_group.default.id
  depends_on=[module.sw_workers]
}

