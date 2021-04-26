# scripts
## GENERAL INDEX


SCRIPT NAME | DESCRIPTION
:-------------|:-----------
__ala.sh__ | Arch Linux Archives (aka ALA) explorer and a pkg downloader
__anta.sh__ | Explorador do site &lt;oantagonista.com&gt;; spider of the website &lt;oantagonista.com&gt;
__archPkgCrossCheck.sh__ | Check which pkgs are required by other pkgs from the same list (arch linux)
__bcalc.sh__ | Simple wrapper for Bash Bc that keeps a record of results; compatible with bash and z-shell
__bcalc_ext.bc__ | *bcalc.sh* extensions for bash bc
__cep.sh__ | Cep por Nome de Rua e Vice-Versa
__conkykiller.sh__ | Start/restart conkies regularly to deal with terrible IO ops memory leaks.
__corona_func.sh__ | Small shell function library for corona virus data manipulation; source to make functions available in your shell. not comprehensible to use; will not be updated
__corona_tables.sh__ | Make some tables with funcs from corona_func.sh (used by coronaplotup.sh)
__corona_notifyBR.sh__ | Shell functions to download data from SUS Flu Syndrome Notification System and calculate the positivity rate of covid19 tests (experimental)
__coronaplot.sh__ | Script to fetch latest data and plot graphs of corona virus data from reuters and johns hopkins university
__coronaplotup.sh__ | Automate sync'ing corona virus graphs and git repo
__ctemp.sh__ | Convert amongst temperature units (Celsius, Fahrenheit and Kelvin)
__ddate.sh__ | Calculate time ranges in different units; convert between human and UNIX time formats
__diffcp.sh__ | Copy files from $SOURCE to $PWD when they differ (uses `diff`). Useful for updating files in a git repo from a source directory
__faster_sh.txt__ | Tips for improving script performances, specific for some use cases, text document
__firefox.sh__ | Set opengl environment vars and launch firefox with pvkrun or primusrun
__grep.sh__ |  Grep files with shell built-ins
__gs.sh__ | Sync a git repository in one go (git wrapper).. I actually use this
__ibgepop.sh__ | População nacional/regional do Brasil pelo IBGE
__index-of.sh__ | Try to download book files from &lt;index-of.co.uk/&gt;
__inmet.sh__ | Download satellite images from Brazilian National Institute of Meteorology
__sas.sh__ | Set multiple audio sinks for my system
__skel.sh__ | My skel script and tips
__ts.sh__ | Test my own scripts with repetitive commands (z-shell)
__ug.sh__ | Light version of \`urlgrep.sh', almost as a proof-of-concept but more generous.
__unt.sh__ | Unarchive and uncompress file types to stdout
__urlgrep.sh__ | Grep full-text content from a URL list; useful for searching web history and bookmarks
__wc.sh__ |  print line, word and character count for files with shell built-ins
__zoomDown.sh__ | Emulate _super+mouse wheel_, translates to zooming in xfce4
__zoomUp.sh__ | Emulate _super+mouse wheel_, translates to zooming in xfce4

---

## BITCOIN-CLI WRAPPER AND BITCOIN-RELATED SCRIPTS

These scripts wrap bitcoin-cli (bitcoind) and try to parse data;
they are transaction-centred.

_Make sure bitcoin-dameon is **fully synchonised**_, otherwise some
functions may not work properly!

___Tip___: to use bitcoin.tx.sh, have bitcoind set with
transaction indexes (option 'txindex=1'),
otherwise user must supply block id hash manually and
still some vin transaction information is not going to be retrieved.

Depends on `bitcoin-cli` _RPC_ call output.
That is good as we can be dependable on a set of minimally-parsed data
to start with.

These wrapper scripts require `bash`, `bitcoin-cli` and `jq`.
Some scripts have got [grondilu's bitcoin-bash-tools](https://github.com/grondilu/bitcoin-bash-tools)
functions embedded.

The script `bitcoin.tx.sh`  will deliver better summary data than
&lt;blockchain.com&gt; or &lt;blockchair&gt;. This script can return
addresses from segwit and multisig transactions. The average
time for parsing transactions until block height 667803 is about
2 seconds with my i7, however that depends on the number of
vins and vouts of each transaction. Parsing a few thousand transactions
seems quite feasible for personal use.


SCRIPT NAME | DESCRIPTION
:-------------|:-----------
__bitcoin.blk.sh__ | bitcoin block information and functions
__bitcoin.hx.sh__ | create base58 address types from public key and WIF from private keys (shell function wrapper)
__bitcoin.tx.sh__ |  parse transactions by hash or transaction json data
__bitcoin.tx.ksh__ |  version ported from bash to ast ksh (script version v0.7.29k-); gains about 10-15% speed improvement over bash, experimental
__bitcoin.zzz.parsedTxs.blk638200.txt__ | example of parsed transactions from block 638200
__blockchair.btcoutputs.sh__ |  download blockchair output dump files systematically, see also [this repo](https://github.com/mountaineerbr/bitcoin-all-addresses)

---

## USAGE EXAMPLES

Tip: if bitcoind is set with transaction indexes (option `txindex=1`),
that is _not_ necessary to supply block id hash with option `-b`.
The following examples are more complicated than normal usage.

_A._ Use bitcoin-cli to make an rpc-call and get transaction hashes from the memory pool; use jq to open the json array with transaction hashes; bitcoin.tx.sh will make further rpc-calls and parse each transaction data asynchronously; at the end, the script sorts buffers and writes a text file at $PWD:

```bash
bitcoin-cli getrawmempool  | jq -r '.[]' | bitcoin.tx.sh
```

_B._ Parse a single transaction; the last two commands should have the same outputs:

```bash
TRANSACTION_HASH=a8bb9571a0667d63eaaaa36f9de87675f0d430e13c916248ded1d13093a77561

BLOCK_HEIGHT=638200

BLOCK_HASH=$( bitcoin-cli getblockhash $BLOCK_HEIGHT )
    
bitcoin.tx.sh -b"$BLOCK_HASH" "$TRANSACTION_HASH"

bitcoin-cli getrawtransaction "$TRANSACTION_HASH" true "$BLOCK_HASH" | bitcoin.tx.sh
```
    
_C._ Parse the first 10 transactions from block height number 400000; no output to screen is written, wait until all transactions are parsed and then concatenated in the correct order; a file containing the resulting parsing is written to $PWD, or use options -o to write output to screen only (check script help page):

```bash
BLOCK_HASH=000000000000000004ec466ce4732fe6f1ed1cddc2ed4b328fff5224276e3f6f
    
bitcoin.blk.sh -ii 400000 | head | bitcoin.tx.sh -b"$BLOCK_HASH"
```

---

## SEE ALSO

[binfo.sh](../repo/markets/binfo.sh)
is bitcoin blockchain explorer.

There are many shell functions to get data from many API points
at my [markets repo](../repo/markets/)

Grondilu's bitcoin-bash-tools: [bitcoin.sh](https://github.com/grondilu/bitcoin-bash-tools)

Some `bitcoin-cli` scripts: https://github.com/kristapsk/bitcoin-scripts

---

## MISCELLANEOUS

Para um registro histórico em texto de o Antagonista, veja:

For a large historical text record of the news website &lt;oantagonista.com&gt;,
check my [scrape record](https://github.com/mountaineerbr/largeFiles/tree/master/oAntaRegistro).

---

> Please consider sending me a nickle!  = )
>
>    bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr

