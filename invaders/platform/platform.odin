package platform

import "core:fmt"
import "core:os"

import "vendor:glfw"
import gl "vendor:OpenGL"

AppDesc :: struct {
    window_width:  u32,
    window_height: u32,
    window_title:  cstring,

    init_cb:     proc(),
    shutdown_cb: proc(),
    update_cb:   proc(delta_time: f32),
}

GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3

@(private = "file")
window:   glfw.WindowHandle

@(private = "file")
app_desc: AppDesc

@(private = "file")
last_key_state:    [256]bool

@(private = "file")
current_key_state: [256]bool

@(private = "file")
last_time: f32

@(private = "file")
delta_time: f32

key_down :: proc(key: i32) -> bool {
    if key < 0 || key >= len(current_key_state) {
        return false
    }

    return current_key_state[key]
}

key_pressed :: proc(key: i32) -> bool {
    if key < 0 || key >= len(current_key_state) {
        return false
    }

    return current_key_state[key] && !last_key_state[key]
}

key_released :: proc(key: i32) -> bool {
    if key < 0 || key >= len(current_key_state) {
        return false
    }

    return !current_key_state[key] && last_key_state[key]
}

window_size :: proc() -> (i32, i32) {
    return glfw.GetWindowSize(window)
}

run :: proc(desc: ^AppDesc) {
    init_window(desc)

    defer glfw.DestroyWindow(window)
    defer glfw.Terminate()

    init_opengl()

    if desc.init_cb != nil {
        desc.init_cb()
    }

    for !glfw.WindowShouldClose(window) {
        now_time := f32(glfw.GetTime())

        if last_time != 0.0 {
            delta_time = now_time - last_time
        }

        last_time = now_time

        last_key_state = current_key_state
        glfw.PollEvents()

        if desc.update_cb != nil {
            desc.update_cb(delta_time)
        }

        glfw.SwapBuffers(window)
    }

    if desc.shutdown_cb != nil {
        desc.shutdown_cb()
    }
}

@(private = "file")
init_window :: proc(desc: ^AppDesc) {
    if !glfw.Init() {
        //TODO: handle this properly
        fmt.println("glfw init failed")
        os.exit(-1)
    }

    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    window = glfw.CreateWindow(i32(desc.window_width), i32(desc.window_height), "INVADERS", nil, nil)

    if window == nil {
        //TODO: handle this properly
        fmt.println("glfw create window failed")
        os.exit(-1)
    }

    glfw.SetKeyCallback(window, window_key_callback)
    glfw.SetFramebufferSizeCallback(window, framebuffer_size_callback)

    glfw.MakeContextCurrent(window);
    glfw.SwapInterval(0);
}

@(private = "file")
init_opengl :: proc() {
    set_proc_address :: proc(p: rawptr, name: cstring) {
        (cast(^rawptr)p)^ = rawptr(glfw.GetProcAddress(name))
    }

    gl.load_up_to(GL_VERSION_MAJOR, GL_VERSION_MINOR, set_proc_address)
}

@(private = "file")
window_key_callback :: proc "cdecl" (window: glfw.WindowHandle, key: i32, scancode: i32, action: i32, mods: i32) {
    if key < 0 || key >= len(current_key_state) {
        return
    }

    current_key_state[key] = (action == glfw.PRESS) || (action == glfw.REPEAT)
}

@(private = "file")
framebuffer_size_callback :: proc "cdecl" (window: glfw.WindowHandle, width: i32, height: i32) {
    gl.Viewport(0, 0, width, height)
}