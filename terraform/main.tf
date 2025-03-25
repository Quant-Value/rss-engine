
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
  aws_secret_arn=aws_secretsmanager_secret.rss_engine_imatia.arn
  ami_id=data.aws_ami.ubuntu_latest.id

  aws_key_name=aws_key_pair.key_ec2.key_name
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
  aws_secret_arn=aws_secretsmanager_secret.rss_engine_imatia.arn
  ami_id=data.aws_ami.ubuntu_latest.id

  aws_key_name=aws_key_pair.key_ec2.key_name

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
  aws_secret_arn=aws_secretsmanager_secret.rss_engine_imatia.arn
  ami_id=data.aws_ami.ubuntu_latest.id
  subnet_ids=data.aws_subnets.private_subnets.ids

  efs_dns_name=aws_efs_file_system.this.dns_name
  sg_default_id=data.aws_security_group.default.id
  sg_grafana=module.grafana.sg_id
  sg_otel=module.prometheus.i3_sg_id

  aws_key_name=aws_key_pair.key_ec2.key_name

  
  depends_on=[module.sw_workers,module.prometheus,module.grafana,aws_efs_mount_target.this]

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
  subnet_ids=data.aws_subnets.private_subnets.ids
  efs_id=aws_efs_file_system.this.dns_name
  sg_default_id=data.aws_security_group.default.id
  sg_grafana=module.grafana.sg_id

  aws_key_name=aws_key_pair.key_ec2.key_name

  depends_on=[module.sw_workers,aws_efs_mount_target.this]
}

module "grafana" {
  source = "../modules/grafana_frontend"
  
  vpc_id = var.vpc_id
  public_key_path= var.public_key_path

  amount= 3

  ami_id = data.aws_ami.ubuntu_latest.id
  subnet_ids = data.aws_subnets.public_subnets.ids
  hosted_zone = data.aws_route53_zone.my_hosted_zone.id
  num_availability_zones = local.num_availability_zones
  hosted_zone_arn = data.aws_route53_zone.my_hosted_zone.arn
  hosted_zone_id = data.aws_route53_zone.my_hosted_zone.id
  environment = var.environment
  aws_secret_arn = aws_secretsmanager_secret.rss_engine_imatia.arn
  depends_on=[aws_efs_mount_target.this]
  sg_default_id=data.aws_security_group.default.id
  efs_id=aws_efs_file_system.this.dns_name

  aws_key_name=aws_key_pair.key_ec2.key_name
}
