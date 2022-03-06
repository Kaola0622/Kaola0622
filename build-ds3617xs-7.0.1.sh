
#!/bin/bash

# prepare build tools
sudo apt-get update && sudo apt-get install --yes --no-install-recommends ca-certificates build-essential git libssl-dev curl cpio bspatch vim gettext bc bison flex dosfstools kmod jq

root=`pwd`
mkdir DS3617xs-7.0.1
mkdir output
cd DS3617xs-7.0.1

# download redpill
git clone -b develop --depth=1 https://github.com/jimmyGALLAND/redpill-lkm.git
git clone -b develop --depth=1 https://github.com/jimmyGALLAND/redpill-load.git

# download syno toolkit
curl --location "https://sourceforge.net/projects/dsgpl/files/toolkit/DSM7.0/ds.broadwell-7.0.dev.txz/download" --output ds.broadwell-7.0.dev.txz

mkdir broadwell
tar -C./broadwell/ -xf ds.broadwell-7.0.dev.txz usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build

# build redpill-lkm
cd redpill-lkm
sed -i 's/   -std=gnu89/   -std=gnu89 -fno-pie/' ../broadwell/usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build/Makefile
make LINUX_SRC=../broadwell/usr/local/x86_64-pc-linux-gnu/x86_64-pc-linux-gnu/sys-root/usr/lib/modules/DSM-7.0/build dev-v7
read -a KVERS <<< "$(sudo modinfo --field=vermagic redpill.ko)" && cp -fv redpill.ko ../redpill-load/ext/rp-lkm/redpill-linux-v${KVERS[0]}.ko || exit 1
cd ..

# build redpill-load
cd redpill-load
cp -f ${root}/user_config.DS3617xs.json ./user_config.json
sudo ./build-loader.sh 'DS3617xs' '7.0.1-42218'
mv images/redpill-DS3617xs_7.0.1-4221*.img ${root}/output/
cd ${root}
