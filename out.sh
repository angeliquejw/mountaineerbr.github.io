#!/bin/zsh
# mountaineerbr  apr/20201
# CAUTION: This will replace all text between [BODY]
# tags of files in array $files with text from $html.


#files to modify
files=(
about/index.html
blog/10/index.html
blog/11/index.html
blog/12/index.html
blog/13/index.html
blog/14/index.html
blog/15/index.html
blog/16/index.html
blog/17/index.html
blog/18/index.html
blog/19/index.html
blog/1/index.html
blog/20/index.html
blog/21/index.html
blog/22/index.html
blog/23/index.html
blog/24/index.html
blog/25/index.html
blog/26/index.html
blog/27/index.html
blog/28/index.html
blog/29/index.html
blog/2/index.html
blog/30/index.html
blog/31/index.html
blog/32/index.html
blog/33/index.html
blog/34/index.html
blog/35/index.html
blog/36/index.html
blog/37/index.html
blog/38/index.html
blog/3/index.html
blog/4/index.html
blog/5/index.html
blog/6/index.html
blog/7/index.html
blog/8/index.html
blog/9/index.html
blog/cat.html
blog/index.html
blog/podcast/index.html
business/index.html
contact/index.html
donate/index.html
faqf.html
fool.html
fool/index.html
guestbook/index.html
index.html
links.html
lud.html
podcast.html
quotes.html
sitemap.html

)

#html text to inject
html='<body>


<h1>Away</h1>

<h2>Out-0f-business for the foreseeable future.</h2>


<p>Podcast and Blog RSS feeds remain available.</p>

<p>The blog HTML can be
<a title="For the sake of convenience, all posts concatenated into one document" href="https://mountaineerbr.github.io/blog/cat.html">found here</a>
(without images or styles, sorry about that).</p>

<p>Thanks to all visitors!</p>


<hr>
<h1>Saímos</h1>

<h2>Indisponível por tempo indeterminado.</h2>

<p>Os feeds do Podcast e Blog permanecem disponíveis.</p>

<p>O Blog em HTML pode ser
<a title="Pelo benefício da comodidade, todos os posts reunidos em um único documento" href="https://mountaineerbr.github.io/blog/cat.html">encontrado aqui</a>
(sem images e estilos, foi mal).</p>

<p>Obrigado a todos os visitantes!</p>


<footer>
 

<!--
- - - -	Copyright ©2021.
 - - -	Verbatim copying and distribution of this entire article is
- - - -	permitted in any medium, provided this notice is preserved.
-->

<!--
- - - -	Legal Mumbo Jumbo
- - - -	You are free to copy or repost any or part of these
- - - -	blogs, as long as the proper attribution is given.
- - - -	A heads-up is always appreciated.
- - - -	The opinions expressed are mine and my own and they
- - - -	do not represent my employer or company opinions.
-->


</footer>

</body>'

#temp tag
tag='<!-- tag -->'


#start
set -e

for f in $files[@]
do
	printf "%s..." "$f"
	sed -i "s/.*<body.*/$tag\n&/" $f
	sed -i "/<body/,/<\/body>/ d" $f
	sed -i "/$tag/ r /dev/stdin"  $f <<<"$html"
	sed -i "/$tag/ d"  $f
	printf "%s\n" Done
done


