
#!/bin/bash





# prepare build tools
sudo apt-get update && sudo apt-get install --yes --no-install-recommends ca-certificates build-essential git libssl-dev curl cpio bspatch vim gettext bc bison flex dosfstools kmod jq
root=`pwd`
workpath="DS3622xsp-7.1.0"
mkdir $workpath
build_para="7.1.0-42550"
mkdir output
cd $workpath


# download redpill
git clone -b develop --depth=1 https://github.com/dogodefi/redpill-lkm.git
git clone -b develop --depth=1 https://github.com/dogodefi/redpill-load.git

# download syno toolkit
curl --location "https://global.download.synology.com/download/ToolChain/toolkit/7.0/broadwellnk/ds.broadwellnk-7.0.dev.txz" --output ds.broadwellnk-7.0.dev.txz

mkdir broadwellnk
tar -C./broadwellnk/ -xf ds.broadwellnk-7.0.dev.txz usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build

# build redpill-lkm
cd redpill-lkm
sed -i 's/   -std=gnu89/   -std=gnu89 -fno-pie/' ../broadwellnk/usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build/Makefile
make LINUX_SRC=../broadwellnk/usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build dev-v7
read -a KVERS <<< "$(sudo modinfo --field=vermagic redpill.ko)" && cp -fv redpill.ko ../redpill-load/ext/rp-lkm/redpill-linux-v${KVERS[0]}.ko || exit 1
cd ..

# download old pat for syno_extract_system_patch # thanks for jumkey's idea.
mkdir synoesp
curl --location https://global.download.synology.com/download/DSM/release/7.0.1/42218/DSM_DS3622xs%2B_42218.pat --output oldpat.tar.gz
tar -C./synoesp/ -xf oldpat.tar.gz rd.gz
cd synoesp

output=$(xz -dc < rd.gz 2>/dev/null | cpio -idm 2>&1)
mkdir extract && cd extract
cp ../usr/lib/libcurl.so.4 ../usr/lib/libmbedcrypto.so.5 ../usr/lib/libmbedtls.so.13 ../usr/lib/libmbedx509.so.1 ../usr/lib/libmsgpackc.so.2 ../usr/lib/libsodium.so ../usr/lib/libsynocodesign-ng-virtual-junior-wins.so.7 ../usr/syno/bin/scemd ./
ln -s scemd syno_extract_system_patch

curl --location https://global.download.synology.com/download/DSM/beta/7.1/42550/DSM_DS3622xs%2B_42550.pat --output 42550.pat

sudo LD_LIBRARY_PATH=. ./syno_extract_system_patch 42550.pat output-pat

cd output-pat && sudo tar -zcvf 42550.pat * && sudo chmod 777 42550.pat
read -a os_sha256 <<< $(sha256sum 42550.pat)
echo $os_sha256
cp 42550.pat ${root}/${workpath}/redpill-load/cache/ds3622xsp_42550.pat
cd ../../../


# build redpill-load
cd redpill-load
cp -f ${root}/user_config.DS3622xs.json ./user_config.json
sed -i '0,/"sha256.*/s//"sha256": "'$os_sha256'"/' ./config/DS3622xs+/${build_para}/config.json
cat ./config/DS3622xs+/${build_para}/config.json

# 7.1.0 must add this ext
./ext-manager.sh add https://raw.githubusercontent.com/jumkey/redpill-load/develop/redpill-misc/rpext-index.json  
# add optional ext
./ext-manager.sh add https://raw.githubusercontent.com/dogodefi/mpt3sas/offical/rpext-index.json
#./ext-manager.sh add https://raw.githubusercontent.com/dogodefi/redpill-ext/master/acpid/rpext-index.json
# ./ext-manager.sh add https://raw.githubusercontent.com/dogodefi/mpt3sas/offical/rpext-index.json
# ./ext-manager.sh add https://raw.githubusercontent.com/jumkey/redpill-load/develop/redpill-virtio/rpext-index.json
sudo ./build-loader.sh 'DS3622xs+' '7.1.0-42550'
mv images/redpill-DS3622xs+_7.1.0-42*.img ${root}/output/
cd ${root}
