package invaders

EntityHandle :: struct {
    index:      u32,
    generation: u32,
}

EntityTag :: enum {
    
}

EntityFlags :: enum {
    VISIBLE    = 1 << 0,
    COLLIDABLE = 1 << 1,
    DAMAGABLE  = 1 << 2, 
}

Entity :: struct {
    handle: EntityHandle,
    flags:  EntityFlags,

    position: vec2,
    size:     vec2,
    color:    vec4,

    health: f32,
}

EntityEntry :: struct {
    index:      u32,
    generation: u32,
    in_use:     bool,
}

EntityManager :: struct {
    entries:  [dynamic]EntityEntry,
    entities: [dynamic]Entity,
}

create_entity_manager :: proc(capacity: u32) -> EntityManager {
    return EntityManager{
        entries  = make([dynamic]EntityEntry, 0, capacity),
        entities = make([dynamic]Entity, 0, capacity),
    }
}

destroy_entity_manager :: proc(manager: ^EntityManager) {
    delete(manager.entries)
    delete(manager.entities)
}

create_entity :: proc(manager: ^EntityManager) -> EntityHandle {
    index := -1

    for i in 0..<len(manager.entries) {
        if !manager.entries[i].in_use {
            index = i
        }
    }

    if index == -1 {
        index = len(manager.entries)
        append(&manager.entries, EntityEntry{generation=1})
    }

    manager.entries[index].index  = u32(len(manager.entities))
    manager.entries[index].in_use = true

    handle := EntityHandle{
        index      = u32(index),
        generation = manager.entries[index].generation,
    }

    append(&manager.entities, Entity{handle=handle})

    return handle
}

destroy_entity :: proc(manager: ^EntityManager, handle: EntityHandle) {
    entry := &manager.entries[handle.index]

    if entry.generation != handle.generation {
        return
    }

    entry.generation += 1
    entry.in_use = false

    last_index := len(manager.entities) - 1
    swap_index := entry.index

    if swap_index != u32(last_index) {
        manager.entities[swap_index] = manager.entities[last_index]

        swapped_handle := manager.entities[swap_index].handle
        manager.entries[swapped_handle.index].index = swap_index
    }

    pop(&manager.entities)
}

get_entity :: proc(manager: ^EntityManager, handle: EntityHandle) -> ^Entity {
    entry := &manager.entries[handle.index]

    if entry.generation != handle.generation {
        return nil
    }

    return &manager.entities[entry.index]
}