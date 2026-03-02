/* Jens Hartmann, Ant Colony Optomisation Algorithmus 28.02.2021
Benutzung: siehe README.txt*/

:- writeln("\nImported arcs.pl.\n"), ['arcs.pl'].
/* Die Begriffe wurden verwendet im Sinne des usprünglichen Ant System Paper von
 Dorigo, Maniezzo, Colorni von 1996.

 Es werden die folgenden dynamischen globalen Variablen mittels assert 
verwendet:
 o arcPref : Preferenz ist die unnormierte Wahrscheinlichkeit einer Kante.
 o arcTau : beschreibt die Intensität einer edge, diese werden nach dem Lauf 
            einer Ameise aktualisiert (in runAnt), haben jedoch erst Einfluss 
            im nächsten Cycle. 
 o bestSol : Pfad und Kosten der derzeit besten gefunden Lösung.
 */

edgeC(X, Y, Weight) :- arcCost(X, Y, Weight) ; arcCost(Y, X, Weight).
edgeP(X, Y, Pref) :- arcPref(X, Y, Pref) ; arcPref(Y, X, Pref).
edgeT(X, Y, Tau) :- arcTau(X, Y, Tau) ; arcTau(Y, X, Tau).

allArcs(XYs) :- findall(X:Y, arcCost(X, Y, _), XYs).
/******************************************************************************
Parameter settings*/
alpha(1). 
beta(5).
persistance(0.9). % Verdampfen der Trails
constantQ(100). % Faktor für Tau
totalAnts(100). % M Ants per Cycle.
stableSolCountForLoopStop(10).
/******************************************************************************
Teil 1: Boilerplate*/
mainRunUntilStable :-
    runInit, runUntilStable, writeSol, !.

/* Mehrere Cycles mit anschließender Ausgabe der Lösung.
Kann nicht ohne zuvor initialisierter arcsPref und arcsTau verwendet werden
(durch Aufruf von runInit) */
mainRunCycleMultiple(Count) :-
    runCycleMultiple(Count), writeSol, !.

/* Eine vorgegebene Anzahl an Cycles wir ausgeführt, wurde eine bessere Lösung
gefunden, dann wird die Schleife wiederholt*/
runUntilStable :-
    bestSol(_, OldCost),
    stableSolCountForLoopStop(Count),
    runCycleMultiple(Count),
    reRun(OldCost).

/* Überprüft, ob die Aktuelle lösung eine Verbesserung ist und startet einen
erneuten run. Andernfalls wird keine weitere Berechnung mit den Ameisen 
durchgeführt. */
reRun(OldCost) :-
    writeln("   reRun?"), 
    bestSol(_, NewCost),
    write("   OldCost: "), write(OldCost),
    write(" NewCost: "), writeln(NewCost),
    NewCost < OldCost, runUntilStable.
reRun(_). % In Case NewCost >= OldCost.

runCycleMultiple(0).
runCycleMultiple(Count) :-
    Count1 is Count -1, runCycle, runCycleMultiple(Count1).

/* Tau evaporation wird ausgeführt. Alle M verschiedenen Ameisen legen einen 
kompletten Pfad zurück. Anschließend werden die preferenzes neu berechnet, um im
 nächsten Zyklus verwendet zu werden */
runCycle :-
    allArcs(XYs), evaporateT(XYs),
    totalAnts(M), runAllAnts(M),
    updateP(XYs).

runAllAnts(0). % :- writeln("All Ants are finished. Cycle Ended").
runAllAnts(Count) :- 
    runAnt, Count1 is Count - 1,
    runAllAnts(Count1).

/* Für eine Ameise mit zufälligen Startpunkt wir ein Pfad ermittelt.
Anschließend werden die Pheromone aktualisiert, 
und sie werden nur hier aktualisiert */
runAnt :-
    nodes(Nodes),
    random_select(Start, Nodes, Rest),    
    path([Start|Rest], Path, C), updateBestSol(Path, C),
    last(Path, Last), updateT(Start, Last, C), updateT(Path, C).
%    write("   Path: "), write(Path), write("   Cost: "), writeln(C).    

/******************************************************************************
Teil 2: Berechnen des Pfades mittels der Preferenzen.
Die Pheromone werden hier nicht benötigt.*/

