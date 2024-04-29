app "app"
    packages { pf: "platform/main.roc" }
    imports [
        pf.Task.{ Task },
        pf.Core,
    ]
    provides [main, Model] to pf

Model : {
    frameCount : U32,
    sinePhase : F32,
    signal : List F32,
}

CycleOut : {
    outBuffer : List F32,
    nextPhase : F32,
}

main = { init, update }

# Constants
sampleRate = 44100.00
bufferSize = 512
pi = 3.141592653589793
twoPi = 2.0 * pi

init : Task Model []
init =
    Task.ok {
        frameCount: 0,
        sinePhase: 0,
        signal: [],
    }

update : Model -> Task Model []
update = \model ->
    # inBuffer <- Task.await Core.getCurrentInBuffer

    { outBuffer, nextPhase } = sine 440 model.sinePhase

    scaledSine = List.map outBuffer (\samp -> samp * 0.5)
    {} <- Task.await (Core.setCurrentOutBuffer scaledSine)

    Task.ok
        { model &
            sinePhase: nextPhase,
            signal: outBuffer,
        }

# A basic sinewave function
sine : F32, F32 -> CycleOut
sine = \freq, phase ->

    generateSineWave [] freq phase 0

generateSineWave : List F32, F32, F32, U32 -> CycleOut
generateSineWave = \state, freq, phase, step ->

    sample = phase * twoPi |> Num.sin

    nextState = List.append state sample
    nextStep = step + 1
    phinc = (freq / sampleRate)
    nextPhase =
        if
            phase > (1.0 - phinc)
        then
            phase - (1.0 - phinc)
        else
            phase + phinc

    if
        step < (bufferSize - 1)
    then
        {
            outBuffer: (generateSineWave nextState freq nextPhase nextStep).outBuffer,
            nextPhase: nextPhase,
        }
    else
        # This is the final
        {
            outBuffer: nextState,
            nextPhase: nextPhase,
        }

# mul : List F32, F32 -> List F32
# mul = \sig, amount ->
#     sig |> List.map (\samp -> samp * amount)

