BASE_DIR=$HOME/bin/time_tracker
mkdir -p $BASE_DIR
cp -r ./resources $BASE_DIR
cp ./time_tracker $BASE_DIR
desktop-file-install --dir=$HOME/.local/share/applications ./ubuntu/time_tracker.desktop