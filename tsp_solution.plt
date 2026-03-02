fname = 'tsp_solution.dat'
set output 'tsp_solution.pdf'
set terminal pdfcairo size 40cm,40cm       # generate pdf file

unset xtics; unset ytics; unset x2tics; unset y2tics

plot [-5:105] [-5:105] \
  fname using 2:3       with lines lc rgb "black" lw 2 notitle, \
  fname using 2:3:(1.1) with circles lc rgb "white" lw 2 fill solid border lc "black" notitle, \
  fname using 2:3:1     with labels offset (0,0) font 'Arial Bold' notitle
