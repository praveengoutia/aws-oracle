#!/bin/sh

#Oracle11204EnterpriseEditionASM.sh


declare YUM=/usr/bin/yum
declare WGET=/usr/bin/wget
declare GIT=/usr/bin/git
declare ORACLEASMLIB=/etc/init.d/oracleasm
declare UNZIP=/usr/bin/unzip

declare SCRIPT_DIR="/root/rsoradba"
declare GIT_DIR="$SCRIPT_DIR/aws-oracle"
#declare INSTALLCODE="Oracle11204EnterpriseEditionASM"
declare INPUTPARAMFILE="$SCRIPT_DIR/inputparameters.txt"
declare SCREATEDBMOUNT="$GIT_DIR/createdbmounts.sh"
declare SOFTWAREREPOMD="$GIT_DIR/swrepo.md"

declare CFPARAM_ORAVERSION=`grep CFADDBVERSION $INPUTPARAMFILE|cut -f2 -d ':'` 
declare CFPARAM_ORASTORAGETYPE=`grep CFAESTORAGETYPE $INPUTPARAMFILE|cut -f2 -d ':'` 
declare CFPARAM_ORASID=`grep CFAGORASID $INPUTPARAMFILE|cut -f2 -d ':'` 
declare CFPARAM_SYSPASSWORD=`grep CFAHSYSPASSWORD $INPUTPARAMFILE|cut -f2 -d ':'` 
declare CFPARAM_LISTENERPORT=`grep CFAILISTENERPORT $INPUTPARAMFILE|cut -f2 -d ':'` 
declare CFPARAM_CHARACTERSET=`grep CFAJCHARACTERSET $INPUTPARAMFILE|cut -f2 -d ':'` 
declare CFPARAM_NCHARACTERSET=`grep CFAJNCHARACTERSET $INPUTPARAMFILE|cut -f2 -d ':'` 
declare CFPARAM_ORABLOCKSIZE=`grep CFALBLOCKSIZE $INPUTPARAMFILE|cut -f2 -d ':'` 
declare CFPARAM_REPOUSER=`grep CFANREPOUSER $INPUTPARAMFILE|cut -f2 -d ':'` 
declare CFPARAM_REPOPWD=`grep CFAOREPOPASSWD $INPUTPARAMFILE|cut -f2 -d ':'` 

declare INSTALLCODE=`echo $CFPARAM_ORAVERSION|sed -e 's/ //g'|sed -e 's/\.//g'``echo $CFPARAM_ORASTORAGETYPE|sed -e 's/ //g'`

declare LINUX_KERNEL=`uname -r|rev|cut -f1,2 -d '.'|rev`
declare HOSTNAME=`hostname`
declare LINUX_KERNEL_EL6="el6.x86_64"
declare LINUX_KERNEL_EL7="el7.x86_64"

declare EC2METADATA_BASE="http://169.254.169.254/latest/meta-data/"
declare ORACLEASM_SUPPORT_RPM_EL6_LINK="http://oss.oracle.com/projects/oracleasm-support/dist/files/RPMS/rhel6/amd64/2.1.8/oracleasm-support-2.1.8-1.el6.x86_64.rpm"
declare ORACLEASMLIB_RPM_EL6_LINK="http://download.oracle.com/otn_software/asmlib/oracleasmlib-2.0.4-1.el6.x86_64.rpm"
declare ORACLEASM_SUPPORT_RPM_EL6="oracleasm-support-2.1.8-1.el6.x86_64.rpm"
declare ORACLEASMLIB_RPM_EL6="oracleasmlib-2.0.4-1.el6.x86_64.rpm"

declare ORACLEASM_SUPPORT_RPM_EL7_LINK="http://yum.oracle.com/repo/OracleLinux/OL7/latest/x86_64/getPackage/oracleasm-support-2.1.8-3.el7.x86_64.rpm"
declare ORACLEASMLIB_RPM_EL7_LINK="http://download.oracle.com/otn_software/asmlib/oracleasmlib-2.0.12-1.el7.x86_64.rpm"
declare ORACLEASMLIB_RPM_EL7="oracleasmlib-2.0.12-1.el7.x86_64.rpm"
declare ORACLEASM_SUPPORT_RPM_EL7="oracleasm-support-2.1.8-3.el7.x86_64.rpm"

declare DEVU01="/dev/xvdb"
declare DEVSWAP="/dev/xvdb2"
declare DEVDATA="/dev/xvdc"
declare DEVFRA="/dev/xvdd"
declare DATADG_NAME="DATA"
declare FRADG_NAME="FRA"



#Run yum update -y 
$YUM update -y

#Download and install Pre-install rpm
v_preinstall_link=`grep $INSTALLCODE $SOFTWAREREPOMD|grep PREINSTALL|grep $LINUX_KERNEL|cut -f3 -d "|"`
v_rpm_name=`echo $v_preinstall_link|rev|cut -f1 -d '/'|rev`
$WGET --http-user=$CFPARAM_REPOUSER --http-password=$CFPARAM_REPOPWD $v_preinstall_link

$YUM install $v_rpm_name -y --nogpgcheck --disableexcludes=all

