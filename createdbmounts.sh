###
#Script Name: createdbmounts.sh
#
###

diskname=$1
mountpointname=$2
volgrpname=$mountpointname"_vg"
lvdiskname=$mountpointname"_lv"

mkdir "/$mountpointname"

##Mount /u01
pvcreate $diskname
vgcreate $volgrpname $diskname
vextentnum=`vgdisplay $volgrpname|grep 'Total PE'|awk '{print $3}'`
lvcreate -l $vextentnum -n $lvdiskname $volgrpname
mkfs.ext4 /dev/$volgrpname/$lvdiskname
echo "/dev/mapper/$volgrpname-$lvdiskname   /$mountpointname 		ext4 		defaults	0 0">>/etc/fstab
mount -a
