interface Core
    exposes [
        Program,
        getCurrentInBuffer,
        setCurrentOutBuffer,
    ]
    imports [InternalTask, Task.{ Task }, Effect.{ Effect }]

Program state : {
    init : Task state [],
    update : state -> Task state [],
}

getCurrentInBuffer : Task (List F32) []
getCurrentInBuffer =
    Effect.getCurrentInBuffer
    |> Effect.map \buffer -> Ok buffer
    |> InternalTask.fromEffect

setCurrentOutBuffer : List F32 -> Task {} []
setCurrentOutBuffer = \buffer ->
    Effect.setCurrentOutBuffer buffer
    |> Effect.map Ok
    |> InternalTask.fromEffect
