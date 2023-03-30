using GraphletCounting
using Test
using LinearAlgebra

@testset "automated 4-node" begin
    ## uses the generate_heterogeneous_graphlet_dict function to find the right ordering of each graphlet permutation, to test comprehensively across all possible typesets if count_graphlets is ordering correctly.
    
    ##functions necessary for test here (for now; do they go into GraphletCounting proper?)
    function permute_all(F::AbstractVector,m::Int;replace::Bool=false)
        ##find all sets of objects F choose m
        ## F is the set of objects, m is how many we choose for each permutation
        #if replace is false, m!>|F|
        if((replace == false) & (m>length(F)))
            throw(ArgumentError("When replace=false, m!>|F| (i.e. cannot choose more elements than provided)"))
        end
        n = length(F)
        comb = []
        for i in 1:m
            push!(comb,repeat(vcat([repeat([F[x]],n^(m-i)) for x in 1:n]...),n^(i  -1)))
        end
        candidates = hcat(comb...)
        if replace==false
            candidates = candidates[length.(unique.(eachrow(candidates))).==m,:]   
        end
        return candidates
    end;   

    function adj_is_connected(adj)
        #using the Fieldler value to determine if a graph is connected
        deg = diagm(vec(sum(adj,dims=1)))
        Lap = deg - adj
        test = eigvals(Lap)[2]
        return test>0
    end

    function edgelist_from_adj(adjacency_matrix::AbstractArray)
        edgelist=Array{Pair}(undef,sum(UpperTriangular(adjacency_matrix)))
        count=0
        for (i,row) in enumerate(eachrow(UpperTriangular(adjacency_matrix)))
            for j in 1:size(row,1)
                if (row[j]==1)
                    count=count+1
                    edgelist[count]=Pair(i,j)
                end
            end
        end
        return edgelist
    end

    #get all possible connected adj_matrices (in vector form)
    candidates = permute_all([0,1],6,replace = true)
    candidate_adj = GraphletCounting.graphlet_edgelist_array_to_adjacency.(eachrow(candidates))
    connected = candidate_adj[adj_is_connected.(candidate_adj),:]
    
    #further restrict  to just the 4-node case
    connected_4 = connected[.!(in.(0,sum.(connected,dims=1)))]
    #set types to be maximal to order size
    types = ["a","b","c","d"]
    
    #provide a map for eigs of each adj back to appropriate graphlet label
    label_dict = Dict(
                      round.(eigvals(GraphletCounting.graphlet_edgelist_array_to_adjacency([1,0,0,1,0,1])),digits=5).+0.0=>"4-path",  
                      round.(eigvals(GraphletCounting.graphlet_edgelist_array_to_adjacency([0,1,0,1,0,1])),digits=5).+0.0=>"4-star",  
                      round.(eigvals(GraphletCounting.graphlet_edgelist_array_to_adjacency([1,1,0,1,0,1])),digits=5).+0.0=>"4-tail",  
                      round.(eigvals(GraphletCounting.graphlet_edgelist_array_to_adjacency([1,0,1,1,0,1])),digits=5).+0.0=>"4-cycle",  
                      round.(eigvals(GraphletCounting.graphlet_edgelist_array_to_adjacency([1,1,0,1,1,1])),digits=5).+0.0=>"4-chord",  
                      round.(eigvals(GraphletCounting.graphlet_edgelist_array_to_adjacency([1,1,1,1,1,1])),digits=5).+0.0=>"4-clique"  
                    )

    for adj in connected_4
            for (k,v) in GraphletCounting.generate_heterogeneous_graphlet_dict(adj,types)
                ##note that vlist and edgelist are from original (unchanged) adj matrix, but v from above has been shifted to canonical form 
                vlist = split(k,"_")
                elist = edgelist_from_adj(adj)
                exp = v*"_"*label_dict[round.(eigvals(adj),digits=5).+0.0]
                @test count_graphlets(vlist,elist,4,recursive = false) == Dict{String,Int}(exp=>1)
            end
    end
end

@testset "recursive 4-node" begin
#### A minimal test for each graphlet. Initially just with two types (colours).

## 4-path tests{{{


#     1R    4R
#     |      |
#     |      |
#     |      |
#     2R----3R

testvlist = [ "1" "red"; "2" "red";"3" "red"; "4" "red"]
testelist = [ 1=>2;2 =>3 ;3=>4]

four_path_expected_1 = Dict{String,Int}("red_red_red_red_4-path"=>1,"red_red_red_3-path" =>2)

