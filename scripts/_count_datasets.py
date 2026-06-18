import os, json
root = os.path.abspath('datasets/raw')
summary = []
for name in os.listdir(root):
    d = os.path.join(root, name)
    if not os.path.isdir(d):
        continue
    for split_file in os.listdir(d):
        if not split_file.endswith('.jsonl'):
            continue
        path = os.path.join(d, split_file)
        count = 0
        with open(path, 'r', encoding='utf-8') as f:
            for _ in f:
                count += 1
        placeholder = count < 20
        summary.append({
            'dataset': name,
            'split': split_file.replace('.jsonl', ''),
            'records': count,
            'placeholder': placeholder,
            'path': path
        })
print(json.dumps(summary, indent=2))
