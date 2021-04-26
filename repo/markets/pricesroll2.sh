#!/bin/zsh

#xterm -geometry 8x1 -e "$HOME/bin/markets/binance.sh -aw2 btcusdt" &|
#xterm -geometry 8x1 -e "$HOME/bin/markets/foxbit.sh -p" &|
#xterm -geometry 8x1 -e 'while true ;do bash "$HOME/bin/markets/novad.sh" -2 | xargs -n1 printf "\n%.2f" ;sleep 5 ;done' &|

xfce4-terminal -T 'BTC Binance' --geometry=8x1+0+690 -e "${HOME}/bin/markets/binance.sh -2w" &
xfce4-terminal -T 'BTC Bitstamp' --geometry=8x1+70+690 -e "${HOME}/bin/markets/bitstamp.sh" &
xfce4-terminal -T 'BTC Novadax' --geometry=9x1+140+690 -e "${HOME}/bin/markets/foxbit.sh -p" &


