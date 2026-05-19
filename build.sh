#!/bin/bash
PATH_PWD="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"
PATH_web="${PATH_PWD}/web/debian"
PATH_patchlist="${PATH_web}/patch-list"
PATH_source="${PATH_PWD}/source"

URL_wpi_update="https://github.com/walnutpi/wpi-update.git"
SOURCE_wpi_update="${PATH_source}/$(basename "$URL_wpi_update" .git)"


[[ ! -d $PATH_source ]] && mkdir ${PATH_source}



clone_url() {
    local git_url="$1"
    dir_name=$(basename "$git_url" .git)
    
    if [ -d "$dir_name" ]; then
        cd "$dir_name"
        git config --global --add safe.directory $(pwd)
        echo "pull : $git_url"
        git pull
    else
        echo "clone : $git_url"
        git clone $git_url
    fi
}
echo "打包wpi-update供下载"
cd $PATH_source
clone_url $URL_wpi_update
cd $SOURCE_wpi_update
if [ ! -f "$PATH_web/wpi-update" ];then
    # 如果不存在就生成
    cp wpi-update $PATH_web/wpi-update
    tar -czf $PATH_web/wpi-update.gz wpi-update
fi

GIT_TIME=$(git log -1 --format=%cd --date=unix)
FILE_TIME=$(stat -c %Y "$PATH_web/wpi-update")
if [ "$GIT_TIME" -gt 0 ] 2>/dev/null && [ "$FILE_TIME" -gt 0 ] 2>/dev/null; then
    # 如果git的修改时间大于文件修改时间，就生成tar包覆盖
    if [ "$GIT_TIME" -gt "$FILE_TIME" ]; then
        cp wpi-update $PATH_web/wpi-update
        tar -czf $PATH_web/wpi-update.gz wpi-update
    fi
fi


echo "打包patch-list"
cd $PATH_patchlist
for DIR in */
do
    cd $PATH_patchlist
    DIR_NAME=${DIR%/}
    DIR_TIME=$(find "$DIR_NAME" -type f -exec stat -c %Y {} \; | sort -nr | head -n 1)
    FILE_TIME=$(stat -c %Y "$PATH_patchlist/$DIR_NAME.gz" 2>/dev/null)
    
    # 如果.gz文件不存在，或者文件夹的修改时间比.gz文件晚，就生成同名.gz压缩文件覆盖
    if [ -z "$FILE_TIME" ] || [ $DIR_TIME -gt $FILE_TIME ]
    then
        cd $PATH_patchlist/$DIR_NAME
        tar -czf "$PATH_patchlist/$DIR_NAME.gz" ./
        echo "已生成$PATH_patchlist/$DIR_NAME.gz"
    fi
done


echo "打包deb包"
cd $PATH_web
bin_all=${PATH_web}/dists/bookworm/main/binary-all
mkdir  -p ${bin_all}
cd ${PATH_web}
dpkg-scanpackages --multiversion pool/main /dev/null > ${bin_all}/Packages

bin_arm64=${PATH_web}/dists/bookworm/main/binary-arm64
mkdir  -p ${bin_arm64}
cd ${PATH_web}
dpkg-scanpackages --multiversion pool/arm64 /dev/null > ${bin_arm64}/Packages

echo "生成release文件"
cd $PATH_PWD
apt-ftparchive -c=bookworm.conf release ${PATH_web}/dists/bookworm > ${PATH_web}/dists/bookworm/Release

exit

