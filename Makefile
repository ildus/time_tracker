SHELL := /bin/bash

build:
	go build

run:
	make build
	./tracker

app:
	- cp ./tracker.app/Contents/MacOS/activities.db ./
	- rm -rf ./tracker.app
	appify ./tracker
	macdeployqt tracker.app -qmldir=./resources/qml
	cp -r ./resources tracker.app/Contents/MacOS
	- cp ./activities.db ./tracker.app/Contents/MacOS/
	./set_icon.sh

install_deps:
	go get github.com/jinzhu/gorm
	go get github.com/mattn/go-sqlite3
	go get gopkg.in/qml.v0