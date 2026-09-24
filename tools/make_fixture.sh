#!/bin/zsh
# Собирает тестовую папку со всеми неудобными случаями для сканера.
#   tools/make_fixture.sh /tmp/ts-fixture
# Папка пересоздаётся с нуля. Содержимое файлов — нули, важны только размеры, имена и даты.
set -e
F=${1:?укажи папку, например /tmp/ts-fixture}
case "$F" in /tmp/*|/private/tmp/*) ;; *) echo "фикстура только в /tmp" >&2; exit 1;; esac
rm -rf "$F"; mkdir -p "$F"
cd "$F"

mk() { mkdir -p "$(dirname "$1")"; head -c "$2" /dev/zero > "$1"; }   # файл заданного размера

# крупные файлы разных типов
mk media/film.mov 6000000
mk media/copies/film_copy.mov 6000000          # кандидат в дубли: тот же размер и расширение
mk media/photo.JPG 2500000                     # расширение в верхнем регистре
mk docs/report.pdf 1200000
mk docs/Таблица.xlsx 800000                    # кириллица в имени
mk docs/no_extension 300000
mk docs/.hidden_config 5000
mk docs/archive.tar.gz 900000                  # расширение «gz»
mk docs/weird.verylongextension 700            # слишком длинное расширение — считается «без расширения»
# «й» в разложенной форме (и + U+0306): 6 видимых букв, но 12 кодовых точек — расширение слишком длинное
mk "docs/nfd.$(python3 -c 'print("и\u0306" * 6, end="")')" 777
mk "docs/short.$(python3 -c 'print("и\u0306" * 2, end="")')" 555     # 4 кодовые точки — нормальное расширение

# разреженный файл: размер 200 МБ, на диске почти ноль
mkdir -p sparse; mkfile -n 200m sparse/disk.img

# 500 мелких файлов — проверка лимита 400 файлов на папку и сводки «помельче»
mkdir -p many
for i in $(seq 1 500); do head -c $((100 + i)) /dev/zero > many/f$i.txt; done

# глубокая вложенность и пустая папка
mk deep/l1/l2/l3/l4/leaf.txt 4000
mkdir -p empty

# жёсткая ссылка: место считается один раз
mk hard/h1.bin 1000000
ln hard/h1.bin hard/h2.bin

# символическая ссылка: пропускается
ln -s ../media/film.mov media/link_to_film.mov

# папка «не синхронизировать» (атрибут Dropbox)
mk ignored/big.bin 3000000
xattr -w 'com.apple.fileprovider.ignore#P' 1 ignored

# даты: старый файл и файл из будущего
mk old/ancient.doc 50000
touch -t 201501011200 old/ancient.doc
mk future/time_traveller.txt 1000
touch -t 210001011200 future/time_traveller.txt

echo "Фикстура готова: $F"
