Пробный запуск №3. Кода по делу не пиши. Выполни по очереди и приведи вывод каждой команды дословно (последние 3 строки):
1. `swift build -c release --scratch-path /tmp/ts-build 2>&1 | tail -3`
2. `/tmp/ts-build/release/tscan /tmp/ts-fixture --json /tmp/ts-build/smoke.json 2>&1 | tail -2` (если папки /tmp/ts-fixture нет — сначала `tools/make_fixture.sh /tmp/ts-fixture`)
3. `mkdir -p build/smoke && touch build/smoke/ok && ls build/smoke`
4. `touch .build/smoke_ok && ls .build/smoke_ok`
Ответь четырьмя пунктами.
