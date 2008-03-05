require 'locking'

ActiveRecord::Base.send(:include, Locking)