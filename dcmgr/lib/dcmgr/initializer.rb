# -*- coding: utf-8 -*-

module Dcmgr
  module Initializer

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def conf
        depr_msg = %{
          Dcmgr.conf is DEPRECATED!
          Use the new Dcmgr::Configurations methods instead. Example:
          For hva.conf:   Dcmgr::Configurations.hva
          For dcmgr.conf: Dcmgr::Configurations.dcmgr
          etc.

          Dcmgr.conf was used at:
          #{caller.first}
        }

        respond_to?(:logger) ? logger.warn(depr_msg) : puts(depr_msg)

        Dcmgr::Configurations.last
      end

      def load_conf(conf_class, files)
        path = files.find { |i| File.exists?(i) }
        abort("ERROR: Failed to load #{files.inspect}.") if path.nil?

        begin
          ::Dcmgr.instance_eval do
            # Set the dynamic config name method. For example:
            # loading hva.conf will create Dcmgr::Configurations.hva method
            conf_name = path.split('/').last.split('.').first
            conf_name.downcase!
            conf_name.tr!(' ', '_')

            Dcmgr::Configurations.load_conf(conf_name, conf_class.load(path))
          end
        rescue NoMethodError => e
          abort("Syntax Error: #{path}\n  #{e.backtrace.first} #{e.message}")
        rescue Fuguta::Configuration::ValidationError => e
          abort("Validation Error: #{path}\n  " +
                e.errors.join("\n  ")
                )
        end
      end

      def run_initializers(*files)
        if Dcmgr::Configurations.last.nil?
          raise "Complete the configuration prior to run_initializers()."
        end

        @files ||= []
        if files.length == 0
          @files << "*"
        else
          @files = files
        end

        initializer_hooks.each { |n|
          n.call
        }
      end

      def initializer_hooks(&blk)
        @initializer_hooks ||= []
        if blk
          @initializer_hooks << blk
        end
        @initializer_hooks
      end
    end
  end
end
