#!/bin/bash
# SPDX-License-Identifier: MIT
# Copyright (C) 2026 VIKINGYFY

#移除luci-app-attendedsysupgrade
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "/attendedsysupgrade/d" {} +
#修改默认主题
find ./feeds/luci/collections/ -type f -name "Makefile" -exec sed -i "s/luci-theme-bootstrap/luci-theme-$WRT_THEME/g" {} +
#修改immortalwrt.lan关联IP
find ./feeds/luci/modules/luci-mod-system/ -type f -name "flash.js" -exec sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" {} +
#添加编译日期标识
find ./feeds/luci/modules/luci-mod-status/ -type f -name "10_system.js" -exec sed -i "s/(\(luciversion || ''\))/(\1) + (' \/ $WRT_DATE')/g" {} +

#修改默认WIFI账号密码
WIFI_UC="./package/network/config/wifi-scripts/files/lib/wifi/mac80211.uc"
ROUTER_TOOL="./package/emortal/luci-app-router-tool/root/etc/config/router-tool"
for file in "$ROUTER_TOOL" "$WIFI_UC"; do
	[ -f "$file" ] && sed -i "s/ssid '.*'/ssid '$WRT_SSID'/g; s/key '.*'/key '$WRT_WORD'/g" "$file"
done

CFG_FILE="./package/base-files/files/bin/config_generate"
#修改默认IP地址
sed -i "s/192\.168\.[0-9]*\.[0-9]*/$WRT_IP/g" $CFG_FILE
#修改默认主机名
sed -i "s/hostname='.*'/hostname='$WRT_NAME'/g" $CFG_FILE

#配置文件修改
echo "CONFIG_PACKAGE_luci=y" >> ./.config
echo "CONFIG_LUCI_LANG_zh_Hans=y" >> ./.config
echo "CONFIG_PACKAGE_luci-theme-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME=y" >> ./.config
echo "CONFIG_PACKAGE_luci-app-$WRT_THEME-config=y" >> ./.config

#引入私有扩展配置
if [ -f "$GITHUB_WORKSPACE/Config/PRIVATE.txt" ]; then
	echo "Applying private configurations from PRIVATE.txt..."
	cat $GITHUB_WORKSPACE/Config/PRIVATE.txt >> ./.config
fi

#手动调整的插件
if [ -n "$WRT_PACKAGE" ]; then
	echo -e "$WRT_PACKAGE" >> ./.config
fi

#高通平台调整
DTS_PATH="./target/linux/qualcommax/dts/"
if [[ "${WRT_TARGET^^}" == *"QUALCOMMAX"* ]]; then
	#无WIFI配置调整Q6大小
	if [[ "$WRT_WIFI" == "WIFI-NO" ]]; then
		find $DTS_PATH -type f ! -iname '*nowifi*' -exec sed -i 's/ipq\(6018\|8074\).dtsi/ipq\1-nowifi.dtsi/g' {} +
		echo "qualcommax set up nowifi successfully!"
	fi
fi

if [[ "${WRT_CONFIG,,}" == *"ipq60"* ]]; then
	echo "IPQ60XX CONFIG set up successfully!"
	echo "CONFIG_PACKAGE_kmod-sctp=y" >> ./.config
	echo "CONFIG_PACKAGE_kmod-sctp-diag=y" >> ./.config
	echo "CONFIG_PACKAGE_luci-app-dockerman=y" >> ./.config
	echo "CONFIG_PACKAGE_luci-app-openclash=y" >> ./.config
	echo "CONFIG_PACKAGE_luci-app-taskplan=y" >> ./.config
	echo "CONFIG_PACKAGE_luci-app-adguardhome=y" >> ./.config
	#修复 netspeedtest 缺失的 Python3 依赖环境
	echo "CONFIG_PACKAGE_python3=y" >> ./.config
	echo "CONFIG_PACKAGE_python3-base=y" >> ./.config
	echo "CONFIG_PACKAGE_python3-email=y" >> ./.config
	echo "CONFIG_PACKAGE_python3-pkg-resources=y" >> ./.config
	echo "CONFIG_PACKAGE_luci-app-netspeedtest=y" >> ./.config
	echo "CONFIG_PACKAGE_luci-i18n-netspeedtest-zh-cn=y" >> ./.config
#
# Zoneinfo
#
	echo "CONFIG_PACKAGE_zoneinfo-africa=y" >> ./.config
	# CONFIG_PACKAGE_zoneinfo-all is not set
	echo "CONFIG_PACKAGE_zoneinfo-asia=y" >> ./.config
	echo "CONFIG_PACKAGE_zoneinfo-atlantic=y" >> ./.config
	echo "CONFIG_PACKAGE_zoneinfo-australia-nz=y" >> ./.config
	echo "CONFIG_PACKAGE_zoneinfo-core=y" >> ./.config
	echo "CONFIG_PACKAGE_zoneinfo-europe=y" >> ./.config
	echo "CONFIG_PACKAGE_zoneinfo-india=y" >> ./.config
	echo "CONFIG_PACKAGE_zoneinfo-northamerica=y" >> ./.config
	echo "CONFIG_PACKAGE_zoneinfo-pacific=y" >> ./.config
	echo "CONFIG_PACKAGE_zoneinfo-poles=y" >> ./.config
	echo "CONFIG_PACKAGE_zoneinfo-simple=y" >> ./.config
	echo "CONFIG_PACKAGE_zoneinfo-southamerica=y" >> ./.config
	
	echo "CONFIG_PACKAGE_luci-app-ddns-go=y" >> ./.config
	echo "CONFIG_PACKAGE_luci-app-mosdns=y" >> ./.config
	echo "CONFIG_PACKAGE_adguardhome=y" >> ./.config

	
fi

