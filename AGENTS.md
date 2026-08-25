# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`pupmod-simp-rngd` is a SIMP Puppet module that manages the `rngd`
entropy-gathering daemon from `rng-tools`. It replaces `pupmod-simp-haveged`
(the `haveged` daemon is obsolete on kernels 5.6+, where the kernel entropy
pool no longer blocks).

It is intentionally small and deliberately **minimizes blast radius**: a bare
`include rngd` installs the `rng-tools` package and does *nothing else*. In
particular, the `rngd` service is **left unmanaged by default** — service
management is opt-in.

### Business logic

All behavior lives in the one class, `rngd` (`manifests/init.pp`):

- **`$package_name`** / **`$service_name`** (`String[1]`, no default in code) —
  resolved from module hiera data (`hiera.yaml` + `data/`), keyed on
  `os.family`:
  - RedHat (default, `data/common.yaml`): package `rng-tools`, service `rngd`
  - Debian/Ubuntu (`data/Debian.yaml`): package `rng-tools5` (upstream
    rng-tools; the distro's `rng-tools`/`rng-tools-debian` are an older fork),
    service `rngd`
  - SLES (`data/Suse.yaml`): package `rng-tools` (from SUSE Package Hub),
    service `rng-tools`
- **`$package_ensure`** (`String[1]`, default
  `simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' })`) —
  the package state. Follows the standard SIMP pattern of deferring to the
  site-wide `simp_options::package_ensure` hiera key when set.
- **`$service_ensure`** (`Optional[Stdlib::Ensure::Service]`, default `undef`)
  and **`$service_enable`** (`Optional[Boolean]`, default `undef`) — the
  `service { $service_name: }` resource is only declared when at least one of
  these is non-`undef`. When declared, it carries
  `require => Package[$package_name]`.

There are no other classes, defined types, facts, functions, or templates.

**Do not add automatic service management, config-file ownership, or
`simp_options::*` feature opt-ins to the bare include** — the safe default is
the point of this module's design (see the SIMP "reduce blast radius"
pattern).

## Dependencies

- `simp/simplib` — provides `simplib::lookup`.
- `puppetlabs/stdlib` — provides `Stdlib::Ensure::Service`.
- Runtime: `openvox >= 8.0.0 < 9.0.0` (see `metadata.json` `requirements`).

## Repository layout

- `manifests/init.pp` — the entire module (class `rngd`).
- `hiera.yaml` + `data/` — per-OS-family package/service names.
- `spec/classes/init_spec.rb` — rspec-puppet unit tests. EL platforms come
  from the SIMP factsets (`simp-rspec-puppet-facts`); Debian/Ubuntu/SLES fall
  back to the upstream rspec-puppet-facts (FacterDB) factsets via
  `Simp::RspecPuppetFacts::Shim.on_supported_os`, skipping releases the
  installed FacterDB doesn't carry.
- `spec/acceptance/suites/default/` — beaker acceptance suite; `nodesets/`
  holds the per-OS node definitions (EL only; hypervisor selected with
  `BEAKER_HYPERVISOR`, default vagrant).
- `REFERENCE.md` — generated Puppet Strings reference (do not hand-edit; regenerate).
- `metadata.json` — module metadata, dependencies, and supported OS matrix.

## Common commands

This module uses `puppetlabs_spec_helper` + `simp-rake-helpers (~> 5)`
+ `simp-beaker-helpers (~> 2)`; tasks come from `Simp::Rake::Pupmod::Helpers`
(see `Rakefile`).

```sh
bundle install

# Unit tests (rspec-puppet)
bundle exec rake spec

# Lint / style
bundle exec rake lint
bundle exec rake rubocop

# Regenerate REFERENCE.md after changing manifest docstrings
bundle exec rake strings:generate:reference

# Acceptance tests (beaker; needs a hypervisor — CI uses vagrant_libvirt)
bundle exec rake beaker:suites[default]
# or a specific node set:
bundle exec rake beaker:suites[default,el9]
```

Note `.rspec` sets `--fail-fast`, so `rake spec` stops at the first failure.

## Conventions

- This is a component of the SIMP ecosystem. Follow SIMP module conventions:
  parameters that reflect site-wide policy are resolved through
  `simp_options::*` hiera keys via `simplib::lookup`, defaulting to safe values
  so the module works standalone.
- Keep manifest parameter `@param` docstrings current — `REFERENCE.md` is
  generated from them.
- Files marked `**This file is maintained with puppetsync**` are managed by
  the SIMP puppetsync baseline; do not hand-edit them here.
