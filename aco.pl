:- ['arcs.pl'].
/* Die Begriffe wurden verwendet im Sinne des usprünglichen Ant System Paper von
 Dorigo, Maniezzo, Colorni von 1996. */

/* prob und int werden als globale Variablen mittels assert angelegt (Teil 3).
 int beschreibt die Intensität der Trails, diese werden nach dem Lauf einer 
Ant aktualisiert (runAnt), haben jedoch erst Einfluss auf den nächsten Cycle. */
edgeC(X, Y, Weight) :- arc(X, Y, Weight) ; arc(Y, X, Weight).
edgeP(X, Y, Pref) :- pref(X, Y, Pref) ; pref(Y, X, Pref).
edgeT(X, Y, Tau) :- int(X, Y, Tau) ; int(Y, X, Tau).

/******************************************************************************
Parameter settings*/
alpha(1). 
beta(5).
persistance(0.5). % Verdampfen der Trails
constantQ(100). % Faktor für Tau
totalAnts(100). 

/******************************************************************************
Teil 1: Boilerplate*/

/* Initialisierung mit Anschließenden start.*/ 
startWInit(SolPath, SolCost) :-
    findall(X:Y, arc(X, Y, _), XYs), initTP(XYs),
    assert(bestSol([], 2^31-1)),
    start(SolPath, SolCost), !.

/* Start mit anschließenden printen der Lösung. Kann wiederholt aufgerufen 
werden, um die ausgegebene Lösung zu verbessern. */
start(SolPath, SolCost) :-
    runACO,
    printSol(SolCost),
    bestSol(SolPath, _),!.

/**/
runACO :-
    bestSol(_, OldCost),
    runCycleMultiple(5),
    reRun(OldCost).

/* Überprüft, ob die Aktuelle lösung eine Verbesserung ist und startet einen
erneuten run. Andernfalls wird keine weitere Berechnung mit den Ameisen 
durchgeführt.*/
reRun(OldCost) :-
    writeln("   reRun?"), 
    bestSol(_, NewCost),
    write("   OldCost: "), write(OldCost),
    write(" NewCost: "), writeln(NewCost),
    NewCost < OldCost, runACO.
reRun(_). % todo raus?

runCycleMultiple(0) :- writeln("All Ants are finished. Cycle Ended").
runCycleMultiple(Count) :-
    Count1 is Count -1, runCycle, runCycleMultiple(Count1).

/* Tau evaporation wird ausgeführt. Alle M verschiedenen Ameisen legen einen 
kompletten Pfad zurück. Anschließend werden die preferenzes neu berechnet, um im
 nächsten Zyklus verwendet zu werden */
runCycle :-
    findall(X:Y, arc(X, Y, _), XYs), evaporateT(XYs),
    totalAnts(M), runAllAnts(M),
    mapUpdateP(XYs).

runAllAnts(0).
runAllAnts(Count) :- 
    runAnt, Count1 is Count -1,
    runAllAnts(Count1).

/* Für eine Ameise mit zufälligen Startpunkt wir ein Pfad ermittelt.
Anschließend werden die Pheromone aktualisiert, 
und sie werden nur hier aktualisiert */
runAnt :-
    nodes(Nodes),
    random_select(Start, Nodes, Rest),    
    path([Start|Rest], Path, C), updateC(Path, C),
    last(Path, Last), updateT(Start, Last, C), mapUpdateT(Path, C).
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

% Hilfsfunktion: path/4 wuerfelt einen Pfad aus und berechnet die Kosten:
path(X, [Y], [X,Y], C) :- edgeC(X, Y, C).
path(X, Unvisited0, [X|Path], SumCost0) :-
        choice(X, Unvisited0, Y),
        edgeC(X, Y, C),    
	selectchk(Y, Unvisited0, Unvisited1),
	path(Y, Unvisited1, Path, SumCost1),
	SumCost0 is SumCost1 + C.

/* Wählt einen Unvisited-Knoten als Ziel.
 NPs: Node: Preferenzliste von unbesuchten Nachbarn */
choice(X, Unvisited, Y) :-
    setof(N:P, (member(N, Unvisited), edgeP(X, N, P)), NPs),
    sumP(NPs, 0, Pges),
    random(0, Pges, Tar),
    roll(NPs, Tar, 0, Y).
/*    write("   Unvisited: "), writeln(Unvisited0),    
    writeln("   NPs: "), pp(NPs,0),
    write("   SumP: "), writeln(Pges),
    write("   Tar: "), writeln(Tar),           
    write("   Choosen: "), writeln(Y), writeln(""). */

% Summe der Preferences:
sumP([], Pges, Pges).
sumP([_:P|NPs], AkkIn, Pges) :-
    AkkOut is AkkIn + P, sumP(NPs, AkkOut, Pges).

