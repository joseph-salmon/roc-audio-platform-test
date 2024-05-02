app "app"
    packages { pf: "platform/main.roc" }
    imports [
        pf.Task.{ Task },
        pf.Core,
    ]
    provides [main, Model] to pf

Model : {
    sinePhase : F32,
}

CycleOut : {
    outBuffer : List F32,
    nextPhase : F32,
}

main = { init, update }

# Constants
sampleRate = 44100.00
bufferSize = 256
pi : F32
pi = 3.141592653589793
twoPi = 2.0 * pi

init : Task Model []
init =
    Task.ok {
        sinePhase: 0,
    }

update : Model -> Task Model []
update = \model ->
    # inBuffer <- Task.await Core.getCurrentInBuffer

    # dbg "CYCLE"

    # dbg model.sinePhase
    { outBuffer, nextPhase } = sine 200 model.sinePhase

    # dbg nextPhase

    scaledSine = List.map outBuffer (\samp -> samp * 0.5)
    {} <- Task.await (Core.setCurrentOutBuffer scaledSine)

    Task.ok
        { model &
            sinePhase: nextPhase,
        }

# A basic sinewave function
sine : F32, F32 -> CycleOut
sine = \freq, phase ->
    generateSineWave [] freq phase

generateSineWave : List F32, F32, F32 -> CycleOut
generateSineWave = \state, freq, phase ->

    # dbg phase

    phaseIncrement = (freq / sampleRate)

    sample = phase * twoPi |> Num.sin

    nextState = List.append state sample
    # dbg List.len nextState
    nextPhase =
        if
            phase > 0.99
        then
            phase - 0.99
        else
            phase + phaseIncrement

    # dbg nextPhase

    if
        List.len nextState < bufferSize
    then
        generateSineWave nextState freq nextPhase
    else
        # This is the final output
        { outBuffer: nextState, nextPhase: nextPhase }