four_path_test_1 = count_graphlets(testvlist[:,2],testelist,4)
#-----------------------------------------------------------------------------------------
#     1R    4B
#     |      |
#     |      |
#     |      |
#     2R----3R

testvlist = [ "1" "red"; "2" "red";"3" "red"; "4" "blue"]
testelist = [ 1=>2;2 =>3 ;3=>4]

four_path_expected_2 = Dict{String,Int}("blue_red_red_red_4-path"=>1,"red_red_red_3-path" =>1,"blue_red_red_3-path" =>1)

four_path_test_2 = count_graphlets(testvlist[:,2],testelist,4)
#--------------------------------------------------------------------------------------------

#     1R    4R
#     |      |
#     |      |
#     |      |
#     2R----3B

testvlist = [ "1" "red"; "2" "red";"3" "blue"; "4" "red"]
testelist = [ 1=>2;2 =>3 ;3=>4]

four_path_expected_3 = Dict{String,Int}("red_blue_red_red_4-path"=>1,"red_blue_red_3-path" =>1,"blue_red_red_3-path" =>1)

four_path_test_3 = count_graphlets(testvlist[:,2],testelist,4)
#--------------------------------------------------------------------------------------------

#     1R    4B
#     |      |
#     |      |
#     |      |
#     2R----3B

testvlist = [ "1" "red"; "2" "red";"3" "blue"; "4" "blue"]
testelist = [ 1=>2;2 =>3 ;3=>4]

four_path_expected_4 = Dict{String,Int}("blue_blue_red_red_4-path"=>1,"blue_blue_red_3-path" =>1,"blue_red_red_3-path" =>1)

four_path_test_4 = count_graphlets(testvlist[:,2],testelist,4)

#--------------------------------------------------------------------------------------------

#     1R    4B
#     |      |
#     |      |
#     |      |
#     2B----3R

testvlist = [ "1" "red"; "2" "blue";"3" "red"; "4" "blue"]
testelist = [ 1=>2;2 =>3 ;3=>4]

four_path_expected_5 = Dict{String,Int}("blue_red_blue_red_4-path"=>1,"red_blue_red_3-path" =>1,"blue_red_blue_3-path" =>1)

four_path_test_5 = count_graphlets(testvlist[:,2],testelist,4)

#--------------------------------------------------------------------------------------------

#     1R    4R
#     |      |
#     |      |
#     |      |
#     2B----3B

testvlist = [ "1" "red"; "2" "blue";"3" "blue"; "4" "red"]
testelist = [ 1=>2;2 =>3 ;3=>4]

four_path_expected_6 = Dict{String,Int}("red_blue_blue_red_4-path"=>1,"blue_blue_red_3-path" =>2)

four_path_test_6 = count_graphlets(testvlist[:,2],testelist,4)
#--------------------------------------------------------------------------------------------

@test four_path_test_1 == four_path_expected_1
@test four_path_test_2 == four_path_expected_2
@test four_path_test_3 == four_path_expected_3
@test four_path_test_4 == four_path_expected_4
@test four_path_test_5 == four_path_expected_5
@test four_path_test_6 == four_path_expected_6#=}}}=#

## 4-tail tests{{{

#     1R    4R
#     | \   |
#     |  \  |
#     |   \ |
#     2R----3R

testvlist = [ "1" "red"; "2" "red";"3" "red"; "4" "red"]
testelist = [ 1=>2;1 =>3 ;2=>3;3=>4]

four_tail_expected_1 = Dict{String,Int}("red_red_red_3-tri"=>1,"red_red_red_red_4-tail"=>1,"red_red_red_3-path" =>2)

four_tail_test_1 = count_graphlets(testvlist[:,2],testelist,4)


#     1R    4B
#     | \   |
#     |  \  |
#     |   \ |
#     2R----3R

testvlist = [ "1" "red"; "2" "red";"3" "red"; "4" "blue"]
testelist = [ 1=>2;1 =>3 ;2=>3;3=>4]

four_tail_expected_2 = Dict{String,Int}("red_red_red_3-tri"=>1,"red_red_red_blue_4-tail"=>1,"blue_red_red_3-path" =>2)

four_tail_test_2 = count_graphlets(testvlist[:,2],testelist,4)

#     1R    4R
#     | \   |
#     |  \  |
#     |   \ |
#     2R----3B

testvlist = [ "1" "red"; "2" "red";"3" "blue"; "4" "red"]
testelist = [ 1=>2;1 =>3 ;2=>3;3=>4]

four_tail_expected_3 = Dict{String,Int}("blue_red_red_3-tri"=>1,"red_red_blue_red_4-tail"=>1,"red_blue_red_3-path" =>2)

