package invaders

import "core:c"
import "core:fmt"
import "core:math/linalg"

import gl "vendor:OpenGL"
import stb_image "vendor:stb/image"

import platform "platform"

renderer: Renderer
manager:  EntityManager

playerHandle: EntityHandle

load_texture :: proc(filename: cstring) -> Texture {
    width:  c.int
    height: c.int
    comp:   c.int

    pixels := stb_image.load(filename, &width, &height, &comp, 4)

    if pixels == nil {
        fmt.println("failed to load image:", filename)
        return Texture{}
    }

    texture := create_texture(u32(width), u32(height), pixels)

    stb_image.image_free(pixels)

    return texture
}

game_init :: proc() {
    fmt.println("GL VERSION:", gl.GetString(gl.VERSION))
    fmt.println("RENDERER:  ", gl.GetString(gl.RENDERER))
    fmt.println("VENDOR:    ", gl.GetString(gl.VENDOR))

    window_width, window_height := platform.window_size()

    renderer = create_renderer()
    renderer.projection = linalg.matrix_ortho3d_f32(0.0, f32(window_width), f32(window_height), 0.0, 0.0, 1.0)

    manager = create_entity_manager(256)

    playerHandle = create_entity(&manager);

    {
        player := get_entity(&manager, playerHandle)

        player.flags |= EntityFlags.VISIBLE

        player.position = vec2{
            f32(window_width) * 0.5,
            f32(window_height) * 0.5,
        }

        player.size = vec2{
            16.0,
            16.0,
        }

        player.color = vec4{
            1.0,
            0.0,
            0.0,
            1.0,
        }
    }
}

game_shutdown :: proc() {
    destroy_renderer(&renderer)
    destroy_entity_manager(&manager)
}

game_update :: proc(delta_time: f32) {
    player := get_entity(&manager, playerHandle)

    update_player_input(player, delta_time)

    gl.ClearColor(0.25, 0.25, 0.25, 1.0)
    gl.Clear(gl.COLOR_BUFFER_BIT);

    draw_quad(&renderer, player.position, player.size, player.color)
}

update_player_input :: proc(player: ^Entity, delta_time: f32) {
    velocity: vec2

    velocity.x = f32(i32(platform.key_down('D')) - i32(platform.key_down('A')))
    velocity.y = f32(i32(platform.key_down('S')) - i32(platform.key_down('W')))

    if velocity.x != 0 && velocity.y != 0 {
        velocity = linalg.normalize(velocity)
    }

    player.position += velocity * 250.0 * delta_time
}