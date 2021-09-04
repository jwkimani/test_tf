terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
    curl = {
      source  = "anschoewe/curl"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

# resource "aws_key_pair" "deployer" {
#   key_name   = "Talend_Remote_Engine_KeyPair"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCMaQfQovkF1TZl2TBzyBoSmpIijge3oo2Pn/6jg3BM+8xvCJ62F0jHxk1sb7B+p8cRDpp131upaxs+dGBVTmr8OHblk8fjvMlsHuOT9ejBNsquDKeLCl3a/VSLZ44ejV+cKuzThp0MCRA/J+ivmfbkMtMF2Cbs5vu6ngw3KPRB5RFIrliwRcJVwWvFd8bFqr8ePsoiZBskm5xdnE227pf+LedYWaGwHRdgXiy251TbyqEv9uABwumj44o6er3bkLiPcCz3jSjYsGJJx+p6HDBh4u0kDpzfkoTV3cH5v3nNYUGLxInINGsKWfzmt82cHt9Zhf+YoiJkSU4G4WOHSOP/"
# }

data "aws_secretsmanager_secret" "secrets" { ## $ rates=> 	$0.40 per secret per month + $0.05 per 10,000 API calls
  arn = "arn:aws:secretsmanager:us-east-1:152338276817:secret:dev/talend/pairing-key/re1-oDNiDo"
}
data "aws_secretsmanager_secret_version" "current" {
  secret_id = data.aws_secretsmanager_secret.secrets.id
}


data "http" "remoteEngineDetails" {
  url = "https://api.us.cloud.talend.com/tmc/v2.5/runtimes/remote-engines/611180651c51be57b4738243"

  # Optional request headers
  request_headers = {
    Accept = "application/json"
    Authorization = "Bearer 8U79FHobS9WE6XpmLxpKyPIf0F3PdEGf51DFIzF2NZH8PTcRBPmuqicuMFo1yx-o"
  }
}
locals {
  json_data = jsondecode(data.http.remoteEngineDetails.body)
}
resource "aws_instance" "talend_re" {
  ami           = "ami-05f489c5d63e4234f"
  instance_type = "t2.small"   ## For Testing => 	$0.023 per hour
  # instance_type = "t2.medium" ## VENDOR RECOMMENDED TO CONNECT TO TMC => 	$0.046 per hour
  security_groups=["Talend Cloud Remote Engine for AWS-2-10-4-AutogenByAWSMP-"]
  key_name = "Talend_Remote_Engine_KeyPair"
  # user_data="pairing.service.url=https://pair.us.cloud.talend.com\nremote.engine.pre.authorized.key=${data.aws_secretsmanager_secret_version.current.secret_string}"
  # user_data="pairing.service.url=https://pair.us.cloud.talend.com\nremote.engine.pre.authorized.key=${local.json_data.preAuthorizedKey}"
  user_data=<<EOF
#!/bin/bash

set -x

yum install python3 pip3 jq -y
yum -y install git
yum -y install unzip

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip
sudo ./aws/install -b /usr/bin

sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
sudo systemctl enable amazon-ssm-agent
sudo systemctl start amazon-ssm-agent
sudo yum -y install java-1.8.0-openjdk-devel

curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo python3 get-pip.py

sudo /usr/local/bin/pip3 install requests
sudo /usr/local/bin/pip3 install pytrends
sudo /usr/local/bin/pip3 install s3fs # may have had issue
sudo /usr/local/bin/pip3 install pandas_profiling
sudo /usr/local/bin/pip3 install boto3 # may have had issue
sudo /usr/local/bin/pip3 install pyyaml
sudo /usr/local/bin/pip3 install fsspec

export TALEND_INSTALL_DIR=/opt/talend/ipaas/remote-engine-client/etc

touch $${TALEND_INSTALL_DIR}/org.apache.cxf.http.conduits-common.cfg
chown ec2-user:ec2-user $${TALEND_INSTALL_DIR}/org.apache.cxf.http.conduits-common.cfg
sudo echo "client.ConnectionTimeout = 0" >> $${TALEND_INSTALL_DIR}/org.apache.cxf.http.conduits-common.cfg
sudo echo "client.ReceiveTimeout = 0" >> $${TALEND_INSTALL_DIR}/org.apache.cxf.http.conduits-common.cfg


sudo sed -i "s|remote.engine.pre.authorized.key =.*|remote.engine.pre.authorized.key = ${local.json_data.preAuthorizedKey}|g" $${TALEND_INSTALL_DIR}/preauthorized.key.cfg
sudo sed -i "s|remote.engine.name.*=.*|remote.engine.name = eon-automated-engine-${var.re_number}|g" $${TALEND_INSTALL_DIR}/preauthorized.key.cfg
sudo sed -i "s|pairing.service.url.*=.*|pairing.service.url = ${var.location_url["${var.location}"]}|g" $${TALEND_INSTALL_DIR}/org.talend.ipaas.rt.pairing.client.cfg
sudo sed -i "s|max.deployed.flows.*=.*|max.deployed.flows = 0|g" $${TALEND_INSTALL_DIR}/org.talend.ipaas.rt.deployment.agent.cfg
sudo sed -i "s|org.talend.remote.server.MultiSocketServer.SERVER_SOCKET_LIFETIME.*=.*|org.talend.remote.server.MultiSocketServer.SERVER_SOCKET_LIFETIME = 0|g" $${TALEND_INSTALL_DIR}/org.talend.remote.jobserver.server.cfg

/opt/talend/ipaas/remote-engine-client/bin/stop

sudo tar -C /tmp/ -xvzf /tmp/sqljdbc_6.4.0.0_enu.tar.gz
sudo cp /tmp/sqljdbc_6.4/enu/mssql-jdbc-6.4.0.jre8.jar /usr/lib/sqoop/lib/

EOF
  tags = {
    Name = var.instance_name
    Created_By = "EON Terraform"
    Purpose = "SBDInstance with ARUN - must be torn down at end of SBD project"
    customer = var.organization
    # PreAuthKey = local.json_data.preAuthorizedKey
  }
}