require 'pack_rat/cache_helper/cacher'
module PackRat
  module CacheHelper
    extend ActiveSupport::Concern

    included do
      # Include and Extend so cache method is available in all contexts
      extend Cacher
      include Cacher
      self.file_location = file_location_guesser
      self.updated_attribute_name = :updated_at
    end

    module ClassMethods

      # Instance attribute name that stores the last time the object was updated, usually :updated_at
      def updated_attribute_name
        @updated_attribute_name
      end
      def updated_attribute_name=(name)
        @updated_attribute_name = name
      end
      
      # File path of the class
      def file_location
        @file_location
      end
      def file_location=(path)
        @file_location = path
        generate_file_digest
      end
      
      # Stores the MD5 Digest of the class
      def file_digest
        @file_digest
      end
      def file_digest=(digest)
        @file_digest = digest
      end
      
      # Creates MD5 Digest of the set file_location attribute
      def generate_file_digest
        if self.file_location
          begin
            file = File.read(self.file_location)
            self.file_digest = Digest::MD5.hexdigest(file)
          rescue
            self.file_digest = nil
          end
        end
      end
      
      # Uses Rails conventions to determine location of the defined class
      def file_location_guesser
        # This needs to be refactored to take a prefix to replace the rails/app/models
        # AR Extension would be then include a prefix that this picks up
        # Haven't decided on a clean way to implement this
        "#{Rails.root}/app/models/#{self.to_s.split('::').join('/').underscore.downcase}.rb" if defined? Rails
      end

      # Create cache_key for class, use most recently updated record
      unless self.respond_to? :cache_key
        define_method :cache_key do
          key = order("#{self.updated_attribute_name} DESC").first.cache_key if self.superclass.to_s == "ActiveRecord::Base"
          key << "/#{self.to_s}" if key
        end
      end
  
    end
  end
end