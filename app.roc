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
    out : List F32,
    phase : F32,
}

main = { init, update }

# Constants
sampleRate = 44100
buffer = 256
pi = 3.141592653589793

init : Task Model []
init =
    Task.ok {
        frameCount: 0,
        sinePhase: 0,
        signal: [],
    }

update : Model -> Task Model []
update = \model ->
    newCount = model.frameCount + 1
    # inBuffer <- Task.await Core.getCurrentInBuffer
    { out, phase } = sine 440 model.sinePhase
    scalesSine = mul out 0.5
    {} <- Task.await (Core.setCurrentOutBuffer scalesSine)

    Task.ok {
        frameCount: newCount,
        sinePhase: phase,
        signal: out,
    }

# A basic sinewave function
sine : F32, F32 -> CycleOut
sine = \freq, phase ->

    generateSineWave [] freq phase 0

generateSineWave : List F32, F32, F32, U32 -> CycleOut
generateSineWave = \state, freq, phase, step ->
    omega = 2 * pi * freq
    sample = Num.sin phase
    nextStep = step + 1
    nextPhase =
        if
            phase > 2 * pi
        then
            phase - 2 * pi
        else
            phase + (omega / sampleRate)

    if
        step < (buffer)
    then
        {
            out: List.append (generateSineWave state freq nextPhase nextStep).out sample,
            phase: nextPhase,
        }
    else
        # This is the final
        {
            out: state,
            phase: nextPhase,
        }

mul : List F32, F32 -> List F32
mul = \sig, amount ->
    sig |> List.map (\samp -> samp * amount)
