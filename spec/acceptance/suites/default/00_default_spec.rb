require 'spec_helper_acceptance'

test_name 'rngd class'

describe 'rngd class' do
  let(:manifest) do
    <<-EOS
      include 'rngd'
    EOS
  end

  let(:service_manifest) do
    <<-EOS
      class { 'rngd':
        service_ensure => 'running',
        service_enable => true,
      }
    EOS
  end

  hosts.each do |host|
    context "on #{host}" do
      # Exercise noop from a clean (uninstalled) state: a noop apply should
      # report the module's intended changes without enacting them, so the
      # package must remain absent afterward. Real idempotence is covered by
      # the apply below. A *post-convergence* noop check is deliberately
      # omitted: `puppet apply --noop --detailed-exitcodes` always exits 0
      # regardless of pending changes, so a catch_changes+noop assertion can
      # never fail and would test nothing.
      context 'in noop mode from a clean state' do
        # Setup, not an assertion: a failure here should error the context
        # rather than abort the suite under --fail-fast. `puppet resource`
        # exits 0 whether it removes the package or finds it already absent
        # (it does not use --detailed-exitcodes), so no acceptable_exit_codes
        # override is needed.
        before(:context) do
          on(host, 'puppet resource package rng-tools ensure=absent')
        end

        it 'applies without errors in noop mode' do
          apply_manifest_on(host, manifest, catch_failures: true, noop: true)
        end

        describe package('rng-tools') do
          it 'is not installed by the noop run' do
            is_expected.not_to be_installed
          end
        end
      end

      context 'with default parameters' do
        it 'works with no errors' do
          apply_manifest_on(host, manifest, catch_failures: true)
        end

        it 'is idempotent' do
          apply_manifest_on(host, manifest, catch_changes: true)
        end

        describe package('rng-tools') do
          it { is_expected.to be_installed }
        end

        # The safe default: a bare `include rngd` must leave the service
        # alone entirely, whatever state the package/preset left it in.
        it 'does not manage the rngd service' do
          result = apply_manifest_on(host, manifest, catch_failures: true)
          expect(result.stdout).not_to match(%r{Service\[})
        end
      end

      context 'with service management enabled' do
        it 'works with no errors' do
          apply_manifest_on(host, service_manifest, catch_failures: true)
        end

        it 'is idempotent' do
          apply_manifest_on(host, service_manifest, catch_changes: true)
        end

        describe service('rngd') do
          it { is_expected.to be_enabled }
          it { is_expected.to be_running }
        end
      end
    end
  end
end
