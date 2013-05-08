use Test::More;
eval q{ use Test::Spellunker };
plan skip_all => "Test::Spellunker is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Hideaki Ohno
hide.o.j55 {at} gmail.com
ArangoDB
fulltext
skiplist
api
geo
geojson
waitForSync
journalSize
filesize
isSystem
isVolatile
datafiles-fileSize
journals-fileSize
keepNull