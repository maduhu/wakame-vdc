# -*- coding: utf-8 -*-

require 'rbvmomi'

module Dcmgr
  module Drivers
    class ESXiLocalStore < LocalStore
      include Dcmgr::Logger
      include Dcmgr::Helpers::CliHelper
      include RbVmomi

      def deploy_image(inst,ctx)
        #TODO: check if the file exists yet
        inst_uuid = inst[:uuid]
        
        # ESXi images have a *.vmdk file containing metadata
        # and a *-flat.vmdk file which contains the disk itself.
        # We need to copy both.
        inst_img_flat  = inst[:image][:source][:uri]
        #TODO: make sure we only delete the last occurence of "-flat" in the filename
        inst_img_meta = inst_img_flat.gsub("-flat","")
        
        
        # Collect the esxi data
        esxi_options = {
          :host => ctx.node.manifest.config.esxi_ipaddress,
          :user => ctx.node.manifest.config.esxi_username,
          :password => ctx.node.manifest.config.esxi_password,
          :insecure => true,
          :datastore => ctx.node.manifest.config.esxi_datastore,
          :datacenter => ctx.node.manifest.config.esxi_datacenter,
        }
        
        logger.debug("Creating ESXI vm: #{inst_uuid}")
        create_vm(inst,esxi_options)
        
        # Copy the image to the ESXi server
        
        logger.debug("Copying file: #{inst_img_flat}")
        sh("curl -s -o - #{inst_img_flat} | curl -s -u #{esxi_options[:user]}:#{esxi_options[:password]} -k -T - https://#{esxi_options[:host]}/folder/#{inst_uuid}/#{inst_img_flat.split("/").last}?dsName=#{esxi_options[:datastore]}")
        logger.debug("Copying file: #{inst_img_meta}")
        sh("curl -s -o - #{inst_img_meta} | curl -s -u #{esxi_options[:user]}:#{esxi_options[:password]} -k -T - https://#{esxi_options[:host]}/folder/#{inst_uuid}/#{inst_uuid}.vmdk?dsName=#{esxi_options[:datastore]}")
      end
      
      private
      # Creates a vm on the ESXi server
      def create_vm(inst,opts)
        vim = VIM.connect opts
        dc = vim.serviceInstance.find_datacenter(opts[:datacenter]) or raise "datacenter not found"
        vmFolder = dc.vmFolder
        hosts = dc.hostFolder.children
        rp = hosts.first.resourcePool
        
        vm_cfg = {
          :name => inst[:uuid],
          :guestId => 'otherGuest',
          :files => { :vmPathName => "[#{opts[:datastore]}]" },
          :numCPUs => inst[:cpu_cores],
          :memoryMB => inst[:memory_size],
          :deviceChange => [
            
          ]
        }
        
        # Add vnics
        vifs = inst[:vif]
        if !vifs.empty?
          vifs.sort {|a, b|  a[:device_index] <=> b[:device_index] }.each { |vif|
            vm_cfg[:deviceChange] << {
              :operation => :add,
              :device => VIM.VirtualE1000(
                :key => 0,
                :deviceInfo => {
                  :label => vif[:uuid],
                  :summary => 'VM Network'
                },
                :backing => VIM.VirtualEthernetCardNetworkBackingInfo(
                  :deviceName => 'VM Network'
                ),
                :addressType => 'manual',
                :macAddress => vif[:mac_addr].unpack('A2'*6).join(':')
              )
            }
          }
        end
        
        vmFolder.CreateVM_Task(:config => vm_cfg, :pool => rp).wait_for_completion

        # Download the vmx file, edit it and reupload it
        #TODO: Do this through the rbvmomi library instead of shell commands
        #TODO: Better tmp path if the former isn't possible
        sh("rm -f /tmp/#{inst[:uuid]}.vmx")
        sh("curl -s -u #{opts[:user]}:#{opts[:password]} -k -o /tmp/#{inst[:uuid]}.vmx https://#{opts[:host]}/folder/#{inst[:uuid]}/#{inst[:uuid]}.vmx?dsName=#{opts[:datastore]}")
        
        # Add the uploaded disk image to this VM
        sh("echo 'ide0:0.present = \"TRUE\"' >> /tmp/#{inst[:uuid]}.vmx")
        sh("echo 'ide0:0.fileName = \"#{inst[:uuid]}.vmdk\"' >> /tmp/#{inst[:uuid]}.vmx")
        # Add the metadata cdrom to this VM
        sh("echo 'ide1:0.present = \"TRUE\"' >> /tmp/#{inst[:uuid]}.vmx")
        sh("echo 'ide1:0.fileName = \"metadata.iso\"' >> /tmp/#{inst[:uuid]}.vmx")
        sh("echo 'ide1:0.deviceType = \"cdrom-image\"' >> /tmp/#{inst[:uuid]}.vmx")
        
        sh("curl -u #{opts[:user]}:#{opts[:password]} -k -s -T /tmp/#{inst[:uuid]}.vmx https://#{opts[:host]}/folder/#{inst[:uuid]}/#{inst[:uuid]}.vmx?dsName=#{opts[:datastore]}")
        sh("rm -f /tmp/#{inst[:uuid]}.vmx")
      end
    end
  end
end
