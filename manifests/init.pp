# This class manages the rngd entropy-gathering daemon from rng-tools.
#
# By default, this class only installs the rng-tools package. The `rngd`
# service is left unmanaged unless `$service_ensure` and/or `$service_enable`
# are set, keeping the blast radius of a bare `include rngd` as small as
# possible.
#
# This module replaces `pupmod-simp-haveged`. On kernels 5.6 and later the
# in-kernel entropy pool no longer blocks, so a userspace entropy daemon is
# rarely required; where one is (e.g. to feed a hardware TRNG to the kernel),
# opt in to service management explicitly.
#
# @param package_name
#   The name of the rng-tools package
#
# @param service_name
#   The name of the rngd service
#
# @param package_ensure
#   Management of the rng-tools package
#
# @param service_ensure
#   The state of the rngd service
#
#   * If this and `$service_enable` are both `undef` (the default), the
#     service is left unmanaged
#
# @param service_enable
#   Whether the rngd service should be enabled to start at boot
#
#   * If this and `$service_ensure` are both `undef` (the default), the
#     service is left unmanaged
#
# @author https://github.com/simp/pupmod-simp-rngd/graphs/contributors
#
class rngd (
  String[1]                         $package_name,
  String[1]                         $service_name,
  String[1]                         $package_ensure = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  Optional[Stdlib::Ensure::Service] $service_ensure = undef,
  Optional[Boolean]                 $service_enable = undef,
) {
  package { $package_name: ensure => $package_ensure }

  if ($service_ensure =~ NotUndef) or ($service_enable =~ NotUndef) {
    service { $service_name:
      ensure     => $service_ensure,
      enable     => $service_enable,
      hasstatus  => true,
      hasrestart => true,
      require    => Package[$package_name],
    }
  }
}
