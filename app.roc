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
        sinePhase: 0.0,
        signal: [],
    }

update : Model -> Task Model []
update = \model ->
    newCount = model.frameCount + 1
    inBuffer <- Task.await Core.getCurrentInBuffer
    { out, phase } = audioCallback model inBuffer
    {} <- Task.await (Core.setCurrentOutBuffer out)
    dbg "Phase: ${phase}"

    Task.ok {
        frameCount: newCount,
        sinePhase: phase,
        signal: out,
    }

# Currently just mono in, mono out
audioCallback : Model, List F32 -> CycleOut
audioCallback = \model, _ ->
    sine model

# A basic sinewave function
sine : Model -> CycleOut
sine = \model ->
    generateSineWave [] 100 model.sinePhase 0

generateSineWave : List F32, F32, F32, U32 -> CycleOut
generateSineWave = \state, freq, phase, step ->
    sample = Num.sin (phase * 2 * pi) * 0.5
    nextPhase = phase + (freq / sampleRate)
    nextStep = step + 1
    if
        step < (buffer)
    then
        {
            out: List.append (generateSineWave state freq nextPhase nextStep).out sample,
            phase: nextPhase,
        }
    else
        {
            out: state,
            phase: nextPhase,
        }

