#!/usr/bin/env bash

##############################################################
# @Filename:    mongodb_migration.sh     
# @Version:     
# @Created:     10.19.2017
# @Author:       
# @Description: 
# @History:     date time modify params xxxx
# @Usage:       ./mongodb_migration.sh 
##############################################################

[ $(whoami) != "root" ] && echo " You must use root account" && exit 1

dir_name=$(cd $(dirname$0) && pwd)
mkdir -p ${dir_name}/mongodb_migration/dumppath

local_ip=$(/sbin/ifconfig eth0|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
date_t=$(date +%Y%m%d)


backup_mongodb(){
	read -s -p "Please Enter Mongo password:" mongo_auth
        mongo_user=root

        mongo_port=$(cat /etc/mongod.conf |grep port|awk -F: '{gsub(/[[:blank:]]*/,"",$2);print $2}')
        mongo_ip=$(cat /etc/mongod.conf |grep bindIp|awk -F: '{gsub(/[[:blank:]]*/,"",$2);print $2}')

        mongodump -h ${mongo_ip} --port=${mongo_port} -u ${mongo_user} -p ${mongo_auth} --authenticationDatabase=admin -o ${dir_name}/mongodb_migration/dumppath
}         
         
migration_shell(){
cat > ${dir_name}/mongodb_migration/mongodb_migration.sh << EOF
#!/bin/bash

[ \$(whoami) != "root" ] && echo " You must use root account" && exit 1

dir_name=\$(pwd)

read -s -p "Please Enter Mongo password:" mongo_auth
mongo_user=root
    
mongo_port=\$(cat /etc/mongod.conf |grep port|awk -F: '{gsub(/[[:blank:]]*/,"",\$2);print \$2}')
mongo_ip=\$(cat /etc/mongod.conf |grep bindIp|awk -F: '{gsub(/[[:blank:]]*/,"",\$2);print \$2}')
    
mongorestore -h \${mongo_ip} --port=\${mongo_port} -u \${mongo_user} -p \${mongo_auth} --authenticationDatabase=admin --dir \${dir_name}/dumppath
EOF
}

tar_package(){
	tar zcvf mongodb_dump_${local_ip}_${date_t}.tar.gz -C ${dir_name} mongodb_migration 
	sha256sum mongodb_dump_${local_ip}_${date_t}.tar.gz > ${dir_name}/mongodb_dump_${local_ip}_${date_t}.hash
	tar zcvf mongodb_migration_${local_ip}_${date_t}.tar.gz mongodb_dump_${local_ip}_${date_t}.tar.gz mongodb_dump_${local_ip}_${date_t}.hash
	rm -rf mongodb_dump_${local_ip}_${date_t}.tar.gz mongodb_dump_${local_ip}_${date_t}.hash mongodb_migration
}

backup_mongodb
migration_shell
tar_package
