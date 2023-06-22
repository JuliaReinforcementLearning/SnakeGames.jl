export play, scene_and_node

using Makie
using WGLMakie
using Colors

const SNAKE_GAME_SCEENS = IdDict()

function scene_and_node(game::SnakeGame)
    if haskey(SNAKE_GAME_SCEENS, game)
        SNAKE_GAME_SCEENS[game]
    else
        node = Observable(game)
        scene = init_screen(node)
        get!(SNAKE_GAME_SCEENS, game, (scene, node))
    end
end

function Base.display(game::SnakeGame)
    scene, node = scene_and_node(game)
    node[] = game
    display(scene)
end

function init_screen(game::Observable{<:SnakeGame{2}}; resolution=(1000,1000))
    SNAKE_COLORS = range(HSV(60,1,1), stop=HSV(300,1,1), length=length(game[].snakes)+1)
    scene = Scene(resolution = resolution, raw = true, camera = campixel!)

    area = scene.px_area
    poly!(scene, area)

    grid_size = @lift((widths($area)[1] / size($game)[1], widths($area)[2] / size($game)[2]))

    walls = get_walls(game[])
    if length(walls) > 0
        wall_boxes = @lift([Rect2f((w.I .- (1,1)) .* $grid_size , $grid_size) for w in walls])
        poly!(scene, wall_boxes, color=:gray)
    end

    for i in 1:length(game[].snakes)
        snake_boxes = @lift([Rect2f((p.I .- (1,1)) .* $grid_size , $grid_size) for p in $game.snakes[i]])
        poly!(scene, snake_boxes, color=SNAKE_COLORS[i], strokewidth = 5, strokecolor = :black)

        snake_head_box = @lift(Rect2f(($game.snakes[i][1].I .- (1,1)) .* $grid_size , $grid_size))
        poly!(scene, snake_head_box, color=:black)
        snake_head = @lift((($game.snakes[i][1].I .- 0.5) .* $grid_size))
        scatter!(scene, snake_head, marker='◉', color=SNAKE_COLORS[i], markersize=@lift(minimum($grid_size)))
    end

    food_position = @lift([(f.I .- (0.5, 0.5)) .* $grid_size for f in $game.foods])
    scatter!(scene, food_position, color=:red, marker='♥', markersize=@lift(minimum($grid_size)))

    display(scene)
    scene
end

play() = play(SnakeGame())

function play(game::SnakeGame{2};f_name="test.mp4",framerate = 2)
    @assert length(game.snakes) <= 3 "At most three players are supported in interactive mode"
    scene, game_node = scene_and_node(game)

    LEFT = CartesianIndex(-1, 0)
    RIGHT = CartesianIndex(1, 0)
    UP = CartesianIndex(0, 1)
    DOWN = CartesianIndex(0, -1)

    actions = [rand([LEFT,RIGHT,UP,DOWN]) for _ in game.snakes]
    is_exit = Ref{Bool}(false)

    on(scene, events(scene).keyboardbutton) do but
        @show but
        if ispressed(scene, Keyboard.left)
            actions[1] != -LEFT && (actions[1] = LEFT)
        elseif ispressed(scene, Keyboard.up)
            actions[1] != -UP && (actions[1] = UP)
        elseif ispressed(scene, Keyboard.down)
            actions[1] != -DOWN && (actions[1] = DOWN)
        elseif ispressed(scene, Keyboard.right)
            actions[1] != -RIGHT && (actions[1] = RIGHT)
        elseif ispressed(scene, Keyboard.a)
            actions[2] != -LEFT && (actions[2] = LEFT)
        elseif ispressed(scene, Keyboard.w)
            actions[2] != -UP && (actions[2] = UP)
        elseif ispressed(scene, Keyboard.s)
            actions[2] != -DOWN && (actions[2] = DOWN)
        elseif ispressed(scene, Keyboard.d)
            actions[2] != -RIGHT && (actions[2] = RIGHT)
        elseif ispressed(scene, Keyboard.j)
            actions[3] != -LEFT && (actions[3] = LEFT)
        elseif ispressed(scene, Keyboard.i)
            actions[3] != -UP && (actions[3] = UP)
        elseif ispressed(scene, Keyboard.k)
            actions[3] != -DOWN && (actions[3] = DOWN)
        elseif ispressed(scene, Keyboard.l)
            actions[3] != -RIGHT && (actions[3] = RIGHT)
        elseif ispressed(scene, Keyboard.q)
            is_exit[] = true
        end
    end
    record(scene, f_name; framerate=framerate) do io
        while true
            sleep(1)
            is_success = game(actions)
            game_node[] = game
            recordframe!(io)
            is_success || break
            is_exit[] && break
        end
    end
    println("game over")
end
