platform "echo-in-c"
    requires {} { main : List F32 -> List F32 }
    exposes []
    packages {}
    imports []
    provides [mainForHost]

mainForHost : List F32 -> List F32
mainForHost = \inputBuffer -> main inputBuffer