four_tail_test_3 = count_graphlets(testvlist[:,2],testelist,4)

#     1R    4R
#     | \   |
#     |  \  |
#     |   \ |
#     2B----3R

testvlist = [ "1" "red"; "2" "blue";"3" "red"; "4" "red"]
testelist = [ 1=>2;1 =>3 ;2=>3;3=>4]

four_tail_expected_4 = Dict{String,Int}("blue_red_red_3-tri"=>1,"blue_red_red_red_4-tail"=>1,"blue_red_red_3-path" =>1,"red_red_red_3-path"=>1)

four_tail_test_4 = count_graphlets(testvlist[:,2],testelist,4)

#     1R    4B
#     | \   |
#     |  \  |
#     |   \ |
#     2R----3B

testvlist = [ "1" "red"; "2" "red";"3" "blue"; "4" "blue"]
testelist = [ 1=>2;1 =>3 ;2=>3;3=>4]

four_tail_expected_5 = Dict{String,Int}("blue_red_red_3-tri"=>1,"red_red_blue_blue_4-tail"=>1,"blue_blue_red_3-path" =>2)

four_tail_test_5 = count_graphlets(testvlist[:,2],testelist,4)

#     1R    4B
#     | \   |
#     |  \  |
#     |   \ |
#     2B----3R

testvlist = [ "1" "red"; "2" "blue";"3" "red"; "4" "blue"]
testelist = [ 1=>2;1 =>3 ;2=>3;3=>4]

four_tail_expected_6 = Dict{String,Int}("blue_red_red_3-tri"=>1,"blue_red_red_blue_4-tail"=>1,"blue_red_blue_3-path" =>1,"blue_red_red_3-path"=>1)

four_tail_test_6 = count_graphlets(testvlist[:,2],testelist,4)



@test four_tail_test_1 == four_tail_expected_1
@test four_tail_test_2 == four_tail_expected_2
@test four_tail_test_3 == four_tail_expected_3
@test four_tail_test_4 == four_tail_expected_4
@test four_tail_test_5 == four_tail_expected_5
@test four_tail_test_6 == four_tail_expected_6
#=}}}=#

## 4-star test{{{

#     1R    4R
#       \   |
#        \  |
#         \ |
#     2R----3R
    
testvlist = [ "1" "red"; "2" "red";"3" "red"; "4" "red"]
testelist = [ 1=>3;2 =>3 ;3=>4]

@test count_graphlets(testvlist[:,2],testelist,4) == Dict{String,Int}("red_red_red_3-path"=>3,"red_red_red_red_4-star"=>1)

#---------------------------------------------------------------------

#     1R    4B
#       \   |
#        \  |
#         \ |
#     2R----3R
    
testvlist = [ "1" "red"; "2" "red";"3" "red"; "4" "blue"]
testelist = [ 1=>3;2 =>3 ;3=>4]

@test count_graphlets(testvlist[:,2],testelist,4) == Dict{String,Int}("red_red_red_3-path"=>1,"blue_red_red_3-path"=>2,"blue_red_red_red_4-star"=>1)

#---------------------------------------------------------------------

#     1R    4R
#       \   |
#        \  |
#         \ |
#     2R----3B
    
testvlist = [ "1" "red"; "2" "red";"3" "blue"; "4" "red"]
testelist = [ 1=>3;2 =>3 ;3=>4]

@test count_graphlets(testvlist[:,2],testelist,4) == Dict{String,Int}("red_blue_red_3-path"=>3,"red_red_blue_red_4-star"=>1)

#---------------------------------------------------------------------

#     1R    4B
#       \   |
#        \  |
#         \ |
#     2R----3B
    
testvlist = [ "1" "red"; "2" "red";"3" "blue"; "4" "blue"]
testelist = [ 1=>3;2 =>3 ;3=>4]

@test count_graphlets(testvlist[:,2],testelist,4) == Dict{String,Int}("red_blue_red_3-path"=>1,"blue_blue_red_3-path"=>2,"blue_red_blue_red_4-star"=>1)
#=}}}=#

#---------------------------------------------------------------------

#     1R    4B
#       \   |
#        \  |
#         \ |
#     2B----3R
    
testvlist = [ "1" "red"; "2" "blue";"3" "red"; "4" "blue"]
testelist = [ 1=>3;2 =>3 ;3=>4]

@test count_graphlets(testvlist[:,2],testelist,4) == Dict{String,Int}("blue_red_blue_3-path"=>1,"blue_red_red_3-path"=>2,"blue_blue_red_red_4-star"=>1)
#=}}}=#

end
