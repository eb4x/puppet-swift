require 'spec_helper'

describe 'swift::storage::mount' do
  let :title do
    'dans_mount_point'
  end

  shared_examples 'swift::storage::mount' do
    describe 'with defaults params' do
      let :params do
        {
          :device => '/dev/sda'
        }
      end

      it { is_expected.to contain_mount('/srv/node/dans_mount_point').with(
        :ensure  => 'present',
        :device  => '/dev/sda',
        :fstype  => 'xfs',
        :options => 'noatime,nodiratime,nofail,logbufs=8',
      )}
    end

    describe 'when mounting a loopback device' do
      let :params do
        {
          :device   => '/dev/sda',
          :loopback => true
        }
      end

      it { is_expected.to contain_mount('/srv/node/dans_mount_point').with(
        :device  => '/dev/sda',
        :options => 'noatime,nodiratime,nofail,loop,logbufs=8'
      )}
    end

    describe 'when mounting a loopback device on selinux system' do
      let :params do
        {
          :device => '/dev/sda'
        }
      end

      before do
        facts[:os]['selinux']['enabled'] = 'true'
      end

      it { is_expected.to contain_exec("restorecon_mount_dans_mount_point").with(
        :command     => "restorecon /srv/node/dans_mount_point",
        :path        => ['/usr/sbin', '/sbin'],
        :refreshonly => true
      )}
    end
  end

  on_supported_os({
    :supported_os => OSDefaults.get_supported_os
  }).each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge(OSDefaults.get_facts())
      end

      it_configures 'swift::storage::mount'
    end
  end
end
