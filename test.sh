#File name: test.sh


declare SCRIPT_DIR="/root/rsoradba"
declare INPUTPARAMFILE="$SCRIPT_DIR/inputparameters.txt"
declare SCREATEDBMOUNT="$SCRIPT_DIR/createdbmounts.sh"

declare GIT_BASE="https://raw.githubusercontent.com/praveengoutia/aws-oracle/master"
declare PREINSTALL_11G="http://dfworacle1.racscan.com/Linux/x86-64/11gR2/preinstall/oracle-rdbms-server-11gR2-preinstall-1.0-1.el6.x86_64.rpm"
declare PREINSTALL_12C="http://dfworacle1.racscan.com/Linux/x86-64/12cR1/preinstall/oracle-rdbms-server-12cR1-preinstall-1.0-1.el6.x86_64.rpm  "
declare ORAASMLIBSUPPORT="http://oss.oracle.com/projects/oracleasm-support/dist/files/RPMS/rhel6/amd64/2.1.8/oracleasm-support-2.1.8-1.el6.x86_64.rpm"
declare ORAASMLIB="http://download.oracle.com/otn_software/asmlib/oracleasmlib-2.0.4-1.el6.x86_64.rpm"

declare REPOUSER=`grep CFANREPOUSER $INPUTPARAMFILE|cut -f2 -d ':'` 
declare REPOPWD=`grep CFAOREPOPASSWD $INPUTPARAMFILE|cut -f2 -d ':'` 

wget "$GIT_BASE/createdbmounts.sh"
chmod 755 "$SCREATEDBMOUNT" 

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
pvcreate /dev/xvdb1
vgcreate vgu01 /dev/xvdb1
lvcreate -L 100G -n lvu01 vgu01
mkfs.ext4 /dev/vgu01/lvu01
mkdir /u01
echo "/dev/mapper/vgu01-lvu01   /u01 		ext4 		defaults	0 0">>/etc/fstab
mount -a

##Install rpm
yum update -y
v_oracle_version=`grep CFADDBVERSION $INPUTPARAMFILE|cut -f2 -d ':'` 
if [ "$v_oracle_version" = "Oracle 11.2.0.4 Enterprise Edition" -o "$v_oracle_version" = "Oracle 11.2.0.4 Standard Edition" ]; then
	wget --http-user=$REPOUSER --http-password=$REPOPWD $PREINSTALL_11G
	yum install oracle-rdbms-server-11gR2-preinstall-1.0-1.el6.x86_64.rpm -y --nogpgcheck --disableexcludes=all
else
	wget --http-user=$REPOUSER --http-password=$REPOPWD $PREINSTALL_12C
	yum install oracle-rdbms-server-12cR1-preinstall-1.0-1.el6.x86_64.rpm -y --nogpgcheck --disableexcludes=all
fi

##Check type of storage choose for Oracle 
v_storage_type=`grep CFAESTORAGETYPE $INPUTPARAMFILE|cut -f2 -d ':'` 
if [ "$v_storage_type" = "File System" ]; then
##call script to create data and fra mount point
	v_datasize=`grep CFAFDATASIZE $INPUTPARAMFILE|cut -f2 -d ':'|sed "s/^0*//"` 
	v_frasize=`grep CFAGFRASIZE $INPUTPARAMFILE|cut -f2 -d ':'|sed "s/^0*//"` 
	$SCREATEDBMOUNT "/dev/xvdc1" DATA $v_datasize
	$SCREATEDBMOUNT "/dev/xvdd1" FRA $v_frasize
else
##call script to create data and fra disks
	echo " "
	wget $ORAASMLIBSUPPORT
	wget $ORAASMLIB
	yum install kmod-oracleasm -y
	yum localinstall oracleasmlib-2.0.4-1.el6.x86_64.rpm -y
	yum localinstall oracleasm-support-2.1.8-1.el6.x86_64.rpm -y
	oracleasm init
	/etc/init.d/oracleasm configure<<EOM
	grid
	asmadmin
	y
	y
EOM

/etc/init.d/oracleasm createdisk DATA001 /dev/xvdc1
/etc/init.d/oracleasm createdisk FRA001 /dev/xvdd1
/etc/init.d/oracleasm listdisks
fi
