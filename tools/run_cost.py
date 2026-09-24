#!/usr/bin/env python3
"""Сводка по прогону исполнителя: модель, ходы, токены, оценка в рублях.
    python3 tools/run_cost.py docs/runs/<лог>.jsonl [...]
Цены coding-lite (₽ за 1 млн токенов) со слов CEO 24.09.2026; выход — оценка, уточнить по кабинету шлюза.
"""
import json, sys
PRICE = {  # вход, выход
    "deepseek/deepseek-v4-flash": (2.5, 15), "deepseek/deepseek-v4.1-flash": (7, 15),
    "qwen/qwen3.8-flash": (7, 15), "z-ai/glm-5.3-flash": (13, 42),
}
total = 0.0
for path in sys.argv[1:]:
    models, res = set(), None
    for line in open(path, encoding="utf-8"):
        try: e = json.loads(line)
        except ValueError: continue
        if e.get("type") == "assistant": models.add(e["message"].get("model"))
        if e.get("type") == "result": res = e
    if not res:
        print(f"{path}: нет итоговой записи (прогон оборван?)"); continue
    u = res.get("usage", {})
    tin = u.get("input_tokens", 0) + u.get("cache_read_input_tokens", 0) + u.get("cache_creation_input_tokens", 0)
    tout = u.get("output_tokens", 0)
    m = next(iter(models - {None}), "?")
    pin, pout = PRICE.get(m, (10, 30))
    rub = tin / 1e6 * pin + tout / 1e6 * pout
    total += rub
    print(f"{path.split('/')[-1]}: {m} | {res.get('subtype')} | ходов {res.get('num_turns')} | "
          f"{res.get('duration_ms', 0) / 60000:.1f} мин | вход {tin:,} / выход {tout:,} токенов | ≈ {rub:.2f} ₽".replace(",", " "))
if len(sys.argv) > 2:
    print(f"ИТОГО ≈ {total:.2f} ₽")
