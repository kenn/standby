module ActiveRecord
  class Relation
    attr_accessor :standby_target

    # Supports queries like User.on_standby.to_a
    alias_method :exec_queries_without_standby, :exec_queries

    def exec_queries
      if standby_target
        Standby.on_standby(standby_target) { exec_queries_without_standby }
      else
        exec_queries_without_standby
      end
    end


    # Supports queries like User.on_standby.count
    alias_method :calculate_without_standby, :calculate

    def calculate(*args)
      if standby_target
        Standby.on_standby(standby_target) { calculate_without_standby(*args) }
      else
        calculate_without_standby(*args)
      end
    end
  end
end
