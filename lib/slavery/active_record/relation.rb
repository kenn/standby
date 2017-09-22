module ActiveRecord
  class Relation
    attr_accessor :slavery_target

    # Supports queries like User.on_slave.to_a
    alias_method :exec_queries_without_slavery, :exec_queries

    def exec_queries
      if slavery_target
        Slavery.on_slave(slavery_target) { exec_queries_without_slavery }
      else
        exec_queries_without_slavery
      end
    end


    # Supports queries like User.on_slave.count
    alias_method :calculate_without_slavery, :calculate

    def calculate(*args)
      if slavery_target
        Slavery.on_slave(slavery_target) { calculate_without_slavery(*args) }
      else
        calculate_without_slavery(*args)
      end
    end
  end
end
