require File.expand_path('../cactus_kev_value', __FILE__)

module MoritzHammer
    NUMBEROFCARDRANKS = 13
    MAXCARDSPERRANK = 4
    MAXCARDSPERHAND = 7
    class DagNode < Struct.new(:code, :index, :next_links, :eq_flush, :eq_noflush)
        def self.root
            @@dag[0]
        end
        def self.size
            @@hash_of_all_dags.size
        end
        def self.dag
            @@dag 
        end
        def self.print_display
            puts 'Display of all Dag Nodes'
            printf "Dag = [\n"
            @@dag.each do |node|
                printf "\tDagNode.new("
                printf "%5d,   %s,   [", node.code, node.index.inspect
                printf((["%5s"]*NUMBEROFCARDRANKS).join(', '),
                    *node.next_links.map{|each| (each && each.code).inspect})
                printf "]),\n", 
            end
            printf "]"
            puts
        end
        def self.create_new_dag
            @@hash_of_all_dags = {}
            @@queue_of_unenumerated_dags = []
            @@dag = []
            @@code = 0
            dag_node_for Array.new(NUMBEROFCARDRANKS,0)
            enumerate_dag_node(@@queue_of_unenumerated_dags.shift) until @@queue_of_unenumerated_dags.empty?
            @@hash_of_all_dags.size
        end
        def self.dag_node_for index
            @@hash_of_all_dags[index] ||= new_and_queued_dag_node_for(index)
        end
        def self.new_and_queued_dag_node_for index
            # puts "new_and_queued_dag_node_for #{index.inspect} with code #{@@code}"
            raise "internal error" if @@hash_of_all_dags[index]
            puts "#{@@code}" if (@@code % 1000).zero?
            new_node = new(@@code, index)
            @@code+=1
            @@queue_of_unenumerated_dags.push(new_node)
            new_node
        end
        def self.enumerate_dag_node node
            @@dag << node
            node.next_links = Array.new(NUMBEROFCARDRANKS,nil)
            return if node.index.inject(&:+) == MAXCARDSPERHAND
            node.index.each_with_index do |each, index|
                unless node.index[index] == MAXCARDSPERRANK
                    clone_index = node.index.clone
                    clone_index[index]+=1
                    dag_node_for_clone_index = dag_node_for clone_index
                    node.next_links[index] = dag_node_for_clone_index
                end
            end
        end
    end
end
begin_creation = Time.now
MoritzHammer::DagNode.create_new_dag
puts "New dag created in #{Time.now - begin_creation} seconds."
puts "Dag has #{MoritzHammer::DagNode.size} nodes"
MoritzHammer::DagNode.print_display