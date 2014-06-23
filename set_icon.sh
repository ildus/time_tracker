cd `dirname $0`
droplet=./tracker.app
icon=resources/images/appicon.icns
rm -rf $droplet$'/Icon\r'
sips -i $icon >/dev/null
DeRez -only icns $icon > /tmp/icns.rsrc
Rez -append /tmp/icns.rsrc -o $droplet$'/Icon\r'
SetFile -a C $droplet
SetFile -a V $droplet$'/Icon\r'