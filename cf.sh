#!/bin/bash
export LANG=en_US.UTF-8
case "$(uname -m)" in
	x86_64 | x64 | amd64 )
	cpu=amd64
	;;
	i386 | i686 )
        cpu=386
	;;
	armv8 | armv8l | arm64 | aarch64 )
        cpu=arm64
	;;
	armv7l )
        cpu=arm
	;;
        mips64le )
        cpu=mips64le
	;;
        mips64 )
        cpu=mips64
	;;
        mips )
        cpu=mipsle
	;;
        mipsle )
        cpu=mipsle
	;;
	* )
	echo "Kiến trúc hiện tại là $(uname -m), chưa được hỗ trợ"
	exit
	;;
esac

result(){
awk -F ',' '$2 ~ /BGI|YCC|YVR|YWG|YHZ|YOW|YYZ|YUL|YXE|STI|SDQ|GUA|KIN|GDL|MEX|QRO|SJU|MGM|ANC|PHX|LAX|SMF|SAN|SFO|SJC|DEN|JAX|MIA|TLH|TPA|ATL|HNL|ORD|IND|BGR|BOS|DTW|MSP|MCI|STL|OMA|LAS|EWR|ABQ|BUF|CLT|RDU|CLE|CMH|OKC|PDX|PHL|PIT|FSD|MEM|BNA|AUS|DFW|IAH|MFE|SAT|SLC|IAD|ORF|RIC|SEA/ {print $0}' $ip.csv | sort -t ',' -k5,5n | head -n 3 > US-$ip.csv
awk -F ',' '$2 ~ /CGP|DAC|JSR|PBH|BWN|PNH|GUM|HKG|AMD|BLR|BBI|IXC|MAA|HYD|CNN|KNU|COK|CCU|BOM|NAG|DEL|PAT|DPS|CGK|JOG|FUK|OKA|KIX|NRT|ALA|NQZ|ICN|VTE|MFM|JHB|KUL|KCH|MLE|ULN|MDL|RGN|KTM|ISB|KHI|LHE|CGY|CEB|MNL|CRK|KJA|SVX|SIN|CMB|KHH|TPE|BKK|CNX|URT|TAS|DAD|HAN|SGN/ {print $0}' $ip.csv | sort -t ',' -k5,5n | head -n 3 > AS-$ip.csv
awk -F ',' '$2 ~ /TIA|VIE|MSQ|BRU|SOF|ZAG|LCA|PRG|CPH|TLL|HEL|BOD|LYS|MRS|CDG|TBS|TXL|DUS|FRA|HAM|MUC|STR|ATH|SKG|BUD|KEF|ORK|DUB|MXP|PMO|FCO|RIX|VNO|LUX|KIV|AMS|SKP|OSL|WAW|LIS|OTP|DME|LED|KLD|BEG|BTS|BCN|MAD|GOT|ARN|GVA|ZRH|IST|ADB|KBP|EDI|LHR|MAN/ {print $0}' $ip.csv | sort -t ',' -k5,5n | head -n 3 > EU-$ip.csv
}

#if timeout 3 ping -c 2 google.com &> /dev/null; then
#echo "Mạng hiện tại đang bật proxy, để đảm bảo tính chính xác, vui lòng tắt proxy"
#else
#echo "Mạng hiện tại đã tắt proxy, tiếp tục thực hiện..."
#fi

if timeout 3 ping -c 2 2400:3200::1 &> /dev/null; then
echo "Mạng hiện tại hỗ trợ IPV4+IPV6"
else
echo "Mạng hiện tại chỉ hỗ trợ IPV4"
fi
rm -rf 6.csv 4.csv
echo "Dự án Github của anh Yong: github.com/yonggekkk"
echo "Blog của anh Yong       : ygkkk.blogspot.com"
echo "Kênh YouTube của anh Yong: www.youtube.com/@ygkkk"
echo
echo "Nếu có thông báo: Lỗi khi chạy, vui lòng kiểm tra môi trường mạng!!! Hãy thử chạy qua proxy một lần đầu tiên, sau đó chỉ cần chạy nhanh bằng lệnh: bash cf.sh"
echo
echo "Vui lòng chọn loại IP ưu tiên"
echo "1. Chỉ ưu tiên IPV4"
echo "2. Chỉ ưu tiên IPV6"
echo "3. Ưu tiên cả IPV4+IPV6"
echo "4. Đặt lại cấu hình"
echo "5. Thoát"
read -p "Vui lòng chọn [1-5]:" menu
if [ ! -e cf ]; then
curl -L -o cf -# --retry 2 --insecure https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/$cpu
chmod +x cf
fi
if [ ! -e locations.json ]; then
curl -s -o locations.json https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/locations.json
fi
if [ ! -e ips-v4.txt ]; then
curl -s -o ips-v4.txt https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/ips-v4.txt
fi
if [ ! -e ips-v6.txt ]; then
curl -s -o ips-v6.txt https://raw.githubusercontent.com/yonggekkk/Cloudflare_vless_trojan/main/cf/ips-v6.txt
fi
if [ "$menu" = "1" ]; then
ip=4
./cf -ips 4 -outfile 4.csv
result
elif [ "$menu" = "2" ]; then
ip=6
./cf -ips 6 -outfile 6.csv
result
elif [ "$menu" = "3" ]; then
ip=4
./cf -ips 4 -outfile 4.csv
result
ip=6
./cf -ips 6 -outfile 6.csv
result
elif [ "$menu" = "4" ]; then
rm -rf 6.csv 4.csv locations.json ips-v4.txt ips-v6.txt cf cf.sh
echo "Đã đặt lại thành công" && exit
else
exit
fi
clear
if [ -e 4.csv ]; then
echo "Các nút IPV4 tốt nhất hiện có như sau (lấy 3 kết quả hàng đầu):"
echo "Kết quả ưu tiên IPV4 tại Mỹ:"
cat US-4.csv
echo
echo "Kết quả ưu tiên IPV4 tại Châu Á:"
cat AS-4.csv
echo
echo "Kết quả ưu tiên IPV4 tại Châu Âu:"
cat EU-4.csv
fi
if [ -e 6.csv ]; then
echo "Các nút IPV6 tốt nhất hiện có như sau (lấy 3 kết quả hàng đầu):"
echo "Kết quả ưu tiên IPV6 tại Mỹ:"
cat US-6.csv
echo
echo "Kết quả ưu tiên IPV6 tại Châu Á:"
cat AS-6.csv
echo
echo "Kết quả ưu tiên IPV6 tại Châu Âu:"
cat EU-6.csv
fi
if [ ! -e 4.csv ] && [ ! -e 6.csv ]; then
echo "Lỗi khi chạy, vui lòng kiểm tra môi trường mạng"
fi