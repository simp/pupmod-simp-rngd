require 'spec_helper'

# Expected per-OS-family package/service names (see hiera.yaml + data/)
def expected_names(os_facts)
  case os_facts[:os]['family']
  when 'Debian'
    { package: 'rng-tools5', service: 'rngd' }
  when 'Suse'
    { package: 'rng-tools', service: 'rng-tools' }
  else
    { package: 'rng-tools', service: 'rngd' }
  end
end

# Shared examples used for both the SIMP (EL) factsets and the upstream
# rspec-puppet-facts (Debian/Ubuntu/SLES) factsets.
shared_examples 'rngd' do |os_facts|
  let(:names) { expected_names(os_facts) }

  context 'with default parameters' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('rngd') }
    it { is_expected.to contain_package(names[:package]).with(ensure: 'installed') }

    # The safe default: a bare `include rngd` must not manage the service
    it { is_expected.not_to contain_service(names[:service]) }
    it 'does not declare any Service resources' do
      expect(catalogue.resources.select { |r| r.type == 'Service' }).to be_empty
    end
  end

  context 'with a non-default $package_ensure' do
    let(:params) { { package_ensure: 'latest' } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_package(names[:package]).with(ensure: 'latest') }
  end

  # Exercises the actual SIMP business logic: with no parameter passed,
  # $package_ensure resolves via simplib::lookup('simp_options::package_ensure').
  # The hieradata fixture sets it to a value distinct from the default so a
  # pass proves the lookup path (not the default) supplied it.
  # See spec/fixtures/hieradata/package_ensure.yaml.
  context 'with simp_options::package_ensure set in hiera' do
    let(:hieradata) { 'package_ensure' }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_package(names[:package]).with(ensure: '6.16') }
  end

  context 'with service_ensure and service_enable set' do
    let(:params) { { service_ensure: 'running', service_enable: true } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_service(names[:service]).that_requires("Package[#{names[:package]}]") }
    it do
      is_expected.to contain_service(names[:service])
        .with(
          ensure: 'running',
          enable: true,
          hasstatus: true,
          hasrestart: true,
        )
    end
  end

  # Either service parameter alone is enough to opt in to service management;
  # the other property is left unmanaged on the resource.
  context 'with only service_ensure set' do
    let(:params) { { service_ensure: 'stopped' } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_service(names[:service]).with(ensure: 'stopped') }
    it { is_expected.to contain_service(names[:service]).without_enable }
  end

  context 'with only service_enable set' do
    let(:params) { { service_enable: false } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_service(names[:service]).with(enable: false) }
    it { is_expected.to contain_service(names[:service]).without_ensure }
  end

  context 'with the package removed ($package_ensure => absent)' do
    let(:params) { { package_ensure: 'absent' } }

    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_package(names[:package]).with(ensure: 'absent') }
  end
end

describe 'rngd' do
  # EL platforms, from the SIMP factsets
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      # Only base OS facts are provided (no module-specific facts), so these
      # examples also prove the module compiles cleanly with nothing extra set.
      let(:facts) { os_facts }

      it_behaves_like 'rngd', os_facts
    end
  end

  # Debian, Ubuntu, and SLES have no SIMP factsets, so fall back to the
  # upstream rspec-puppet-facts (FacterDB) factsets for them.
  # Simp::RspecPuppetFacts::Shim.on_supported_os is the simp gem's explicit
  # binding to the upstream implementation. Releases missing from the
  # installed FacterDB are skipped with a warning rather than failing.
  non_el_os = [
    { 'operatingsystem' => 'Debian', 'operatingsystemrelease' => ['12', '13'] },
    { 'operatingsystem' => 'Ubuntu', 'operatingsystemrelease' => ['22.04', '24.04'] },
    { 'operatingsystem' => 'SLES', 'operatingsystemrelease' => ['15'] },
  ]

  non_el_os.each do |os_entry|
    os_entry['operatingsystemrelease'].each do |release|
      candidate = [os_entry.merge('operatingsystemrelease' => [release])]

      begin
        upstream_facts = Simp::RspecPuppetFacts::Shim.on_supported_os(supported_os: candidate)
      rescue StandardError => e
        warn "Skipping #{os_entry['operatingsystem']} #{release}: #{e.message}"
        next
      end

      if upstream_facts.empty?
        warn "Skipping #{os_entry['operatingsystem']} #{release}: no factset in the installed FacterDB"
        next
      end

      upstream_facts.each do |os, os_facts|
        context "on #{os} (upstream factset)" do
          let(:facts) { os_facts }

          it_behaves_like 'rngd', os_facts
        end
      end
    end
  end
end
