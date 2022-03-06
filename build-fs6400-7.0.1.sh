
#!/bin/bash

# prepare build tools
sudo apt-get update && sudo apt-get install --yes --no-install-recommends ca-certificates build-essential git libssl-dev curl cpio bspatch vim gettext bc bison flex dosfstools kmod jq

root=`pwd`
mkdir FS6400-7.0.1
mkdir output
cd FS6400-7.0.1

# download redpill
git clone -b test1 --depth=1 https://github.com/dogodefi/redpill-lkm.git
git clone -b test --depth=1 https://github.com/dogodefi/redpill-load.git

# download syno toolkit
curl --location "https://cndl.synology.cn/download/ToolChain/toolkit/7.0/purley/ds.purley-7.0.dev.txz" --output ds.purley-7.0.dev.txz

mkdir purley
tar -C./purley/ -xf ds.purley-7.0.dev.txz usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build

# build redpill-lkm
cd redpill-lkm
sed -i 's/   -std=gnu89/   -std=gnu89 -fno-pie/' ../purley/usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build/Makefile
make LINUX_SRC=../purley/usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build dev-v7
read -a KVERS <<< "$(sudo modinfo --field=vermagic redpill.ko)" && cp -fv redpill.ko ../redpill-load/ext/rp-lkm/redpill-linux-v${KVERS[0]}.ko || exit 1
cd ..

# build redpill-load
cd redpill-load
cp -f ${root}/user_config.FS6400.json ./user_config.json
./ext-manager.sh add https://raw.githubusercontent.com/dogodefi/mpt3sas/offical/rpext-index.json
sudo ./build-loader.sh 'FS6400' '7.0.1-42218'
mv images/redpill-FS6400_7.0.1-4221*.img ${root}/output/
cd ${root}
