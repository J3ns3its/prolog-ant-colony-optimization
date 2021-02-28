normTowns :-
    findall(X ,town(_, X, _), Xs),    
    min_member(LowX, Xs),
    max_member(MaxX, Xs),
    NormX is MaxX - LowX,

    findall(Y ,town(_, _, Y), Ys),
    min_member(LowY, Ys),
    max_member(MaxY, Ys),
    NormY is MaxY - LowY,

    max_member(NormXY, [NormX,NormY]),
    write("   LowX: "), writeln(LowX),
    write("   NormX: "), writeln(NormX),
    write("   LowY: "), writeln(LowY),
    write("   NormY: "), writeln(NormY),    
    tell('townNorm.pl'),
    findall(ID:X:Y, town(ID,X,Y), Towns), normSingleTown(Towns, NormXY, LowX, LowY),
    write("\nnormXY("), write(NormXY), writeln(")."),
    told,
    genArcs, !.

getNorm(NormX, NormY, NormX) :-
    NormX > NormY.
getNorm(NormX, NormY, NormY) :-
    NormX =< NormY.

normSingleTown([], _, _, _).
normSingleTown([ID:X:Y|IDXY], NormXY, LowX, LowY) :-
    XN is 100*((X - LowX) / NormXY), YN is 100*((Y - LowY) / NormXY),
%    write("   normSingleTown: "), writeln(ID), writeln(XN), writeln(YN),    
    write("townN("), write(ID), write(", "), write(XN),
    write(", "), write(YN), writeln(")."),
    normSingleTown(IDXY, NormXY, LowX, LowY).

genArcs :-
    ['townNorm.pl'],
    tell('arcs.pl'),
    findall(ID:X:Y, townN(ID,X,Y), Towns), addArcs(Towns),
    findall(ID1, townN(ID1,_,_), IDs),
    writeln(""), write("nodes("), write(IDs), writeln(")."),
    told, !.


addArcs([]).
addArcs([ID1:X1:Y1|IDXY]) :-
    addSingleArc(ID1, X1, Y1, IDXY),
    addArcs(IDXY).

addSingleArc(_, _, _, []).
addSingleArc(ID1, X1, Y1, [ID2:X2:Y2|IDXY]) :-
%    write("   addSingleArc: "), writeln(ID1), writeln(ID2), writeln(IDXY),
    C is sqrt((X1 - X2)^2 + (Y1 - Y2)^2),
    write("arc("), write(ID1), write(", "), write(ID2),
    write(", "), write(C), writeln(")."),
    addSingleArc(ID1, X1, Y1, IDXY).
