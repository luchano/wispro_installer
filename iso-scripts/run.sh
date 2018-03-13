tag="3.7"
BASE=${HOME}/wispro_installer/iso-scripts
APORTS_SCRIPTS=${HOME}/aports/scripts
cp -a $BASE/genapkovl-wispro.sh $BASE/mkimg.wispro.sh $APORTS_SCRIPTS
cd $APORTS_SCRIPTS
./mkimage.sh --tag $tag --outdir /home/build/iso --arch x86_64 --repository http://dl-cdn.alpinelinux.org/alpine/v${tag}/main/ --extra-repository http://dl-cdn.alpinelinux.org/alpine/v${tag}/community --profile wispro
