:- ['arcs.pl'].

edgeC(X, Y, Weight) :- arc(X, Y, Weight) ; arc(Y, X, Weight).
edgeP(X, Y, Prob) :- prob(X, Y, Prob) ; prob(Y, X, Prob).
edgeT(X, Y, Tau) :- int(X, Y, Tau) ; int(Y, X, Tau).
/*****************************************************************************/

alpha(1).
beta(5).
persistance(0.5).
constantQ(100).

totalAnts(100).

/*****************************************************************************/
% NPs: Node:Probability list of unvisited neighours:
choice(X, Unvisited0, Y) :-
    setof(N:P, (member(N, Unvisited0), edgeP(X, N, P)), NPs),
    sumP(NPs, 0, Pges),
    random(0, Pges, Tar),
    roll(NPs, Tar, 0, Y).
%    write("   Unvisited: "), writeln(Unvisited0),    
%    writeln("   NPs: "), pp(NPs,0),
%    write("   SumP: "), writeln(Pges),
%    write("   Tar: "), writeln(Tar),           
%    write("   Choosen: "), writeln(Y), writeln("").

% Summe der Propabilities:
sumP([], Pges, Pges).
sumP([_:P|NPs], AkkIn, Pges) :-
    AkkOut is AkkIn + P, sumP(NPs, AkkOut, Pges).

% Auswuerfeln des als nächstes zu besuchenden Knoten N
roll([],_,_,_) :- false.
roll([N:P|_], Tar, Akk, N) :- Tar < Akk + P, !.
roll([_:P|NPs], Tar, AkkIn, Y) :-
    AkkOut is AkkIn + P, roll(NPs, Tar, AkkOut, Y).

% Hilfsfunktion: path/4 wuerfelt einen Pfad aus und berechnet die Kosten:
path(X, [Y], [X,Y], C) :- edgeC(X, Y, C).
path(X, Unvisited0, [X|Path], SumCost0) :-
        choice(X, Unvisited0, Y),
        edgeC(X, Y, C),    
	selectchk(Y, Unvisited0, Unvisited1),
	path(Y, Unvisited1, Path, SumCost1),
	SumCost0 is SumCost1 + C.

% path/3 wuerfelt einen Pfad aus und gibt die Kosten zurueck:
% Beispiel: path([a,b,c,d,e], P, C).
%  P = [a, c, d, b, e]; C = 34.
% X ist Startwert, die Reihenfolge der anderen Unvisited elemente ist egal
path([X|Unvisited], Path, SumCost0) :-
	path(X, Unvisited, Path, SumCost1),
	% Kosten um den Pfad abzuschließen:
	last(Path, Last),
	edgeC(X, Last, C),
	SumCost0 is SumCost1 + C,
	!.
/*****************************************************************************/

runACO(SolPath, SolCost) :-
    findall(X:Y, arc(X, Y, _), XYs), initTP(XYs),
    assert(bestSol([], 2^31-1)),
    aux,
    bestSol(SolPath, SolCost), !.

aux :-
    bestSol(_, OldCost),
    runCycleMultiple(5),
    reRun(OldCost).
    
reRun(OldCost) :-
    writeln("   reRun?"), 
    bestSol(_, NewCost),
    write("   OldCost: "), write(OldCost), write(" NewCost: "), writeln(NewCost),
    NewCost < OldCost, aux.
reRun(_).

runCycleMultiple(0).
runCycleMultiple(Count) :-
    Count1 is Count -1, runCycle, runCycleMultiple(Count1).

runCycle :-
    findall(X:Y, arc(X, Y, _), XYs), evaporateT(XYs),
    totalAnts(M), runAllAnts(M),
    mapUpdateP(XYs).

runAllAnts(0).
runAllAnts(Count) :- 
    runAnt, Count1 is Count -1,
    runAllAnts(Count1).

%%% Für eine Ameise mit zufälligen Startpunkt wir ein Pfad ermittelt.
%%% Anschließend werden die Pheromone aktualisiert.
runAnt :-
    nodes(Nodes),
    random_select(Start, Nodes, Rest),    
    path([Start|Rest], Path, C), updateC(Path, C),
    last(Path, Last), updateT(Start, Last, C), mapUpdateT(Path, C).
%    write("   Path: "), write(Path), write("   Cost: "), writeln(C).    


/*****************************************************************************/
%%% Initialisieren und Updaten von Tau, Preferenz und Cost.

initTP([]).
initTP([X:Y|XYs]) :- assert(int(X, Y, 1)), updateP(X, Y), initTP(XYs).

mapUpdateT([_], _).
mapUpdateT([X, Y|Path], C) :- updateT(X, Y, C), mapUpdateT([Y|Path], C).

updateT(X, Y, C) :-
    edgeT(X, Y, TauOld), constantQ(Q),
    TauNew is TauOld + Q/C,
    assertT(X, Y, TauNew).

evaporateT([]).
evaporateT([X:Y|XYs]) :-
    edgeT(X, Y, TauOld), persistance(P),
    TauNew is TauOld * P, assertT(X, Y, TauNew),
    evaporateT(XYs).

assertT(X, Y, TauNew) :-			
    retractall(int(X, Y, _)), retractall(int(Y, X, _)),
    assert(int(X, Y, TauNew)).

mapUpdateP([]).
mapUpdateP([X:Y|XYs]) :- updateP(X, Y), mapUpdateP(XYs).

%%% Preferenzen sind nicht normiert
updateP(X, Y) :-
    alpha(A), beta(B), 
    edgeT(X, Y, Tau), edgeC(X, Y, C),
    P is Tau^A * (100/C)^B,
    retractall(prob(X, Y, _)), assert(prob(X, Y, P)).    
    
updateC(_, C) :- bestSol(_, Cbest), C >= Cbest.
updateC(Path, C) :-
    bestSol(_, Cbest), C < Cbest,
    write("   UPDATE Best Cost: "), write(Cbest), write(" ---> "), writeln(C), writeln(""), 
    retractall(bestSol(_,_)), assert(bestSol(Path, C)).



/*****************************************************************************/
%%% Hilfsfunktionen zur Ausgabe
round(X, Y, D) :- Z is X * 10^D, round(Z, ZA), Y is ZA / 10^D.

% Pretty Print von Listen
pp([H|T], I) :- !, J is I+3, pp(H, J), ppx(T, J),nl.
pp(X, I):- tab(I), write(X), nl.
ppx([],_).
ppx([H|T], I):-pp(H, I),ppx(T, I).

dotGraph :-
    tell(ausgabeTsp),
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
dotEdge([X:Y|XYs]) :-
    edgeC(X, Y, C), edgeT(X, Y, T), edgeP(X, Y, P),
    round(T, TR, 3), round(P, PR, 3), CR is round(C),
    write(X), write(" -> "), write(Y), write(" [label=\""),
    write("C:"), writeln(CR),
    write("T:"), writeln(TR),
    write("P:"), writeln(PR),    
    writeln("\"]"),
    dotEdge(XYs).
