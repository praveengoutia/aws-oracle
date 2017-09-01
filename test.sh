declare GIT=/usr/bin/git

declare SCRIPT_DIR="/root/rsoradba"
declare GIT_DIR="$SCRIPT_DIR/aws-oracle"
declare INSTALL_SCRIPT=$GIT_DIR/Oracle11204EnterpriseEditionASM.sh

declare GIT_BASE="https://github.com/praveengoutia/aws-oracle"

cd $SCRIPT_DIR
$GIT clone $GIT_BASE

chmod 755 $INSTALL_SCRIPT
echo $INSTALL_SCRIPT
$INSTALL_SCRIPT
