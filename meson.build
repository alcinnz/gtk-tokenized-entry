project('tokenized-entry-test', ['vala', 'c'],
    version: '1.0.0',
    license: 'GNU',
    meson_version: '>=0.40.1')

executable('test-tokenized-entry',
    ['main.vala', 'tokenized.vala'],
    link_args: '-lm',
    dependencies: [dependency('gtk+-3.0'), dependency('gee-0.8')],
    install: false
)