% Auswuerfeln des als nächstes zu besuchenden Knoten N
roll([],_,_,_) :- false.
roll([N:P|_], Tar, Akk, N) :- Tar < Akk + P, !.
roll([_:P|NPs], Tar, AkkIn, Y) :-
    AkkOut is AkkIn + P, roll(NPs, Tar, AkkOut, Y).

/******************************************************************************
Teil 3 Initialisieren und Updaten von Tau, Preference und Cost. */

/* Initialisieren der Pheromonone und Preferences von allen Edges.*/
initTP([]).
initTP([X:Y|XYs]) :- assert(int(X, Y, 1)), updateP(X, Y), initTP(XYs).

/* Tau von allen Edges, die Teil des Pfades einer Ameise waren, werden 
aktualisiert.*/
mapUpdateT([_], _).
mapUpdateT([X, Y|Path], C) :- updateT(X, Y, C), mapUpdateT([Y|Path], C).

/* Aktualisiert eine einzige Edge, welche Teil des Pfades einer einzelnen Ameise
 war.*/
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
    retractall(int(X, Y, _)), retractall(int(Y, X, _)),
    assert(int(X, Y, TauNew)).

mapUpdateP([]).
mapUpdateP([X:Y|XYs]) :- updateP(X, Y), mapUpdateP(XYs).

/* Aktualisieren der Preference einer edge mittels der zuvor berechneteten Trail
 intensity Tau. Die Preferences sind nicht normiert. */
updateP(X, Y) :-
    alpha(A), beta(B), 
    edgeT(X, Y, Tau), edgeC(X, Y, C),
    P is Tau^A * (100/C)^B,
    retractall(pref(X, Y, _)), assert(pref(X, Y, P)).    

/* Ist die neu gefundene Lösung eine Verbesserung, so wird sie gespeichert.*/
updateC(_, C) :- bestSol(_, Cbest), C >= Cbest.
updateC(Path, C) :-
    bestSol(_, Cbest), C < Cbest,
    write("   UPDATE Best Cost: "), write(Cbest),
    write(" ---> "), writeln(C), writeln(""), 
    retractall(bestSol(_,_)), assert(bestSol(Path, C)).

/******************************************************************************
Teil 5: Hilfsfunktionen zur Ausgabe*/

round(X, Y, D) :- Z is X * 10^D, round(Z, ZA), Y is ZA / 10^D.

% Pretty Print von Listen
pp([H|T], I) :- !, J is I+3, pp(H, J), ppx(T, J),nl.
pp(X, I):- tab(I), write(X), nl.
ppx([],_).
ppx([H|T], I):-pp(H, I),ppx(T, I).

/* Erstellt ein Dotfile des Graphen mit den aktuellen Kosten, Preferences und 
Tau.*/
dotGraph :-
    tell('ausgabeTsp.dot'),
    writeln("digraph G {\nnode [ordering=\"out\"]"),
    writeln("node [shape=circle, height=0.25, fixedsize=\"true\"]"),    
    nodes(Nodes), dotNode(Nodes),
    findall(X:Y, arc(X, Y, _), XYs), dotEdge(XYs),
    write("}"),
    told, !.

dotNode([]).    
dotNode([N|Nodes]) :-
    write(N), write("[label=\""), write(N), writeln("\"]"),
    dotNode(Nodes).

dotEdge([]).
/*
dotEdge([X:Y|XYs]) :-
    edgeT(X, Y, T), T < 3, !,
    dotEdge(XYs). */
dotEdge([X:Y|XYs]) :-
    edgeC(X, Y, C), edgeT(X, Y, T), edgeP(X, Y, P),
    round(T, TR, 3), round(P, PR, 3), CR is round(C),
    write(X), write(" -> "), write(Y), write(" [arrowhead=none,label=\""),
    write("C:"), writeln(CR),
    write("T:"), writeln(TR),
    write("P:"), writeln(PR),    
    writeln("\"]"),
    dotEdge(XYs).





/* Die Kosten werden entnormiert und der Lösungspfad wird ausgegeben, um als
Gnuplot anzeigen zu werden.*/
printSol(CostOut) :-
    ['townNorm.pl'], normXY(NormXY),
    bestSol(Path, CostNormed),
    Cost1 is (NormXY * CostNormed/100),
    round(Cost1, CostOut, 2),
    last(Path, Last), % Der Startknoten kommt zweimal im .dat vor
    tell('tsp_solution.dat'),
    auxSol([Last|Path]),
    told, !.

auxSol([]).
auxSol([N|NS]) :-
    townN(N, XCord, YCord),
    write(N), write(" "), write(XCord), write(" "), writeln(YCord),
    auxSol(NS).
