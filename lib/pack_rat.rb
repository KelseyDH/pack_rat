module PackRat
  module CacheHelper
    extend ActiveSupport::Concern

    included do
      extend Cacher
      include Cacher
      cattr_accessor :updated_attribute_name
      self.updated_attribute_name ||= :updated_at
      cattr_accessor :file_location
      self.file_location = file_location_guesser
    end

    module Cacher
      def cache(key='', options={}, &block)
        unless options[:overwrite_key]
          calling_method = caller[0][/`([^']*)'/, 1]
          key << calling_method << '/'
          key << self.cache_key << '/'
          if self.is_a? Class
            key << self.file_digest
          else
            key << self.class.file_digest
          end
        end
        puts key if options[:debug]
        filtered_options = options.except(:overwrite_key, :debug)
        Rails.cache.fetch key, filtered_options do
          block.call
        end
      end
    end

    module ClassMethods    
      # Create cache_key for class, use most recently updated record
      unless self.respond_to? :cache_key
        define_method :cache_key do
          key = order("#{self.updated_attribute_name} DESC").first.cache_key if self.superclass.to_s == "ActiveRecord::Base"
          key << "/#{self.to_s}"
        end
      end
      
      def file_digest
        if self.file_location
          begin
            file = File.read(self.file_location)
            Digest::MD5.hexdigest(file)
          rescue
            nil
          end
        end
      end
      
      def file_location_guesser
        "#{Rails.root}/app/models/#{self.to_s.split('::').join('/').underscore.downcase}.rb" if defined? Rails
      end
  
    end
  end
  
  module ActiveRecordExtension
    extend ActiveSupport::Concern
    
    module ClassMethods
      def inherited(child_class)
        child_class.send(:include, PackRat::CacheHelper)
        super
      end
    end
  end

end

if defined? ActiveRecord::Base
  ActiveRecord::Base.send(:include, PackRat::ActiveRecordExtension)
end
  
  
  