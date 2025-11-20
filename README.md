# lum.core.sh

Simple core libraries for writing Bash scripts.

## Description

Every time I wrote a CLI script, I was using completely different methods
for registering commands, displaying help info, and generally just doing
the basic stuff that most CLI scripts need to do.

This is an attempt to rectify that, by writing a core library like I have
for [JS](https://github.com/supernovus/lum.core.js) 
and [PHP](https://github.com/supernovus/lum.core.php).

## Requirements

- Bash 4.4 or higher
- GNU coreutils or busybox
- sed
- (g)awk
- grep

## Future Development Plans (2024-02-15)

I am planning on a major revision of this entire system.
The current implementation, while very flexible, is not very efficient.
It is in fact quite slow compared to my older scripts.
A lot of that is due to the convoluted "inline" documentation system, but
there's several places that could be overhauled to be far more optimized.

I am planning to support a new _compiler_, which will take source files and 
use them to generate optimized executable scripts, extracting the documentation
for each command into its own pre-compiled script file, as well as several 
other potential optimizations.

As this would be a massive change, likely breaking backwards compatibility,
it will be released as version `2.0` of the core library, and existing
library extensions and scripts using the libraries would need to be reworked to
support the new compiled methodology.

### Update (2025-11-20)

Okay, it's been quite some time since I added the plans, and I haven't
touched any of these libraries. There's some good stuff hidden in this mess,
but trying to refactor this into something less convoluted is going to be more
work than simply pulling out any useful features and adding them to a new
library set that isn't convoluted to begin with. So that's my current plan.

## Author

Timothy Totten <2010@totten.ca>

## License

[MIT](https://spdx.org/licenses/MIT.html)
