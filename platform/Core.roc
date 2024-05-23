module [Program, getCurrentInBuffer, setCurrentOutBuffer]
import InternalTask
import Task exposing [Task]
import Effect

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