/* path/3 wuerfelt einen Pfad aus und gibt die Kosten zurueck:
 Beispiel: path([a,b,c,d,e], P, C).
 P = [a, c, d, b, e]; C = 34.
 X ist Startwert, die Reihenfolge der anderen Unvisited elemente ist egal */
path([X|Unvisited], Path, SumCost0) :-
	path(X, Unvisited, Path, SumCost1),
	% Kosten um den Pfad abzuschließen:
	last(Path, Last),
	edgeC(X, Last, C),
	SumCost0 is SumCost1 + C,
	!.

% Hilfsfunktion: path/4 wuerfelt einen geschlossenen Pfad aus und berechnet die Kosten:
path(X, [Y], [X,Y], C) :- edgeC(X, Y, C).
path(X, Unvisited0, [X|Path], SumCost0) :-
        choice(X, Unvisited0, Y),
        edgeC(X, Y, C),    
	selectchk(Y, Unvisited0, Unvisited1),
	path(Y, Unvisited1, Path, SumCost1),
	SumCost0 is SumCost1 + C.

/* Wählt einen Unvisited-Knoten als Ziel.*/
choice(X, Unvisited, Y) :-
%NPs: Node: Tupelliste von Knotenlabels und Preferenzen von unbesuchten Nachbarn
    setof(N:P, (member(N, Unvisited), edgeP(X, N, P)), NPs),
    sumP(NPs, 0, Pges),
    random(0, Pges, PTarget),
    seekNode(NPs, PTarget, 0, Y).

% Summe der Preferences:
sumP([], Pges, Pges).
sumP([_:P|NPs], AccIn, Pges) :-
    AccOut is AccIn + P, sumP(NPs, AccOut, Pges).

%  des als nächstes zu besuchenden Knoten N
seekNode([],_,_,_) :- false. % Should never occur
seekNode([N:P|_], PTarget, Acc, N) :- PTarget < Acc + P, !.
seekNode([_:P|NPs], PTarget, AccIn, Y) :-
    Acc1 is AccIn + P, seekNode(NPs, PTarget, Acc1, Y).

/******************************************************************************
Teil 3 Initialisieren und Updaten von arcTau, arcPref und bestSol. */

/* runInit/0 Initialisierung der Arcs und von bestSol.*/ 
runInit :-
    allArcs(XYs), runInit(XYs),
    assert(bestSol([], 2^31-1)).

/* runInit/1 Initialisieren der Pheromonone  und Preferences von allen Edges.
Die Pheromone werden alle mit der selben Konstante initialisiert, der erste
Cycle entspricht dem Greedy Algorithmus.*/
runInit([]).
runInit([X:Y|XYs]) :- assert(arcTau(X, Y, 1)), updateP(X, Y), runInit(XYs).

/* updateT/1 Tau von allen Edges, die Teil des Pfades einer Ameise waren, werden
aktualisiert.*/
updateT([_], _).
updateT([X, Y|Path], C) :- updateT(X, Y, C), updateT([Y|Path], C).

/* updateT/3 Aktualisiert eine einzige Edge, welche Teil des Pfades einer 
einzelnen Ameise war.*/
updateT(X, Y, C) :-
    edgeT(X, Y, TauOld), constantQ(Q),
    TauNew is TauOld + Q/C,
    assertT(X, Y, TauNew).

evaporateT([]).
evaporateT([X:Y|XYs]) :-
    edgeT(X, Y, TauOld), persistance(P),
    TauNew is TauOld * P, assertT(X, Y, TauNew),
    evaporateT(XYs).

/* Überschreibt eine intensity mit einen neuen Wert für Tau.*/
assertT(X, Y, TauNew) :-			
    retractall(arcTau(X, Y, _)), retractall(arcTau(Y, X, _)),
    assert(arcTau(X, Y, TauNew)).

/* updateP/1 Aktualisieren der Preference einer edge mittels der zuvor berechneteten Trail
 intensity Tau. Die Preferences sind nicht normiert. */
updateP([]).
updateP([X:Y|XYs]) :- updateP(X, Y), updateP(XYs).

/* updateP/2 */
updateP(X, Y) :-
    alpha(A), beta(B), 
    edgeT(X, Y, Tau), edgeC(X, Y, C),
    P is Tau^A * (100/C)^B,
    retractall(arcPref(X, Y, _)), assert(arcPref(X, Y, P)).    

