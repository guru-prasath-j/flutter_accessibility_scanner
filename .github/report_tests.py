import json, sys
names, errors, failed = {}, {}, []
for line in open(sys.argv[1], errors='replace'):
    line = line.strip()
    if not line.startswith('{'): continue
    try: e = json.loads(line)
    except Exception: continue
    if not isinstance(e, dict): continue
    t = e.get('type')
    if t == 'testStart': names[e['test']['id']] = e['test']['name']
    elif t == 'print': errors.setdefault(e['testID'], []).append(e['message'][:2500])
    elif t == 'error': errors.setdefault(e['testID'], []).append(e['error'] + '\n' + e.get('stackTrace', '')[:600])
    elif t == 'testDone' and e.get('result') != 'success' and not e.get('hidden'): failed.append(e['testID'])
for tid in failed:
    msg = '\n'.join(errors.get(tid, ['(no error)']))[:6000].replace('%', '%25').replace('\r', '').replace('\n', '%0A')
    print(f"::error title=FAILED {names.get(tid, tid)[:120]}::{msg}")
print(f"{len(failed)} failed")
sys.exit(1 if failed else 0)
