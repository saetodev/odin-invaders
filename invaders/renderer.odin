package invaders

import "core:fmt"
import "core:math/linalg"

import gl "vendor:OpenGL"

Texture :: struct {
    handle: u32,
    width:  u32,
    height: u32,
}

Renderer :: struct {
    shader: u32,
    vao:    u32,
    vbo:    u32,

    white_texture: Texture,
    projection:    mat4,
}

VERTEX_SHADER_SOURCE :: `#version 330 core

layout(location = 0) in vec2 a_position;
layout(location = 1) in vec2 a_texCoord;

out vec2 v_texCoord;

uniform mat4 u_projection;
uniform mat4 u_transform;

void main() {
    v_texCoord  = a_texCoord;
    gl_Position = u_projection * u_transform * vec4(a_position, 0.0, 1.0);
}`

FRAGMENT_SHADER_SOURCE :: `#version 330 core

in vec2 v_texCoord;

out vec4 o_color;

uniform vec4 u_color;
uniform sampler2D u_texture;

void main() {
    o_color = u_color * texture(u_texture, v_texCoord);
}
`

create_texture :: proc(width: u32, height: u32, pixels: rawptr) -> Texture {
    texture := Texture{
        width  = width,
        height = height,
    }

    gl.GenTextures(1, &texture.handle)
    gl.BindTexture(gl.TEXTURE_2D, texture.handle)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP)

    gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA, i32(width), i32(height), 0, gl.RGBA, gl.UNSIGNED_BYTE, pixels)
    gl.BindTexture(gl.TEXTURE_2D, 0)

    return texture
}

create_renderer :: proc() -> Renderer {
    program, ok := gl.load_shaders_source(VERTEX_SHADER_SOURCE, FRAGMENT_SHADER_SOURCE)

    if !ok {
        fmt.println("renderer failed to load shaders")
    }

    vao: u32
    vbo: u32

    gl.GenVertexArrays(1, &vao);
    gl.BindVertexArray(vao);

    quad_vertices := []vec2{
        {-0.5, -0.5},
        { 0.5, -0.5},
        { 0.5,  0.5},

        { 0.5,  0.5},
        {-0.5,  0.5},
        {-0.5, -0.5},
    }

    gl.GenBuffers(1, &vbo);
    gl.BindBuffer(gl.ARRAY_BUFFER, vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(vec2) * len(quad_vertices), &quad_vertices[0], gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 2, gl.FLOAT, false, size_of(vec2), 0)

    pixels := []byte{
        0xFF, 0xFF, 0xFF, 0xFF,
    }

    white_texture := create_texture(1, 1, &pixels[0])

    return Renderer{
        shader = program,
        vao    = vao,
        vbo    = vbo,

        white_texture = white_texture
    }
}

destroy_renderer :: proc(renderer: ^Renderer) {
    gl.DeleteShader(renderer.shader)
    gl.DeleteVertexArrays(1, &renderer.vao)
    gl.DeleteBuffers(1, &renderer.vbo)

    renderer^ = Renderer{}
}

draw_quad :: proc(renderer: ^Renderer, position: vec2, size: vec2, color: vec4) {
    color_temp := color

    transform := linalg.identity_matrix(mat4)
    transform  = linalg.matrix_mul(transform, linalg.matrix4_translate(vec3{position.x, position.y, 0.0}))
    transform  = linalg.matrix_mul(transform, linalg.matrix4_scale(vec3{size.x, size.y, 1.0}))

    gl.UseProgram(renderer.shader)
    gl.BindVertexArray(renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, renderer.vbo)

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, renderer.white_texture.handle)

    projection_loc := gl.GetUniformLocation(renderer.shader, "u_projection")
    transform_loc  := gl.GetUniformLocation(renderer.shader, "u_transform")
    color_loc      := gl.GetUniformLocation(renderer.shader, "u_color")
    texture_loc    := gl.GetUniformLocation(renderer.shader, "u_texture")

    gl.UniformMatrix4fv(projection_loc, 1, false, &renderer.projection[0][0])
    gl.UniformMatrix4fv(transform_loc, 1, false, &transform[0][0])
    gl.Uniform4fv(color_loc, 1, &color_temp[0])
    gl.Uniform1f(texture_loc, 0)

    gl.DrawArrays(gl.TRIANGLES, 0, 6)
}

draw_quad_texture :: proc(renderer: ^Renderer, texture: Texture, position: vec2, size: vec2, color: vec4) {
    color_temp := color

    transform := linalg.identity_matrix(mat4)
    transform  = linalg.matrix_mul(transform, linalg.matrix4_translate(vec3{position.x, position.y, 0.0}))
    transform  = linalg.matrix_mul(transform, linalg.matrix4_scale(vec3{size.x, size.y, 1.0}))

    gl.UseProgram(renderer.shader)
    gl.BindVertexArray(renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, renderer.vbo)

    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D, texture.handle)

    projection_loc := gl.GetUniformLocation(renderer.shader, "u_projection")
    transform_loc  := gl.GetUniformLocation(renderer.shader, "u_transform")
    color_loc      := gl.GetUniformLocation(renderer.shader, "u_color")
    texture_loc    := gl.GetUniformLocation(renderer.shader, "u_texture")

    gl.UniformMatrix4fv(projection_loc, 1, false, &renderer.projection[0][0])
    gl.UniformMatrix4fv(transform_loc, 1, false, &transform[0][0])
    gl.Uniform4fv(color_loc, 1, &color_temp[0])
    gl.Uniform1f(texture_loc, 0)

    gl.DrawArrays(gl.TRIANGLES, 0, 6)
}