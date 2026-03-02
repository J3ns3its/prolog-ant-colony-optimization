# gnuplot -c tsp2.plt
#
# variable width:
# https://stackoverflow.com/questions/24499467/gnuplot-how-to-plot-with-variable-linewidth

fnodes = 'tsp_solution.dat'
set output 'tsp_tau.pdf'
# set terminal pdfcairo size 8cm,8cm       # generate pdf file
set terminal pdfcairo size 40cm,40cm       # generate pdf file

unset xtics; unset ytics; unset x2tics; unset y2tics

#set style arrow 1 lw 0.2 lc "black" nohead
#set for [i=1:100] style arrow (i+1) lw i/5. lc "red" nohead
set for [i=0:100] style arrow (i+1) lw i/5. lc "red" nohead

plot [-5:105] [-5:105] \
  'tsp_tau.dat' using 1:2:($3-$1):($4-$2):5  with vectors arrowstyle variable notitle, \
  fnodes using 2:3:(1.1) with circles lc rgb "white" lw 2 fill solid border lc "black" notitle, \
  fnodes using 2:3:1     with labels offset (0,0) font 'Arial Bold' notitle



