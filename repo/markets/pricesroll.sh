#!/bin/bash

xfce4-terminal -T 'BNB Binance' --geometry=6x20+0+375 -e "${HOME}/bin/markets/binance.sh -af3 -w bnbusdt" &

xfce4-terminal -T 'LTC Binance' --geometry=6x20+54+375 -e "${HOME}/bin/markets/binance.sh -as2 ltcusdt" &

xfce4-terminal -T 'BTC Binance US' --geometry=8x6+108+360 -e "${HOME}/bin/markets/binance.sh -a2us btc usd" &

xfce4-terminal -T 'BTC Bitstamp' --geometry=8x6+108+615 -e "${HOME}/bin/markets/bitstamp.sh -c" &

xfce4-terminal -T 'BTC Bitfinex' --geometry=8x6+108+485 -e "${HOME}/bin/markets/bitfinex.sh" &

xfce4-terminal -T 'XRP Binance' --geometry=8x20+0+0 -e "${HOME}/bin/markets/binance.sh -f5 -as xrpusdt" &

xfce4-terminal -T 'BCHABC Binance' --geometry=6x20+65+0 -e "${HOME}/bin/markets/binance.sh -aw2 bchusdt" &

xfce4-terminal -T 'ETH Binance' --geometry=6x20+120+0 -e "${HOME}/bin/markets/binance.sh -aw2 ethusdt" &

xfce4-terminal -T 'BTC Detailed' --geometry=80x52+172+0 -e "${HOME}/bin/markets/binance.sh -ai" &

xfce4-terminal -T 'BTC Book Depth Binance' --geometry=36x44+795+0 -e "${HOME}/bin/markets/binance.sh -ab" &

xfce4-terminal -T 'BTC New-Block Blockchain.info' --geometry=74x17+506+495 -e "${HOME}/bin/markets/binfo.sh -e" &

xfce4-terminal -T 'Misc' --geometry=35x35+1149+20 &

