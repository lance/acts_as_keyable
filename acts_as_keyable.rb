
require 'active_record/base'

module ActiveRecord #:nodoc:
  module Acts #:nodoc:  
    module Keyable
      
      def self.included(base) # :nodoc:
        base.extend ClassMethods
      end    
      
      class KeyWrapper
        def initialize(key_for)
          @key_for = key_for
        end
        
        def before_create(record)
          record.set_key @key_for
        end
      end

      module ClassMethods
        
        def acts_as_keyable(key_for)
          return if self.included_modules.include?( ActiveRecord::Acts::Keyable::ActMethods )
          class_eval do
            validates_presence_of key_for
            validates_uniqueness_of key_for
            before_create ActiveRecord::Acts::Keyable::KeyWrapper.new( key_for )
            include ActiveRecord::Acts::Keyable::ActMethods    
          end
        end
      end #ClassMethods
        
      module ActMethods
        ## instace injection
        def set_key(key_for)
          self.key = generate_key_for(key_for)
        end
        
        def to_param
          self.key
        end      

        def generate_key_for(key_for)
          begin
            return nil unless self.send(key_for)
            generated_key = self.send(key_for).downcase.gsub( /[\!\.\?]+$/, '').gsub( /[\"\']/, '' ).gsub( /([^a-zA-Z0-9]+)/, '_' ) 
            generated_key.gsub!( /(_)+$/, '' )

            suffix, i = '', 2
            while ( true )
              if ( self.class.find( :first, :conditions => "key = '#{generated_key+suffix}'" ) ) 
                suffix = "_#{i}"
              else
                generated_key = generated_key + suffix
                break
              end
              i += 1
            end
            return generated_key
          rescue NoMethodError => boom
            print boom.message + "\n"
            print boom.backtrace.join("\n")
            print "I don't know how to respond to #{key_for}"
          end
          nil
        end  
      end # ActMethods
    end # Keyable
  end # Acts
end # ActiveRecord

ActiveRecord::Base.class_eval { include ActiveRecord::Acts::Keyable }

