#!/bin/bash
# anta.sh -- puxa artigos da homepage de <oantagonista.com>
# v0.17.3  jun/2021  by mountaineerbr

#padrões

#intervalo de tempo entre reacessos opção -r:
TEMPO=( 6m 2${RANDOM: -1} )  #240s
#curl/wget connection-timeout
TOUT=30
#curl/wget retries
RETRIES=2
#tentativas do script
TENTATIVAS=6
#obs: tentativas total = (( RETRIES * TENTATIVAS ))

#debug log file:
LOGF=/tmp/anta.log
#caminho do script para funão de update
SCRIPT="${BASH_SOURCE[0]}"
#não inunde o servidor
#espera entre chamadas (em segundos)
FLOOD=0.4

#cat output instead of less pager by defaults
OPTL=( cat )

#update url
UPURL=https://raw.githubusercontent.com/mountaineerbr/scripts/master/anta.sh
#<https://raw.githubusercontent.com/mountaineerbr/mountaineerbr.github.io/master/repo/scripts/anta.sh>#

#date regex
DREGEX='[0-3][0-9]\.[0-1][0-9]\.[1-2][0-9].*[0-2][0-9]:[0-5][0-9]'

#assuntos/categorias
SUBLIST=(brasil cultura economia eleicoes2020 entretenimento especial esportes mundo opiniao sociedade reuniao-de-pauta videos tudo-sobre tv opiniao despertador sem-categoria)
#tag

