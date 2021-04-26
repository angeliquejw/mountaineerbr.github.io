#!/bin/bash
#yahoo! finance stock symbol scraper
#requires 'links'

#which pages?
markets=(
	trending-tickers
	most-active
	gainers
	losers
	etfs
	commodities
	world-indices
	currencies
	mutualfunds
	bonds
	options/highest-implied-volatility
	options/highest-open-interest 
	sector/ms_basic_materials
	sector/ms_communication_services
	sector/ms_consumer_cyclical
	sector/ms_consumer_defensive
	sector/ms_energy
	sector/ms_financial_services
	sector/ms_healthcare
	sector/ms_industrials
	sector/ms_real_estate
	sector/ms_technology
	sector/ms_utilities

	)

#get data, cut table and print it
getf() { 
	D="$(links -dump -width 300 "https://finance.yahoo.com/$m?offset=$off&count=$count" | sed -n '/Symbol.*Name/,/^$/p')"
	
	#print table
	printf '%s\n' "$D"

	#print stats (address and items per page on stderr)
	printf '%s  items: %s\n' "https://finance.yahoo.com/$m?offset=$off&count=$count" "$(wc -l <<<"$D")" 1>&2
	
	#sleep 0.2
}

#scrape loop
for m in "${markets[@]}"; do
	count=100; off=0
	
	getf

	while (( $(wc -l <<<"$D") > count )); do
		off=$((count+off))
		
		getf
		
	done
done  #| grep -v 'Symbol.*Name' | sed -Ee 's/^(\]|\[|\s|\t)*([A-Z]*)/\2/' -e 's/[0-9]+\.[0-9].*$//' | sed 's/\s/\t/' 
      #uncomment above line to process tables further

