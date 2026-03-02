#Ant Colony Optimisation Algorhitm in Prolog
Jens Hartmann 28.02.2021.

Multiple Traveling Salesman Problems(TSP) are included in the town<NR>.pl files

Solutions for most optimal paths and pheromones are present in the gnu folder. tsp_solution_<NR>*.pdf

#Run program

swipl runAntAlgo.pl

##Run default program.
run.
##Run with custom number of cycles.
runCycles(N). 

# Generate solution PDF
  gnuplot -c tsp_solution.plt
  gnuplot -c tsp_tau.plt

#Sources

 o The Ant System: Optimization by a colony of cooperating agents,
   Marco Dorigo, Vittorio Maniezzo, Alberto Colorni, 1996.

 o TSP in Prolog
   https://nerddan.github.io/2015/01/07/prolog-tsp.html

 o Oliver 30 Problem
   https://stevedower.id.au/research/oliver-30
