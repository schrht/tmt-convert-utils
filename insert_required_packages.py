#!/usr/bin/env python3
"""
Read required packages from plan-fmf and write to test-fmf.
"""

import argparse
import yaml

ARG_PARSER = argparse.ArgumentParser(
    description="Read required packages from plan-fmf and write to test-fmf.")
ARG_PARSER.add_argument('--pfmf',
                        dest='pfmf',
                        action='store',
                        help='plan fmf file',
                        default=None,
                        required=True)
ARG_PARSER.add_argument('--tfmf',
                        dest='tfmf',
                        action='store',
                        help='test fmf file',
                        default=None,
                        required=True)

ARGS = ARG_PARSER.parse_args()

require_section = []
with open(ARGS.pfmf, mode='r') as f:
    content = yaml.safe_load(f)
    for step in content['prepare']:
        if step.get('how') == 'install':
            require_section.append('require:\n')
            for pkg in step.get('package'):
                require_section.append('  - ' + pkg + '\n')
            break

if not require_section:
    print(f'Cannot read package list from {ARGS.pfmf}')
    exit(1)

with open(ARGS.tfmf, mode='r') as f:
    content = yaml.safe_load(f)

if content.get('require'):
    print(f'The "require" section already exists in {ARGS.tfmf}')
    exit(1)

new_text = ''
with open(ARGS.tfmf, mode='r') as f:
    text = f.readlines()
    for pos in range(len(text)):
        if text[pos].startswith('framework:'):
            new_text = text[:pos+1] + require_section + text[pos+1:]
            break

if not new_text:
    print(f'Cannot locate "framework" section in {ARGS.tfmf}')
    exit(1)

with open(ARGS.tfmf, mode='w') as f:
    f.writelines(new_text)

exit(0)