## Install Oracleasm lib 
if [ "$CFPARAM_ORASTORAGETYPE" = "ASM" ]; then
	if [ "$LINUX_KERNEL" = "$LINUX_KERNEL_EL6" ]; then
		$WGET $ORACLEASM_SUPPORT_RPM_EL6_LINK
		$WGET $ORACLEASMLIB_RPM_EL6_LINK
		$YUM install kmod-oracleasm -y
		$YUM localinstall $ORACLEASMLIB_RPM_EL6 -y
		$YUM localinstall $ORACLEASM_SUPPORT_RPM_EL6 -y	
	else
		if [ "$LINUX_KERNEL" = "$LINUX_KERNEL_EL7" ]; then
			$WGET $ORACLEASM_SUPPORT_RPM_EL7_LINK
			$WGET $ORACLEASMLIB_RPM_EL7_LINK
			$YUM install kmod-oracleasm -y
			$YUM localinstall $ORACLEASMLIB_RPM_EL7 -y
			$YUM localinstall $ORACLEASM_SUPPORT_RPM_EL7 -y				
		fi
	fi

	$ORACLEASMLIB configure<<EOM
	grid
	asmadmin
	y
	y
EOM
	
fi

#Format DEVU01=/dev/xvdb
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${DEVU01}
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


##Create Swap
mkswap "$DEVSWAP">/tmp/swapon.1
swapuuid=`grep UUID /tmp/swapon.1|cut -f2 -d =`
swapon -U ${swapuuid}
echo "UUID=$swapuuid    swap		swap    defaults        0 0">>/etc/fstab


##Mount /u01
pvcreate "$DEVU01"1
vgcreate vgu01 "$DEVU01"1
lvcreate -L 100G -n lvu01 vgu01
mkfs.ext4 /dev/vgu01/lvu01
mkdir /u01
echo "/dev/mapper/vgu01-lvu01   /u01 		ext4 		defaults	0 0">>/etc/fstab
mount -a


##DEVDATA="/dev/xvdc"
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${DEVDATA}
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

##DEVFRA="/dev/xvdd"
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | fdisk ${DEVFRA}
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

if [ "$CFPARAM_ORASTORAGETYPE" = "ASM" ]; then
	$ORACLEASMLIB createdisk "$DATADG_NAME"001 "$DEVDATA"1
	$ORACLEASMLIB createdisk "$FRADG_NAME"001 "$DEVFRA"1
	$ORACLEASMLIB listdisks
fi

if [ "$CFPARAM_ORASTORAGETYPE" = "File System" ]; then
	$SCREATEDBMOUNT "$DEVDATA" "$DATADG_NAME"
	$SCREATEDBMOUNT "$DEVFRA" "$FRADG_NAME"
fi

##Modify /etc/hosts
$WGET $EC2METADATA_BASE/local-ipv4 -O $SCRIPT_DIR/local-ipv4

echo "`head $SCRIPT_DIR/local-ipv4`     $HOSTNAME">>/etc/hosts

##Download software
if [ "$CFPARAM_ORASTORAGETYPE" = "ASM" ]; then
	GIZIP1=`grep $INSTALLCODE $SOFTWAREREPOMD|grep $LINUX_KERNEL|grep GRID1|cut -f3 -d "|"`
	GIZIP1_NAME=`echo $GIZIP1|rev|cut -f1 -d '/'|rev`
	$WGET --http-user=$CFPARAM_REPOUSER --http-password=$CFPARAM_REPOPWD $GIZIP1 -O $SCRIPT_DIR/$GIZIP1_NAME
	
	GIZIP2=`grep $INSTALLCODE $SOFTWAREREPOMD|grep $LINUX_KERNEL|grep GRID2|cut -f3 -d "|"`
	GIZIP2_NAME=`echo $GIZIP2|rev|cut -f1 -d '/'|rev`
	$WGET --http-user=$CFPARAM_REPOUSER --http-password=$CFPARAM_REPOPWD $GIZIP2 -O $SCRIPT_DIR/$GIZIP2_NAME	
	cd $SCRIPT_DIR
	$UNZIP $GIZIP1_NAME
	$UNZIP $GIZIP2_NAME	
fi

RDBMSZIP1=`grep $INSTALLCODE $SOFTWAREREPOMD|grep $LINUX_KERNEL|grep RDBMS1|cut -f3 -d "|"`
RDBMSZIP1_NAME=`echo $RDBMSZIP1|rev|cut -f1 -d '/'|rev`
$WGET --http-user=$CFPARAM_REPOUSER --http-password=$CFPARAM_REPOPWD $RDBMSZIP1 -O $SCRIPT_DIR/$RDBMSZIP1_NAME

RDBMSZIP2=`grep $INSTALLCODE $SOFTWAREREPOMD|grep $LINUX_KERNEL|grep RDBMS2|cut -f3 -d "|"`
RDBMSZIP2_NAME=`echo $RDBMSZIP2|rev|cut -f1 -d '/'|rev`
$WGET --http-user=$CFPARAM_REPOUSER --http-password=$CFPARAM_REPOPWD $RDBMSZIP2 -O $SCRIPT_DIR/$RDBMSZIP2_NAME	
cd $SCRIPT_DIR
$UNZIP $RDBMSZIP1_NAME
$UNZIP $RDBMSZIP2_NAME
	
	
