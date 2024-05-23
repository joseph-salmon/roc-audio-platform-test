app [main, Model] { pf: platform "platform/main.roc" }

import pf.Task exposing [Task]
import pf.Core

Model : {
    sinePhase : F32,
}

CycleOut : {
    buffer : List F32,
    phase : F32,
}

main = { init, update }

# Constants
sampleRate = 44100
bufferSize = 1024
twoPi = 2 * Num.pi

init : Task Model []
init =
    Task.ok {
        sinePhase: 0,
    }

update : Model -> Task Model []
update = \model ->

    { buffer, phase } = generateSineWave [] 100 model.sinePhase
    scaledSine = List.map buffer (\samp -> samp * 0.5)
    {} <- Task.await (Core.setCurrentOutBuffer scaledSine)

    Task.ok
        { model &
            sinePhase: phase,
        }

# A basic sinewave function
generateSineWave : List F32, F32, F32 -> CycleOut
generateSineWave = \state, freq, phase ->
    phaseIncrement = (freq / sampleRate)
    sample = Num.sin (phase * twoPi)
    nextState = List.append state sample
    nextPhase =
        if
            phase > 1
        then
            0
        else
            phase + phaseIncrement

    if
        List.len nextState < bufferSize
    then
        generateSineWave nextState freq nextPhase
    else
        { buffer: nextState, phase: nextPhase }
