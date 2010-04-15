module MoritzHammer
    NUMBEROFCARDRANKS = 13
    MAXCARDSPERRANK = 4
    MAXCARDSPERHAND = 7
    class DagNode < Struct.new(:code, :index, :next_links, :eq_flush, :eq_noflush)
        @@hash_of_all_dags = {}
        @@queue_of_unenumerated_dags = []
        @@code = 0
        def self.create_new_dag
            "creating new dag table"
            @@hash_of_all_dags = {}
            @@queue_of_unenumerated_dags = []
            @@code = 0
            dag_node_for Array.new(NUMBEROFCARDRANKS,0)
            enumerate_dag_node @@queue_of_unenumerated_dags.shift until @@queue_of_unenumerated_dags.empty?
            "finished new dag table"
            @@hash_of_all_dags.size
        end
        def self.dag_node_for index
            @@hash_of_all_dags[index] ||= @@queue_of_unenumerated_dags.push(new(@@code+=1, index))
        end
        def self.enumerate_dag_node node
            node.next_links = Array.new(NUMBEROFCARDRANKS,nil)
            return if node.index.inject(&:+) == MAXCARDSPERHAND
            node.index.each_with_index do |each, index|
                unless node.index[index] == MAXCARDSPERRANK
                    clone_index = node.index.clone
                    clone_index[index]+=1
                    node.next_links[index] = dag_node_for clone_index
                end
            end
        end
    end
end
MoritzHammer::DagNode.create_new_dag