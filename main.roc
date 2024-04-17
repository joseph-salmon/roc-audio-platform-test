app "platformTest"
    packages { pf: "platform/main.roc" }
    imports []
    provides [main] to pf

main : List F32 -> List F32
main = \inputBuffer ->
    List.map inputBuffer (\sample -> sample)
