askForFile :- 
  nl, write('\tEnter file name (with dot at the end): '),read(N0),
  term_to_atom(N0,N),
    [N],
    write('loaded file'), nl.


run :-
    runAux,
    mainRunUntilStable.

runCycles(N) :-
    runAux,
    runInit,
    mainRunCycleMultiple(2).

    
runAux :-
    ['generateArcs.pl'],
    askForFile,
    normTowns,
    [aco].

