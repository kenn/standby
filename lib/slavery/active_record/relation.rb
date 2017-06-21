module ActiveRecord
  class Relation
    attr_accessor :slavery_target
    attr_accessor :slave_name

    # Supports queries like User.on_slave.to_a
    alias_method :exec_queries_without_slavery, :exec_queries

    def exec_queries
      if slavery_target == :slave
        Slavery.on_slave(slave_name) { exec_queries_without_slavery }
      else
        exec_queries_without_slavery
      end
    end


    # Supports queries like User.on_slave.count
    alias_method :calculate_without_slavery, :calculate

    def calculate(*args)
      if slavery_target == :slave
        Slavery.on_slave(slave_name) { calculate_without_slavery(*args) }
      else
        calculate_without_slavery(*args)
      end
    end
  end
end
