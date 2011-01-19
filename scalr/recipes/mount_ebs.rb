#
# Cookbook Name:: scalr
# Recipe:: mount_ebs
#
# Copyright 2011, 40 North LLC
#
# All rights reserved - Do Not Redistribute
#
include_recipe "aws"

package "xfsprogs" do
  case node[:platform]
  when "centos","redhat","fedora","suse"
    package_name "xfsprogs"
  when "debian","ubuntu"
    package_name "xfsprogs"
  end
  action :install
end



directory "#{node[:ebs_mnt_pt]}" do
  action :create
  mode 0775
  owner "ubuntu"
  group "ubuntu"
   not_if {File.exists?("#{node[:ebs_mnt_pt]}") }
end

directory "/var/lib/mysql" do
  action :create
  mode 0775
  owner "ubuntu"
  group "ubuntu"
   not_if {File.exists?("/var/lib/mysql") }
end


mount node[:ebs_mnt_pt] do
  device node[:ebs_vol_part]
  fstype node[:ebs_fs_type]
    options "rw"
  not_if {File.exists?("#{node[:ebs_mnt_pt]}/mysql") }
end

mount "/var/lib/mysql" do
    device node[:ebs_mnt_pt]
    options "bind, rw"
    not_if {File.exists?("/var/lib/mysql/mysql") }
end
