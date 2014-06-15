package main

import (
	"gopkg.in/qml.v0"
)

func main() {
	qml.Init(nil)
	engine := qml.NewEngine()
	component, err := engine.LoadFile("main.qml")
	if err != nil {
		panic(err)
	}

	//context := engine.Context()
	window := component.CreateWindow(nil)
	window.Show()
	window.Wait()
}
