#
# Cookbook Name:: scalr
# Recipe:: mount_ebs
#
# Copyright 2011, 40 North LLC
#
# All rights reserved - Do Not Redistribute
#

include_recipe "aws"

aws_ebs_volume "db_ebs_volume" do
  provider "aws_ebs_volume"
  aws_access_key node[:access_key]
  aws_secret_access_key node[:secret_key]
  device node[:ebs_dev_id]
  volume_id node[:ebs_vol_id]
  action [:attach ]
end

