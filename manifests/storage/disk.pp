# This Puppet resource is based on the following
# instructions for creating a disk device:
# https://docs.openstack.org/swift/latest/development_saio.html
#
# ==Add a raw disk to a swift storage node==
#
# It will do two steps to create a disk device:
#   - creates a disk table, use the whole disk instead
#     to make the partition (e.g. use sdb as a whole)
#   - formats the partition to an xfs device and
#     mounts it as a block device at /srv/node/$name
#
# ATTENTION: You should not use the disk that your Operating System
#            is installed on (typically /dev/sda/).
#
# === Parameters:
#
# [*base_dir*]
#   (optional) The directory where the flat files will be stored that house
#   the file system to be loop back mounted.
#   Defaults to '/dev', assumes local disk devices
#
# [*mnt_base_dir*]
#   (optional) The directory where the flat files that store the file system
#   to be loop back mounted are actually mounted at.
#   Defaults to '/srv/node', base directory where disks are mounted to
#
# [*byte_size*]
#   (optional) The byte size that dd uses when it creates the file system.
#   Defaults to '1024', block size for the disk.  For very large partitions, this should be larger
#
# [*ext_args*]
#   (optional) The external command that will be used in parted command.
#   Default to ''. For making partitions, it would be 'mkpart primary 0% 100%'.
#
# [*manage_partition*]
#   (optional) If set to false, skip calling parted which can, in some cases,
#   increase the load on the server. This is to set to false only after the
#   server is fully setup or if the partition was created outside of puppet.
#   Defaults to true.
#
# [*manage_filesystem*]
#   (optional) If set to false, skip calling xfs_admin -l to check if a
#   partition needs to be formatted with mkfs.xfs, which can, in some cases,
#   increase the load on the server. This is to set to false only after the
#   server is fully setup, or if the filesystem was created outside of puppet.
#   Defaults to true.
#
# =Example=
#
# Simply add one disk sdb:
#
# swift::storage::disk { "sdb":}
#
# Add more than one disks and overwrite byte_size:
#
# swift::storage::disk {['sdb','sdc','sdd']:
#   byte_size   =>   '2048',
#   }
#
# TODO(yuxcer): maybe we can remove param $base_dir
#
define swift::storage::disk(
  $base_dir          = '/dev',
  $mnt_base_dir      = '/srv/node',
  $byte_size         = '1024',
  $ext_args          = '',
  $manage_partition  = true,
  $manage_filesystem = true,
) {

  include swift::deps
  include swift::params

  if(!defined(File[$mnt_base_dir])) {
    file { $mnt_base_dir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      require => Anchor['swift::config::begin'],
      before  => Anchor['swift::config::end'],
    }
  }

  if $manage_partition {
    exec { "create_partition_label-${name}":
      command => "parted -s ${base_dir}/${name} mklabel gpt ${ext_args}",
      path    => ['/usr/bin/', '/sbin','/bin'],
      onlyif  => ["test -b ${base_dir}/${name}","parted ${base_dir}/${name} print|tail -1|grep 'Error'"],
      before  => Anchor['swift::config::end'],
    }
    Exec["create_partition_label-${name}"] ~> Swift::Storage::Xfs<| title == $name |>
  }

  swift::storage::xfs { $name:
    device            => "${base_dir}/${name}",
    mnt_base_dir      => $mnt_base_dir,
    byte_size         => $byte_size,
    loopback          => false,
    manage_filesystem => $manage_filesystem,
  }

}
