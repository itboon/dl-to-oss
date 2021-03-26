#!/bin/bash

set -ex

# OSS env
OSS_EP="oss-cn-hongkong.aliyuncs.com"
OSS_BUCKET="oss://nas-ci"
OSS_SITE="ttps://nas-ci.oss-cn-hongkong.aliyuncs.com/"

DL_NAMESAPCE="a"
OSS_HOME="${OSS_BUCKET}/ci/${DL_NAMESAPCE}"

# tools
DL_OSS_URL="https://gosspublic.alicdn.com/ossutil/1.7.1/ossutil64"
DL_YQ_URL="https://github.com/mikefarah/yq/releases/download/v4.6.3/yq_linux_amd64"
# DL_YQ_URLURL="https://nas-ci.oss-cn-hongkong.aliyuncs.com/man/linux/yq_linux_v4.6.3"
aliOSS="${HOME}/bin/ossutil"
YQ="${HOME}/bin/yq"
mkdir -p ${HOME}/bin

DL_DIR="/tmp/download"
mkdir -p ${DL_DIR}
rm -rf ${DL_DIR}/*


# 下载工具
do_setup_env() {
  curl -o $aliOSS -L $DL_OSS_URL
  curl -o $YQ -L $DL_YQ_URL
  chmod a+rx $aliOSS
  chmod a+rx $YQ
}

do_yq_dl() {
  # 第一个参数是 yq 需要解析的 yaml 文件
  local yml=$1
  DL_NAMESAPCE=$($YQ e '.namespace' $yml)
  OSS_HOME="${OSS_BUCKET}/ci/${DL_NAMESAPCE}"
  local num=$($YQ e '.downloads | length' $yml)
  set +e
  for ((i=0; i<$num; i++)); do
    local this_url=$($YQ e downloads[${i}].url $yml)
    local this_file=$($YQ e downloads[${i}].file $yml)
    local this_update=$($YQ e downloads[${i}].update $yml)
    $aliOSS stat ${OSS_HOME}/${this_file} &> /dev/null
    # Download if the file exists on oss or need to update.
    if (( $? != 0 )) || (( $this_update == yes )); then
      curl -sSL ${this_url} -o ${DL_DIR}/${this_file}
    fi
  done
  set -e
}

do_oss_map() {
  $aliOSS ls ${OSS_BUCKET}/ -s | grep '^oss' \
    | sed "s%oss://nas-ci/%${OSS_SITE}%g" > map.txt
  $aliOSS cp -f map.txt ${OSS_BUCKET}/map.txt
}

main() {
  do_setup_env

  $aliOSS config -e $OSS_EP -i $OSS_KEY_ID -k $OSS_KEY_SE
  do_yq_dl "oss-${DL_NAMESAPCE}.yml"
  
  $aliOSS cp -rf ${DL_DIR}/ ${OSS_HOME}/
  do_oss_map
}

main
