data "template_file" "k8s-master-node-bootstrap" {
  template = file(format("%s/scripts/k8s-master-node-bootstrap.tpl", path.module))
  vars = {
    LB_DNS = aws_lb.lb.dns_name

    #updating rds instance / database with the new load balancer dns from terraform output
    rds_mysql_ept = local.db_creds.rds_ept #var.rds_ept
    rds_mysql_usr = local.db_creds.rds_usr #var.rds_usr
    rds_mysql_pwd = local.db_creds.rds_pwd #var.rds_pwd
    rds_mysql_db  = local.db_creds.rds_db  #var.rds_db
  }
}

data "template_file" "k8s-worker-node-bootstrap" {
  template = file(format("%s/scripts/k8s-worker-node-bootstrap.tpl", path.module))
  vars = {
    LB_DNS = aws_lb.lb.dns_name
  }
}

data "template_file" "bastion_s3_cp_bootstrap" {
  template = file(format("%s/scripts/bastion_s3_key_copy.tpl", path.module))
  vars = {
    s3_bucket = local.db_creds.s3_bucket
    pem_key   = "private-key-kp.pem"
  }
}