#Ref tapir art: http://www.ascii-art.de/ascii/t/tapir.txt
HELP="Anta.sh -- Puxa os artigos de <oantagonista.com>

                         _,.,.__,--.__,-----.
                      ,\"\"   '))              \`.
                    ,'   e                    ))
                   (  .='__,                  ,
                    \`~\`     \`-\  /._____,/   /
                             | | )    (  (   ;
                             | | |    / / / /
                     vvVVvvVvVVVvvVVVvvVVvVvvvVvPhSv


SINOPSE
	anta.sh  [-afl] [ÍNDICE..|URL..]
	anta.sh  [-afl] [-sNUM|-pNUM]
	anta.sh  [-afl] -r [-sNUM]
	anta.sh  [-afl] [ASSUNTO] [ÍNDICE..]
	anta.sh  [-huuv]


	Este script puxa os textos resumidos e integrais dos artigos do
	site <www.oantagonista.com>. Por padrão, se nenhuma opção for
	inserida, o script puxará a primeira página inicial com os re-
	sumos dos artigos e sairá. A opção -pNUM ou somente -NUM confi-
	gura quantas páginas iniciais devem ser puxadas.

	O texto integral dos artigos pode ser recuperado com a opção -f .
	Com esta opção, também pode-se especificar URLs de artigos espe-
	cíficos.

	O número de ÍNDICE de uma página inicial de <oantagonista.com>
	corresponde a ordem cronológica da mais recente para a mais an-
	tiga. Assim, a página mais recente tem o número de ÍNDICE igual
	a 1. É possível puxar múltiplas páginas pelos números de ÍNDICES.
	Para isso, use os números de INDICE como argumentos posicionais.

	A opção -r faz um reacesso da primeira página inicial e puxa os
	resumos dos artigos aproximadamente a cada ~${TEMPO[*]} segundos.
	O intervalo de tempo entre reacessos pode ser definido por -sNUM,
	em que NUM é um número natural em segundos, ou -sNUMm, em que
	m está para minutos, sendo aceitos os argumentos comumente pas-
	sados ao comando 'sleep' para esta opção. A opção -r também fun-
	ciona juntamente com a opção -f .

	Ao final da realização de trabalhos, será impresso a data e hora
	e, em seguida, alguns números. Os números entre parenteses, quan-
	do se utiliza a opção -r , são o intervalo de tempo entre reaces-
	sos. Nos demais modos, será impresso entre colchetes o tempo de
	realização da tarefa em segundos.

	Uma outra opção para puxar os links por ASSUNTOS/categorias pode
	ser acionada setando-se o primeiro argumento posicional com
	tag/[ASSUNTO] ou um dos seguintes ASSUNTOS: ${SUBLIST[*]/%/, }.
	Esta opção aceita a opção -[p]NUM ou ÍNDICES das páginas iniciais
	por assuntos e também opção -f, veja exemplo de uso (7) para mais
	informações.

	Use a opção -a para habilitar o uso de servidores alternativos,
	caso observe consecutivos erros ou seja bloqueado pelo limite
	na taxa de acessos.

	Para baixar um grande número de artigos, prefira começar em horá-
	rios de poucas publicações novas, ou seja, finais de semana e
	madrugadas. Ou, use os sitemaps do site (em XML) para pegar o
	endereço de todas as matérias.

	Ainda, pode-se ajustar o tempo de 'timeout' e de retentativas
	configurando-se algumas variáveis cabeça do código-fonte deste
	script.


RSS FEEDS
	RSS FEED
	O site oferece um feed RSS de notícias (as últimas 15 notícias,
	somente a descrição) pelo seguinte endereço:
	<https://www.oantagonista.com/feed/>

	PODCAST FEED
	<https://www.spreaker.com/show/o-antagonista>


LIMITES DE ACESSO
	Nos termos de uso do próprio site, há somente uma limitação
	que eu saiba:

	<< 2.2.1. Você se compromete a não utilizar qualquer sistema
	automatizado, inclusive, mas sem se limitar a 'robôs', 'spiders'
	ou 'offline readers,' que acessem a Plataforma de maneira a en-
	viar mais mensagens de solicitações aos servidores do site O An-
	tagonista em um dado período de tempo do que seja humanamente
	possível responder no mesmo período através de um navegador con-
	vencional. >>

		<oantagonista.com/termos-de-uso>, acesso em set/2019.


GARANTIA E REQUISITOS
	Este programa é software livre e está licenciado sob a GNU GPL 
	versão 3 ou superior e é oferecido sem suporte ou correção de
	bugs.

	Pacotes requeridos: Bash, cURL e/ou Wget. É recomendável insta-
	lar ambos cURL e Wget caso encontre bloqueios de limites de a-
	cesso do servidor.

	Se achou o script útil, por favor conside me mandar um trocado!
		=)

		bc1qlxm5dfjl58whg6tvtszg5pfna9mn2cr2nulnjr


BUGS
	Observe que se uma nova notícia for publicada durante o funciona-
	mento do programa ao baixar múltiplas páginas contíguas, irá
	perder-se algum número de reportagens pois elas são rolantes.

	Quando se usa a opção -a , alguns artigos mais recentes (da pri-
	meira e segunda página iniciais) podem estar faltantes. Os ser-
	vidores alternativos podem demorar um pouco para sincronizarem
	com o servidor padrão.
	
	Algumas sobreposições do texto com mensagens de carregamento
	enviadas pelo stderr podem ocorrer.

	Não sendo um erro do script, artigos podem aparecer em duplicata
	devido ao próprio design do site.


VEJA TAMBÉM
	Para uma cópia histórica em texto das matérias do site até o
	começo de 2020, veja o repositório: 

	<github.com/mountaineerbr/largeFiles/tree/master/oAntaRegistro>


EXEMPLOS DE USO
	( 1 ) Puxar as primeiras quatro páginas iniciais do portal:

		$ anta.sh -p4

		$ anta.sh -4


	( 2 ) Reacesar a página inicial a cada 10 minutos (600 segundos),
	      neste caso também pode-se a opção -f :

		$ anta.sh -r -s10m

		$ anta.sh -r


	(*3 ) Reacesar a página inicial automaticamente e imprimir o
	      texto completo de artigos novos, usar o paginador Les.

		$ anta.sh -frl


	( 4 ) Textos completos dos artigos das primeiras 4 páginas
 	      do portal (dica: use o paginador less também):

		$ anta.sh -f -l -p4


	( 5 ) Puxar artigos completos das URLs (opção -f é opcional):

		$ anta.sh -f '/brasil/toffoli-nega-ter-recebido-e-acessado-relatorios-do-coaf/'

		$ anta.sh '/brasil/o-que-o-congresso-ressuscitou-na-lei-de-abuso-de-autoridade/' '/brasil/toffoli-nega-ter-recebido-e-acessado-relatorios-do-coaf/'


	( 6 ) Puxar página pelo número de ÍNDICE:

		$ anta.sh 12500        #somente resumos dos artigos

		$ anta.sh -f 12500     #puxa artigos integrais da página
				       #inicial número 12500

		$ anta.sh {10..5}      #da página 10 até a página 5
		$ anta.sh 10 9 8 7 6 5
		

	( 7 ) Puxar páginas as primeiras 3 páginas iniciais por categoria;
	      opção -f para puxar os artigos completos pode ser habilitada:

		$ anta.sh -3 brasil
		$ anta.sh brasil 3 2 1

		$ anta.sh -3f despertador


	      Pode-se usar tag/[ASSUNTO] em que ASSUNTO pode ser: ciencia,
	      educacao, rio, saopaulo, lula, pt, bitcoin e mais.

		$ anta.sh -3f tag/retrospectiva-2020
		                        

OPÇÕES
	-NUM 	  Mesmo que opção -pNUM .
	-a 	  Usar servidores alternativos.
	-f [ÍNDICE..|URL..]
		  Texto integral dos artigos das páginas iniciais.
	-h 	  Mostra esta ajuda.
	-l 	  Encanar saída para o paginador Less.
	-p NUM    Número de páginas a serem puxadas; padrão=1 .
	-r 	  Reacessar a página inicial em intervalos de tempo.
	-s NUM    Intervalo de tempo entre reacessos da opção -r ; 
		  NUMm para minutos e NUMs para segundos; padrão~=240s .
	-u 	  Checar por atualização do script.
	-uu 	  Atualização do script.
	-v 	  Mostra a versão do script."


#Orign servers
SERVERS=(www.oantagonista.com)
ALTSERVERS=(cache.oantagonista.com cms.oantagonista.com m.oantagonista.com wp.oantagonista.com editores.oantagonista.com)
#'oantagonista.com' -- redirection to antagonista+
#'52.204.39.109'
#'3.82.68.200'
#'18.204.255.62'
#'52.72.53.233'
#'34.198.178.99'
#'54.210.110.10'
#'52.86.216.106'
#'34.207.47.120'
#'18.214.96.27'

AGENTS=('User-Agent: Mozilla/5.0 (compatible; MSIE 9.0; Windows Phone OS 7.5; Trident/5.0; IEMobile/9.0)' 'User-Agent: Mozilla/5.0 (iPhone; CPU iPhone OS 10_3_1 like Mac OS X) AppleWebKit/603.1.30 (KHTML, like Gecko) Version/10.0 Mobile/14E304 Safari/602.1' 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36 OPR/38.0.2220.41' 'User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.103 Safari/537.36' 'User-Agent: Mozilla/5.0 (Linux; Android 6.0.1; SGP771 Build/32.2.A.0.253; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/52.0.2743.9[<0;45;17M8 Safari/537.36' 'User-Agent: Mozilla/5.0 (Windows Phone 10.0; Android 4.2.1; Microsoft; RM-1127_16056) AppleWebKit/537.36(KHTML, like Gecko) Chrome/42.0.2311.135 Mobile Safari/537.36 Edge/12.10536' 'User-Agent: Mozilla/5.0 (Linux; Android 6.0.1; SGP771 Build/32.2.A.0.253; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/52.0.2743.98 Safari/537.36' 'User-Agent: Mozilla/5.0 (Linux; Android 7.0; SM-G892A Build/NRD90M; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/60.0.3112.107 Mobile Safari/537.36' 'user-agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Mobile Safari/537.36' 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/46.0.2486.0 Safari/537.36 Edge/13.10586' 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0' 'User-Agent: Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0) like Gecko' 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:68.0) Gecko/20100101 Firefox/68.0' 'user-agent: Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/76.0.3809.132 Mobile Safari/537.36')


## Funções
# Filtro HTML e tradução de códigos
#https://ascii.cl/htmlcodes.htm
sedhtmlf() {
	sed 	-e 's/<br[ \/]*>/&\n/g' \
		-e 's/<[^>]*>//g ; s/\r//g ; s/\xc2\xa0/ /g ; s/&nbsp;/ /g ; s/&mdash;/--/g' \
		-e 's/&#32;/ /g ; s/&#33;/\!/g ; s/&#34;/\"/g ; s/&#35;/\#/g ; s/&#36;/$/g' \
		-e 's/&#37;/%/g ; s/&#38;/\&/g' -e "s/&#39;/'/g" -e 's/&#40;/(/g ; s/&#41;/)/g' \
		-e 's/&#42;/*/g ; s/&#43;/+/g ; s/&#44;/,/g ; s/&#45;/-/g ; s/&#46;/./g' \
		-e 's/&#47;/\//g ; s/&#64;/@/g ; s/&#8211;/-/g ; s/&#8212;/--/g' -e "s/&#8216;/'/g" \
		-e "s/X&#8217;/'/g" -e 's/&#8218;/,/g ; s/&#8220;/\"/g ; s/&#8221;/\"/g ; s/&#8222;/\"/g' \
		-e 's/&#8230;/.../g ; s/&#8364;/EUR/g ; s/&amp;/\&/g ; s/&#032;/ /g ; s/&#033;/\!/g' \
		-e 's/&#034;/\"/g ; s/&#035;/\#/g ; s/&#036;/$/g ; s/&#037;/%/g ; s/&#038;/\&/g' \
		-e "s/&#039;/'/g" -e 's/&#040;/(/g ; s/&#041;/)/g ; s/&#042;/*/g ; s/&#043;/+/g' \
		-e 's/&#044;/,/g ; s/&#045;/-/g ; s/&#046;/./g ; s/&#047;/\//g ; s/&#064;/@/g' \
		-e 's/&#8211;/–/g ; s/&#8212;/—/g ; s/&#8216;/‘/g ; s/&#8217;/’/g ; s/&#8218;/‚/g' \
		-e 's/&#8220;/“/g ; s/&#8221;/”/g ; s/&#8222;/„/g ; s/&#8224;/†/g ; s/&#8225;/‡/g' \
		-e 's/&#8226;/•/g ; s/&#8230;/…/g ; s/&#8240;/‰/g ; s/&#8364;/€/g ; s/&#8482;/™/g' \
		-e 's/&#215;/x/g ; s/&#8243;/"/g ;s/\ \ */ /g ; s/\t\t*/\t/g' \
		-e 's/^[\t\ ]*//g' -e 's/Leia mais:.*//' -e 's/^\s*LEIA AQUI.*//'
}

#get post (article) links
getlinksf()
{
	grep -a -e 'id="post_[0-9]' \
	| sed 's|a>|&\n|g' \
	| sed -nE "s|.*href=['\"]([^'\"#]+)['\"!?&*.,; ].*(title\|h2).*|\1| p" \
	| nl | sort -k2 | uniq -f 1 \
	| sort -n | cut -f2
}
#-e "href=['\"]https://www.oantagonista.com/despertador/['\"]+['\"]" \

# Check for errors
cerrf()
{
	NOTFOUND=
	if grep -aiq -e 'Você será redirecionado para a página inicial' \
		     -e 'Page not found' -e 'p.gina n.o encontrada' \
		     -e 'Error processing request' <<< "$PAGE" >&2
	then
		printf 'anta.sh: erro: página não encontrada -- %s\n' "$COMP" >&2
		NOTFOUND=1
		return 0
	elif [[ -z "$PAGE" ]] || grep -aFiq -e 'has been limited' -e 'you were blocked' \
		-e 'to restrict access' -e 'access denied' -e 'temporarily limited' \
		-e 'you have been blocked' -e 'has been blocked' <<< "$PAGE" >&2
	then
		printf 'anta.sh: erro: acesso limitado ou página não encontrada -- %s\n' "$COMP" >&2
		return 1
	elif ! grep -aq '[0-9][0-9]\.[0-9][0-9]\.[0-9][0-9]' <<< "$PAGE" >&2
	then
		printf 'anta.sh: erro: não parece ser artigo de <oantagonista> -- %s\n' "$COMP" >&2
		NOTFOUND=1
		return 0
	fi

	return 0
}


# Cheque por update
updatef() {
	#trap exit
	trap updatecleanf EXIT TERM INT
	
	TMPFILE="$( mktemp )"

	#download script from url
	${YOURAPP[0]} "${AGENTS[0]}" "$UPURL" >"$TMPFILE"

	#check diff
	if diff "$SCRIPT" "$TMPFILE" &>/dev/null; then
		echo 'anta.sh: aviso: o script está atualizado'
		((UPOPT<2))
	else
		#check if the two files headers are a bash SHEBANG
		#avoid bad downloads
		HEADA="$( head -1 "$TMPFILE" 2>/dev/null )" || exit 1
		HEADB="$( head -1 "$SCRIPT"  2>/dev/null )" || exit 1

		#is that a script or html error page?
		if [[ "$HEADA" = "$HEADB" ]]; then
			#only check or install?
			if ((UPOPT>1))
			then
				install "$TMPFILE" "$SCRIPT"
			else
				echo 'anta.sh: aviso: atualização disponível'
				echo "$UPURL"
				false
			fi
		else
			#print page with error
			[[ -e "$TMPFILE" ]] && cat "$TMPFILE"
			echo "$UPURL"
			false
		fi
	fi
}
#update clean up
updatecleanf() { 
	#disable trap
	trap \  EXIT TERM INT
	[[ -f "$TMPFILE" ]] && rm "$TMPFILE"
	exit
}

# Puxar páginas iniciais e testar por erros;
#tamanho: até ~2020 =~ 650KB; mar/2020 = 34KB, compressed 8.7KB; may/2021 = 372KB
puxarpgsf() {
	#skip if $COMP is only numbers
	[[ "$COMP" = +([0-9,.]) ]] && return 0
	# Se for só uma página inicial, acesse site sem 'pagina=1' (evita bloqueios)
	(( PAGINAS == 1 )) && [[ -z "$FULLOPT" ]] && COMP='/'

	SLEEP=5
	# Tentar puxar quantas páginas iniciais quiser e testar por erros
	for ((N=2 ;N<=TENTATIVAS ;N++))
	do
		#puxar a página
		#PAGE="$( ${YOURAPP[${RANDOM} % ${#YOURAPP[@]}]}  "${AGENTS[${RANDOM} % ${#AGENTS[@]}]}" "${SERVERS[${RANDOM} % ${#SERVERS[@]}]}/${COMP#/}" )"
		#make sure to get links from original server
		PAGE="$( ${YOURAPP[${RANDOM} % ${#YOURAPP[@]}]}  "${AGENTS[${RANDOM} % ${#AGENTS[@]}]}" "${SERVERS[0]}${SUBJECT}/${COMP#/}" )"

		#erro?
		cerrf && return 0

		#havendo erro, chamar curl mais uma vez
		printf '\ranta.sh: tentativa %s\n' "$N" 1>&2

		sleep "$SLEEP"
		(( SLEEP = SLEEP + 2 )) 
	done

	# Check if it was succesfull at last or exit with error
	if cerrf
	then return 0
	else return 1
	fi
}

# Pegar os textos curtos das Página(s) Inicial(is)
anta() {
	#timer de tempo de tarefa
	SECONDS=0
	# O for loop para pegar quantas páginas quiser
	for ((i=PAGINAS;i>=1;i--)); do
		#barra de acompanhamento
		printf '\r\033[2KPágina %s/%s\r' "$i" "$PAGINAS" 1>&2

		#puxar a página
		COMP="/pagina/${i}/"
		if ! puxarpgsf; then
			printf '\nanta.sh: erro -- acesso limitado  [%s]\n' "$SECONDS" 1>&2
			return 1
		fi

		if (( D ))  #debug
		then
			echo "$PAGE"
			exit 0
		#page not found?
		elif ((NOTFOUND))
		then
			return 0
		fi

		#imprime a página e processa
		POSTS="$( <<<"$PAGE" sed -nE '/<div id="p[0-9]+"/,/id="mais-lidas"/ p' | sed  '$d' | sed -n '/<article.*/,/<\/article/ p' )"
		#POSTS="$( <<<"$PAGE" sed -nE '/<div id="p[0-9]+"/,/event_label":\s*"p[0-9]+c[0-9]+".*<\/script><\/div>/  { /<article.*/,/(<\/article|<\/h2><\/a>)/ p }' )"
		#POSTS="$( <<<"$PAGE" sed -nE '\|<div class="postmeta|,\|</div| p' )"
		#sed ':a;N;$!ba;s/<p>\s*\n\s*\n*\s*/<p>/g' <<<"$PAGE" \
		#| sed ':a;N;$!ba;s/\n*\s*\n\s*<\/p>/<\/p>/g' \
		#grep -a 'id="post_[0-9]' <<<"$PAGE"

		#continue if $OLDPOSTS and $POSTS are the same (-r OPTION)
		if ((ROLLOPT)) && [[ "$POSTS" = "$OLDPOSTS" ]]
		then :
		#process posts
		else
			#cópia de links
			LINKS2="$( getlinksf <<<"$PAGE" )"

			#print links
			tac <<< "$LINKS2"
			echo '==='

			#process 
			sed 's/[^pagm]>/&\n/g ;s/<\/article[^>]*>/&\n===/g' <<<"$POSTS" \
				| sedhtmlf \
				| sed -E \
					-e '/^\s*(COMPARTILHAR|SALVAR|LEIA AQUI|Ver mais)/ d' \
					-e '/gtag\("event/ d' \
					-e '/^window.*taboola/ d' \
					-e 's/\.dot\{.*//' \
					-e 's/^.live-html.*//' \
					-e '/^Mais lidas\s*$/ d' \
					-e '/^var.*_comscore/ d' \
					-e '/^Voltar para página/ d' \
					-e '/^Ir para página/ d' \
				| tac -r -s'^===' \
				| awk NF
		fi
		OLDPOSTS="$POSTS"
		
		#parar se foi especificado número de index de pg específica
		(( ONLYONE )) && break

		#dont flood the server
		sleep "$FLOOD"
	done

	#hora que terminou
	(( ROLLOPT )) && PRINTT="(${TEMPO[*]})"
	printf '>Puxado em %s  %s [%s]\n' "$(date -R)" "$PRINTT" "$SECONDS"
}
#also works: grep -F -B13 '<p>' <<<"$PAGE" | sedhtmlf | awk NF
#for the FEED, check
#https://www.oantagonista.com/feed/

# -f Artigos inteiros
fulltf() {
	local cab art hrefs p
	
	#ver se notícia é do MoneyTimes
	#ou outros domínios
	if [[ "$COMP" = *moneytimes/* ]] || [[ "$COMP" = */portalig/* ]]
	then
		printf '\033[2K====        \n'
		echo 'anta.sh: aviso: possível redireção a site de outro domínio'
		echo "$COMP"
		return 0
	else
		#puxa página do artigo texto integral
		if ! puxarpgsf
		then
			printf '\nanta.sh: erro: acesso limitado -- %s  [%s]\n' "$COMP" "$SECONDS" >&2
			return 1
		fi
	fi

	#page not found?
	((NOTFOUND)) && return 0

	#cabeçalho
	cab="$( 
		<<<"$PAGE" grep -aF \
			-e '="entry-title' \
			-e 'entry-date published' \
			-e '"entry-author' \
			-e '<div class="gravata' \
			| grep -aFv 'class="timer-icon' \
			|sed -E -e 's/^#breadcrumbs.*}\s?//' \
			-e 's/.*<div class="gravata.*/[&]\n<layout>\n/'
	)"
	grav="$( <<<"$PAGE" grep -cF '<div class="gravata' )"

	#artigo
	art="$(
		#processa página

		#processa página
		#get all lines with <p>
		if [[ "$COMP" = */podcast/* ]]
		then
			#if podcast grep only description line
			##grep 'entry-text-post">.*<p>' <<< "$PAGE"
			<<<"$PAGE" sed -n '/^\s*<p>/p'
		else
			#get all lines with <p> for all other pages
			<<<"$PAGE" sed -n 's/<p>/\n&/gp' | sed -n 's/<\/p>/\n&/gp'
		fi | sed -e '/>Leia também[<:]/d' \
			    -e 's/>Assine a <strong>Crusoé<.*/>/' \
			    -e '/id="comentarios"/,$ d' \
			    -e '/>LEIA MAIS</d' \
			    -e '/>Leia mais:*</d' \
			    -e '/>Mais lidas</d' \
			    -e 's/<[^<]*next_prev_title.*//' \
			    -e 's/>Usamos cookies.*/>/' \
			    -e '/>Política de Cookies/d' \
			    -e '/^Acompanhe nossas notícias/d' \
			    -e '/^Acesse nossa página no/d' \
			    -e 's/<.*id="linkcopy".*>//g' \
			    -e '/>Notícias relacionadas:/d' \
			    -e 's|<a|[*][&|g ;s|</a|]&|g' \
			    -e 's|\[\*\]\[\s*\]\s*||g' \
				-e 's/<\/li>/&\n/g ;s/<\/[ou]l>/&\n<layout>\n/g'
	)"
	#https://stackoverflow.com/questions/5315464/email-formatting-basics-links-in-plain-text-emails
	
	#get link references
	hrefs=( $(
		sed 's|a>|&\n|g' <<<"$art" \
			| sed -nE "s|.*href=['\"]([^'\"]+)['\"].*|\1| p" \
			| nl | sort -k2 | uniq -f 1 \
			| sort -n | cut -f2 \
			| sed -e "/twitter\.com\// s/\?[^\'\"]*//g"
	) )
	
	#remove html tags, more processing of article
	art="$( 
		sedhtmlf <<<"$art" |
		sed -Ee '/^\s*var.*"script/d' \
		     -e 's/setTimeout.*//' \
		     -e 's/function\(\).*//' \
			 -e '/^\s*(Rua Iguatemi, 192 -|®202[0-9] - O Antagonista)/,/^\s*CNPJ 25.163.879\/0001-13/ d'
	)"

	#contar parágrafos
	par="$(p=$grav ;while read; do [[ -n "${REPLY// }" ]] || continue; ((++p)); done <<<"$art"; echo "$p")"

	{
		#print header and add the number of paragraphs
		printf '\033[2K====        \n'
		#print article
		sedhtmlf <<<"$cab" | sed "/^[0-9][0-9]\.[0-9][0-9]\./ s/$/ [\$\$ $par]\n/"

		echo "$art"

		#print article refs
		(( ${#hrefs[@]} )) &&
			printf '\n* %s' "Refs[${#hrefs[@]}]:" "${hrefs[@]}"

		#print footer
		printf '\nhttps://www.oantagonista.com/%s\n' "${COMP#/}"

	} | sed -r ':a; /^\s*$/ {N;ba}; s/( *\n *){2,}/\n/'
	    #^collapse multiple bank lines

	return 0
}
#article index number?
#https://www.oantagonista.com/brasil/399950/
#https://www.oantagonista.com/brasil/bolsonarista-preso-ontem-e-apontado-como-financiador-de-acampamentos/
#try not to break html processing at
#www.oantagonista.com/brasil/como-votou-cada-deputado-no-destaque-da-facada-em-paulo-guedes/
#https://www.oantagonista.com/frases-da-semana/as-frases-da-semana-em-que-o-ministro-interino-da-saude-rezou/
#https://www.oantagonista.com/podcast/podcast-viva-la-muerte/
#https://www.oantagonista.com/brasil/o-stf-esta-disposto-a-ajudar-davi-alcolumbre/
#https://www.oantagonista.com/brasil/renan-calheiros-anuncia-lista-de-14-investigados-pela-cpi/

# Puxar links das páginas iniciais
# e puxar artigos completos
linksf() {
	local ret
	typeset -a ret

	#timer de tempo execução de tarefa
	SECONDS=0
	# Check for user-suppplied links
	if [[ "$*" = */* ]]
	then
		for i in $@
		do
			# Arrumar variável para passar nos testes da 'puxarpgsf'
			PAGINAS=0
			COMP="${i,,}"
			COMP="${COMP/https:\/\/www.oantagonista.com}"
			fulltf ;ret+=($?)
		done
	else
		# Get Links from initial pages
		for ((i=PAGINAS;i>=1;i--))
		do
			#barra de acompanhamento
			printf '\r\033[2KLinks %s/%s\r' "$i" "$PAGINAS" 1>&2

			#prepara o link da página inicial a ser puxada
			export COMP="/pagina/${i}/"

			#puxa pgs iniciais
			puxarpgsf

			#pega links para artigos integrais
			LINKS="$( getlinksf <<<"$PAGE" )"

			#crawl each link
			while read COMP
			do
				#avoid duplicate articles links
				[[ "${LINKSBUFFER[*]}" = *"$COMP"* ]] && continue
				LINKSBUFFER+=( "$COMP" )

				fulltf || { ret+=(1) ;continue ;}

				#dont flood the server
				sleep "$FLOOD"

			done <<<"$(tac <<<"${LINKS//https:\/\/www.oantagonista.com/}" )"
			
			sleep "$FLOOD"

			#parar se foi especificado número de index de pg específica
			(( ONLYONE )) && break
		done

		#hora que terminou tarefa
		(( ROLLOPT )) && PRINTT="(${TEMPO[*]})"
		printf '>Puxado em %s  %s [%s]\n' "$(date -R)" "$PRINTT" "$SECONDS"
	fi
	
	return $(( ${ret[@]/%/+} 0 ))
}

## Parse options
while getopts :afwhlp:rs:uv0123456789 opt
do
	case $opt in
		[0-9])
			# Páginas para Puxar
			PAGINAS="${PAGINAS}${opt}"
			;;
		a)
			#use alternative servers
			OPTALT=1
			;;
		f|w)
			# Textos completos (Full text)
			FULLOPT=1
			;;
		h)
			# Show Help
			HELPOPT=1
			;;
		l)
			#use the Less pager
			OPTL=( less )
			;;
		p)
			# Páginas para Puxar
			PAGINAS="$OPTARG"
			;;
		r)
			# Anta Rolante
			ROLLOPT=1
			;;
		s)
			#tempo entre reacessos
			TEMPO=($OPTARG)
			;;
		u)
			# Checar update ou realizar o update
			((++UPOPT))
			;;
		v)
			# Version of Script
			grep -Fm1 '# v' "${BASH_SOURCE[0]}"
			exit 0
			;;
		\?)
			# Invalid opt
			echo "anta.sh: erro: opção inválida -- -$OPTARG" >&2
			exit 1
			;;
	esac
done
shift $((OPTIND -1))
typeset -a RET
export RET

#chamar algumas opções
#ajuda
if ((HELPOPT))
then echo "$HELP" | "${OPTL[@]}" ;exit 0
fi

#set variables
typeset -a RET

# Test if cURL and Wget are available
if command -v curl &>/dev/null
then YOURAPP=("curl --compressed -s --retry $RETRIES --max-time $TOUT -L -b non-existing -H")
fi
if command -v wget &>/dev/null
then YOURAPP+=("wget -t$RETRIES -T$TOUT -qO- --header")
fi
if ((${#YOURAPP[@]}==0))
then echo 'anta.sh: erro: curl e/ou wget é necessário' >&2 ;exit 1
fi

#-a use alternative servers, too?
if (( OPTALT ))
then SERVERS=( "${SERVERS[@]}" "${ALTSERVERS[@]}" )
#opção de checagem ou realização da atualização do script
elif ((UPOPT))
then updatef ;exit
fi

#lista de assuntos/categorias
[[ "${1//\/}" = podcast ]] && set -- videos "${@:2}"
if [[ \ "${SUBLIST[*]}"\  = *\ "${1//\/}"\ * ]]
then
	echo 'anta.sh: assunto detectado' >&2
	SUBJECT=/"${1//\/}" ;shift
elif [[ "$1" = *(/)tag/?* ]]
then
	echo 'anta.sh: tag/assunto detectado' >&2
	SUBJECT=/"${1#/}"  SUBJECT="${SUBJECT%/}" ;shift
elif [[ "$1" = *(/)tag*(/) ]]
then
	echo "anta.sh: tag/ requer um ASSUNTO" >&2
	exit 1
fi

#setar variáveis das próximas opções
#usar opção -f se especificar uma URL
if [[ "$*" = */* ]]; then
	echo 'anta.sh: link detectado' >&2
	FULLOPT=1
	unset ROLLOPT
#pegar só uma página por número
elif [[ "$*" = +([0-9\ ]) ]]; then
	echo 'anta.sh: índice detectado' >&2
	ONLYONE=1
	#unset ROLLOPT
fi

## Puxar funções das opções
{
	#opção padrão
	#se tiver args posicionais (índices de páginas inciais)
	#ou setado -NUM, ou se for opção padrão
	#(puxar somente a primeira página inicial)
	if (($#)) || (( PAGINAS )) || {
		 (( ROLLOPT + PAGINAS == 0 )) && PAGINAS=1
	}
	then
		#opção -f, textos completo
		if (( FULLOPT ))
		then

			#index opt
			if (( ONLYONE ))
			then
				#indicies de pgs como arg posicionais
				for PAGINAS in "$@"
				do linksf ;RET+=($?)
				done
			else
				#opção padrão, puxar primeira pg e sair
				#ou -NUM
				linksf "$@"
				RET+=($?)
			fi
		else
			#só os resumos das matérias das pgs iniciais
			#index opt
			if (( ONLYONE ))
			then
				#indicies de pgs como arg posicionais
				for PAGINAS in "$@"
				do anta ;RET+=($?)
				done
			else
				#opção padrão, puxar primeira pg e sair
				#ou -NUM
				anta
				RET+=($?)
			fi
		fi
	fi

	# -r Anta Rolante
	if (( ROLLOPT ))
	then
		[[ -n "${OPTL[*]}" ]] || echo "anta.sh: opção antagonista rolante" >&2

		#loop forever
		#then set to always get first page
		XAGAIN=780
		AGAIN="$XAGAIN"
		[[ "$PAGINAS" = 0 ]] || PAGINAS=1
		while :
		do
			# Loop para puxar as notícias
			while :
			do
				if (( FULLOPT ))
				then linksf || break
				else anta || break
				fi
				
				sleep "${TEMPO[@]}"
				[[ "$PAGINAS" = 0 ]] && PAGINAS=1
			done

			#grand retry timer
			((AGAIN>=1800)) && AGAIN="$XAGAIN"
			AGAIN="$((AGAIN+180))"

			#grand retry
			printf '\nanta.sh: aviso -- aguardando %s minutos..\n' "$((AGAIN/60))" 1>&2
			sleep "$AGAIN"
		done
	fi
#use Less pager or Cat ouput?
} | "${OPTL[@]}"

exit $(( ${RET[@]/%/+} 0 ))

