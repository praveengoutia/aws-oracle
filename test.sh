#File name: test.sh
##Format disk xvdb
TGTDEV=/dev/xvdb
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
  +100G # /u01 partition
  n # new partition
  p # primary partition
  2 # partion number 2
    # default, start immediately after preceding partition
  +16G # Swap partition
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

##Format disk xvdc
TGTDEV=/dev/xvdc
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
        # default, extend partition to end of disk
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

##Format disk xvdd
TGTDEV=/dev/xvdd
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${TGTDEV}
  o # clear the in memory partition table
  n # new partition
  p # primary partition
  1 # partition number 1
    # default - start at beginning of disk
        # default, extend partition to end of disk
  p # print the in-memory partition table
  w # write the partition table
  q # and we're done
EOF

##Create Swap
mkswap /dev/xvdb2>/tmp/swapon.1
swapuuid=`grep UUID /tmp/swapon.1|cut -f2 -d =`
swapon -U ${swapuuid}
echo "UUID=$swapuuid    swap		swap    defaults        0 0">>/etc/fstab


##Mount /u01
mkfs.ext4  /dev/xvdb1
createpv /dev/xvdb1
vgcreate vgu01 /dev/xvdb1
lvcreate -L 100G -n lvu01 vgu01
mkfs.ext4 /dev/vgu01/lvu01

echo "/dev/mapper/vgu01-lvu01   /u01 		ext4 		defaults	0 0">>/etc/fstab
mount -a
