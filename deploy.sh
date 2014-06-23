cp ./tracker.app/Contents/MacOS/activities.db ./
rm -rf ./tracker.app
appify ./tracker
macdeployqt tracker.app -qmldir=./resources/qml
cp -r ./resources tracker.app/Contents/MacOS
cp ./activities.db ./tracker.app/Contents/MacOS/