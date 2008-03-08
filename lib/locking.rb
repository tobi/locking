module Locking
  class LockError < ActiveRecord::ActiveRecordError
  end  
  
  class LockTimeout < LockError      
  end    
  
  def self.included(base)
    base.send(:extend, ClassMethods)
  end
    
  module ClassMethods
    
    # acquires an application level lock in the mysql server. 
    def acquire_lock(lock_name = table_name, wait_timeout = 0)
      case c = connection.select_value("SELECT GET_LOCK(#{quote_value(lock_name)}, #{quote_value(wait_timeout)})")
      when '1' 
        yield if block_given?
      when '0' 
        false
      when 'NULL'
        raise LockError, "Error in locking mechanism"
      else
        raise LockError, "Unknown response from database: #{c.inspect}"
      end
      
    ensure
      connection.select_one("SELECT RELEASE_LOCK(#{quote_value(lock_name)})")
    end
    
    # acquires an application level lock in the mysql server. Throws Locking::LockTimeout if the 
    # lock cannot be acquired.
    def acquire_lock!(lock_name = table_name, wait_timeout = 0, &block)
      acquire_lock(lock_name, table_name, &block) or raise LockTimeout, 'Timeout waiting for lock'
    end
    
  end
  
end
