package main

import "invaders"
import "invaders/platform"

main :: proc() {
    desc := platform.AppDesc{
        window_width  = 640,
        window_height = 320,
        window_title  = "INVADERS",

        init_cb   = invaders.game_init,
        update_cb = invaders.game_update,
    }

    platform.run(&desc)
}