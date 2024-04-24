hosted Effect
    exposes [
        Effect,
        after,
        map,
        always,
        forever,
        loop,
        getCurrentInBuffer,
        setCurrentOutBuffer,
    ]
    imports []
    generates Effect with [after, map, always, forever, loop]

getCurrentInBuffer : Effect (List F32)
setCurrentOutBuffer : List F32 -> Effect {}
