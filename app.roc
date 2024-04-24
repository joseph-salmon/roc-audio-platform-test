app "app"
    packages { pf: "platform/main.roc" }
    imports [
        pf.Task.{ Task },
        pf.Core,
    ]
    provides [main, Model] to pf

main = { init, update }

Model : { frameCount : I32, signal : List F32 }

init : Task Model []
init =
    Task.ok { frameCount: 0, signal: [] }

update : Model -> Task Model []
update = \model ->
    newCount = model.frameCount + 1
    inBuffer <- Core.getCurrentInBuffer |> Task.await
    # TODO: configure the host platform to retrieve the new signal from the model
    newSignal = audioCallback inBuffer
    Task.ok { model & frameCount: newCount, signal: newSignal }

# Currently just mono in, mono out
audioCallback : List F32 -> List F32
audioCallback = \input ->

    testOutSigFunc input

# A basic in->out signal function
# testSigFunc : List F32 -> List F32
# testSigFunc = \input ->
#     List.map input (\sample -> sample * 0.9)

# A basic out-only signal function
testOutSigFunc : List F32 -> List F32
testOutSigFunc = \_ ->
    List.map ramp mapSine

# Generate a sine table
sampleRate : F32
sampleRate = 44100

frequency : F32
frequency = 6000

pi : F32
pi = 3.141592653589793

ramp : List F32
ramp = List.range { start: At 0, end: At 511 }

mapSine : F32 -> F32
mapSine = \src ->
    twoPIdivSampleRate = 2.0 * pi / sampleRate
    Num.sin (twoPIdivSampleRate * frequency * src)