/* Ist die neu gefundene Lösung eine Verbesserung, so wird sie gespeichert.*/
updateBestSol(_, C) :- bestSol(_, Cbest), C >= Cbest.
updateBestSol(Path, C) :-
    bestSol(_, Cbest), C < Cbest,
    write("   UPDATE Best Cost: "), write(Cbest),
    write(" ---> "), writeln(C), writeln(""), 
    retractall(bestSol(_,_)), assert(bestSol(Path, C)).

/******************************************************************************
Teil 5a: Hilfsfunktionen zur Ausgabe mit Dot File und für Listen*/

round(X, Y, D) :- Z is X * 10^D, round(Z, ZA), Y is ZA / 10^D.

% Pretty Print von Listen
pp([H|T], I) :- !, J is I+3, pp(H, J), ppx(T, J),nl.
pp(X, I):- tab(I), write(X), nl.
ppx([],_).
ppx([H|T], I):-pp(H, I),ppx(T, I).

/* Erstellt ein Dotfile des Graphen mit den aktuellen Kosten, Preferences und 
Tau.*/
writeDotGraph :-
    tell('ausgabeTsp.dot'),
    writeln("digraph G {\nnode [ordering=\"out\"]"),
    writeln("node [shape=circle, height=0.25, fixedsize=\"true\"]"),    
    nodes(Nodes), dotNode(Nodes),
    allArcs(XYs), dotEdge(XYs),
    write("}"),
    told, !.

dotNode([]).    
dotNode([N|Nodes]) :-
    write(N), write("[label=\""), write(N), writeln("\"]"),
    dotNode(Nodes).

dotEdge([]).
dotEdge([X:Y|XYs]) :-
    edgeT(X, Y, T), T < 3, !,
    dotEdge(XYs).
dotEdge([X:Y|XYs]) :-
    edgeC(X, Y, C), edgeT(X, Y, T), edgeP(X, Y, P),
    round(T, TR, 3), round(P, PR, 3), CR is round(C),
    write(X), write(" -> "), write(Y), write(" [arrowhead=none,label=\""),
    write("C:"), writeln(CR),
    write("T:"), writeln(TR),
    write("P:"), writeln(PR),    
    writeln("\"]"),
    dotEdge(XYs).

/******************************************************************************
Teil 5b: Standardmäßige Ausgebe der Lösung. */

/* Start mit anschließender Ausgebe der Lösung. Kann wiederholt aufgerufen 
werden, um die ausgegebene Lösung zu verbessern. */
writeSol :-
    bestSol(SolPath, CostNormed),
    ['townNorm.pl'],    
    normXY(NormXY),
    Cost1 is (NormXY * CostNormed/100),
    round(Cost1, SolCostOut, 2),
    write("   Denormed Costs: "), writeln(SolCostOut),
    write("   Solution Path: "), writeln(SolPath),
    writeSolToFile, !. 

/* Der Lösungspfad wird ausgegeben, um mittels Gnuplot anzeigt zu werden. 
Anschließend werden die Pheromone ausgegeben. */
writeSolToFile :-
    bestSol(Path, _),
    last(Path, Last), % Der Startknoten kommt zweimal im .dat vor
    tell('tsp_solution.dat'),
    auxSol([Last|Path]),    
    told,
    writeTau, !.

auxSol([]).
auxSol([N|NS]) :-
    townN(N, XCord, YCord),
    write(N), write(" "), write(XCord), write(" "), writeln(YCord),
    auxSol(NS).

/* Ausgeben der Pheromone für Gnuplot.*/
writeTau :-
    tell('tsp_tau.dat'),    
    findall(Tau, arcTau(_, _, Tau), TauS),
    max_member(MaxTau, TauS),
    round(MaxTau, MaxOut, 3),
    write("Maximum T value: "), writeln(MaxOut),
    findall(X:Y:T, arcTau(X,Y,T), XYTs),
    writeArc(XYTs, MaxTau), told.

writeArc([], _).
writeArc([X:Y:T|XYTs], MaxTau) :-    
    TauNorm is 1 + round(100*T/MaxTau),
    writeTown(X), writeTown(Y),
    write("   "), writeln(TauNorm),
    writeArc(XYTs, MaxTau).

writeTown(N) :-    
    townN(N, XCord, YCord),
    round(XCord, XCordR, 3),
    round(YCord, YCordR, 3),    
    write(XCordR), write(" "),
    write(YCordR), write(" ").
	
	
