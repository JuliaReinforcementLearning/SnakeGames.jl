export SnakeGame

using Random

struct SnakeGame{N,M,R<:AbstractRNG}
    board::BitArray{M}
    # TODO: using DataStructures: Deque ?
    snakes::Vector{Vector{CartesianIndex{N}}}
    foods::Set{CartesianIndex{N}}
    walls::Vector{CartesianIndex{N}}
    n_foods::Int
    rng::R
end

Base.size(g::SnakeGame) = size(g.board)[2:end]

ind_of_wall(game) = 2*length(game.snakes)+1
ind_of_food(game) = 2*length(game.snakes)+2

mark_wall!(game, ind) = game.board[ind_of_wall(game), ind] = true
mark_food!(game, ind) = game.board[ind_of_food(game), ind] = true
unmark_food!(game, ind) = game.board[ind_of_food(game), ind] = false
mark_snake_head!(game, ind, i) = game.board[i, ind] = true
unmark_snake_head!(game, ind, i) = game.board[i, ind] = false
mark_snake_body!(game, ind, i) = game.board[length(game.snakes)+i, ind] = true
unmark_snake_body!(game, ind, i) = game.board[length(game.snakes)+i, ind] = false

get_walls(game) = findall(isone, selectdim(game.board, 1, ind_of_wall(game)))

"""
    SnakeGame(;kwargs...)

# Keyword Arguments

- `shape::NTuple{N,Int}=(8,8)`, the size of game board. `N` can be greater than 2.
- `walls`, an iterable type with elements of type `CartesianIndex{N}`.
- `n_snakes`, number of snakes.
- `n_foods`, maximum number of foods in each step.
- `rng::AbstractRNG`, inner RNG used to sample initial snakes and necessary foods in each step.
"""
function SnakeGame(;shape=(8,8), walls=CartesianIndex{length(shape)}[], n_snakes=1, n_foods=1,rng=Random.GLOBAL_RNG)
    n_snakes+n_foods >= reduce(*, shape) && error("n_snakes+n_foods must be less than the total grids")
    board = BitArray(undef, n_snakes#=snake head=#+n_snakes#=snake body=#+1#=wall=#+1#=food=#, shape...)
    snakes = [Vector{CartesianIndex{length(shape)}}() for _ in 1:n_snakes]
    foods = Set{CartesianIndex{length(shape)}}()
    game = SnakeGame(board, snakes, foods, walls, n_foods, rng)
    reset!(game)
    game
end

function reset!(game::SnakeGame)
    fill!(game.board, false)

    for s in game.snakes
        empty!(s)
    end
    
    empty!(game.foods)

    # do not change walls

    for w in game.walls
        mark_wall!(game, w)
    end

    while length(game.foods) < game.n_foods
        p = rand(game.rng, CartesianIndices(size(game.board)[2:end]))
        if any(@view(game.board[:, p]))
            continue  # there's a wall
        else
            push!(game.foods, p)
            mark_food!(game, p)
        end
    end
    
    for i in 1:length(game.snakes)
        while true
            p = rand(game.rng, CartesianIndices(size(game.board)[2:end]))
            if any(@view(game.board[:, p]))
                continue  # there's a wall or food
            else
                push!(game.snakes[i], p)
                mark_snake_head!(game, p, i)
                break
            end
        end
    end

end

(game::SnakeGame)(action::CartesianIndex) = game([action])

function (game::SnakeGame{N})(actions::Vector{CartesianIndex{N}}) where N
    # 1. move snake
    for ((i, s), a) in zip(enumerate(game.snakes), actions)
        unmark_snake_head!(game, s[1], i)
        mark_snake_body!(game, s[1], i)
        pushfirst!(s, CartesianIndex(mod.((s[1] + a).I, axes(game.board)[2:end])))
        mark_snake_head!(game, s[1], i)
        if s[1] in game.foods
            unmark_food!(game, s[1])
        else
            unmark_snake_body!(game, s[end], i)
            pop!(s)
        end
    end
    # 2. check collision
    for s in game.snakes
        sum(@view(game.board[:, s[1]])) == 1 || return false
    end
    # 3. create new foods
    for f in game.foods
        if !game.board[ind_of_food(game), f]
            # food is eaten
            pop!(game.foods, f)
            food = rand(game.rng, CartesianIndices(size(game)))
            attempts = 1
            while any(@view(game.board[:, food]))
                food = rand(game.rng, CartesianIndices(size(game)))
                attempts += 1
                if attempts > reduce(*, size(game))
                    @warn "a rare case happened: sampled too many times to generate food"
                    empty_positions = findall(iszero, vec(any(game.board, dims=1)))
                    if length(empty_positions) == 0
                        return false
                    else
                        food = CartesianIndices(size(game.board)[2:end])[rand(game.rng, empty_positions)]
                        break
                    end
                end
            end
            push!(game.foods, food)
            mark_food!(game, food)
        end
    end
    return true
end