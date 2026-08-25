[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/rngd.svg)](https://forge.puppetlabs.com/simp/rngd)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/rngd.svg)](https://forge.puppetlabs.com/simp/rngd)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with rngd](#setup)
    * [What rngd affects](#what-rngd-affects)
    * [Beginning with rngd](#beginning-with-rngd)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Limitations - OS compatibility, etc.](#limitations)
5. [Development - Guide for contributing to the module](#development)
      * [Acceptance Tests - Beaker env variables](#acceptance-tests)

## Description

This module installs the `rng-tools` package and can optionally manage the
`rngd` entropy-gathering daemon service.

By default, it **only installs the package** — the service is left unmanaged
so that a bare `include rngd` has the smallest possible blast radius. Set
`rngd::service_ensure` and/or `rngd::service_enable` to opt in to service
management.

This module replaces [pupmod-simp-haveged](https://github.com/simp/pupmod-simp-haveged).
On Linux kernels 5.6 and later the in-kernel entropy pool no longer blocks,
so a userspace entropy daemon is rarely required; where one is (e.g. to feed
a hardware TRNG to the kernel entropy pool), opt in to service management
explicitly.

See [REFERENCE.md](./REFERENCE.md) for additional information.

### This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they can be submitted to our [issue tracker](https://github.com/simp/pupmod-simp-rngd/issues).

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html)

This module is optimally designed for use within a larger SIMP ecosystem, but it can be used independently:
* When included within the SIMP ecosystem, security compliance settings will be managed from the Puppet server.
* If used independently, all SIMP-managed security subsystems are disabled by default and must be explicitly opted into by administrators.  Please review the simp_options module for details.

## Setup

### What rngd affects

* installs the `rng-tools` package (`rng-tools5` on Debian and Ubuntu)
* optionally manages the `rngd` service (`rng-tools` on SLES) — unmanaged
  unless `rngd::service_ensure` and/or `rngd::service_enable` are set

### Beginning with rngd

To install the package, just include the class:

```puppet
include 'rngd'
```

## Usage

To also run and enable the `rngd` service:

```puppet
class { 'rngd':
  service_ensure => 'running',
  service_enable => true,
}
```

Or via Hiera:

```yaml
rngd::service_ensure: 'running'
rngd::service_enable: true
```

You can optionally pin the version of the `rng-tools` package by specifying
the `$package_ensure` parameter when calling the class:

```puppet
class { 'rngd':
  package_ensure => 'latest',
}
```

## Limitations

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux
and compatible distributions, such as CentOS. This module additionally
supports Debian, Ubuntu, and SLES. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

On SLES, the `rng-tools` package is available via the SUSE Package Hub
extension, which must be enabled separately.

## Development

Please see the [SIMP Contribution Guidelines](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).


### Acceptance tests

This module includes [Beaker](https://github.com/puppetlabs/beaker) acceptance tests using the SIMP [Beaker Helpers](https://github.com/simp/rubygem-simp-beaker-helpers).  By default the tests use [Vagrant](https://www.vagrantup.com/) with [VirtualBox](https://www.virtualbox.org) as a back-end; Vagrant and VirtualBox must both be installed to run these tests without modification. To execute the tests run the following:

```shell
bundle install
bundle exec rake beaker:suites
```

The hypervisor can be overridden with the `BEAKER_HYPERVISOR` environment
variable (e.g. `BEAKER_HYPERVISOR=docker`). Note that the service-management
portion of the suite requires the `rngd` daemon to be able to feed the kernel
entropy pool (the `RNDADDENTROPY` ioctl requires `CAP_SYS_ADMIN`), so under
Docker it will only pass in privileged containers; the package-only (default)
behavior works anywhere.

Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md) for more information.

Some environment variables may be useful:

```shell
BEAKER_debug=true
BEAKER_provision=no
BEAKER_destroy=no
BEAKER_use_fixtures_dir_for_modules=yes
```

* `BEAKER_debug`: show the commands being run on the STU and their output.
* `BEAKER_destroy=no`: prevent the machine destruction after the tests finish so you can inspect the state.
* `BEAKER_provision=no`: prevent the machine from being recreated. This can save a lot of time while you're writing the tests.
* `BEAKER_use_fixtures_dir_for_modules=yes`: cause all module dependencies to be loaded from the `spec/fixtures/modules` directory, based on the contents of `.fixtures.yml`.  The contents of this directory are usually populated by `bundle exec rake spec_prep`.  This can be used to run acceptance tests to run on isolated networks.
