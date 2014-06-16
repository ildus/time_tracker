package main

import (
	"database/sql"
	"fmt"
	_ "github.com/mattn/go-sqlite3"
	"gopkg.in/qml.v0"
	"log"
	"strings"
	"time"
)

type Activity struct {
	Id    int
	Start time.Time
	End   time.Time
	Name  string
	Tags  []string
}

func getDatabase() *sql.DB {
	db, err := sql.Open("sqlite3", "./activities.db")
	if err != nil {
		log.Fatal(err)
	}
	return db
}

func initDatabase() {
	db := getDatabase()
	table_sql := `
        drop table if exists activities;
        create table if not exists activities (
            id integer primary key autoincrement,
            start datetime not null,
            end datetime null,
            name varchar(500) not null,
            description varchar(2000) null,
            tags varchar(2000) null
        )
    `

	if _, err := db.Exec(table_sql); err != nil {
		log.Fatal(err)
	}
}

func (a *Activity) GetDuration() string {
	var duration time.Duration
	var result string
	if a.End.IsZero() {
		duration = time.Since(a.Start)
	} else {
		duration = a.End.Sub(a.Start)
	}

	if (duration.Minutes()) < 1 {
		result = "Just started"
	} else {
		if duration.Hours() < 1 {
			result = fmt.Sprintf("%d min", int(duration.Minutes()))
		} else {
			result = fmt.Sprintf("%dh %dmin", int(duration.Hours()), int(duration.Minutes()))
		}
	}
	return result
}

type Control struct {
	Root            qml.Object
	Activities      []*Activity
	CurrentActivity *Activity
}

func (c *Control) NewActivity(name string, tags string) {
	tagsArr := strings.Split(tags, " ")
	activity := &Activity{Start: time.Now(), Name: name, Tags: tagsArr}
	c.CurrentActivity = activity
	c.SaveActivity(activity)
	updateCurrentActivity(activity.Start)

	ctrl.Root.Set("currentActivity", name)
	ctrl.Root.Set("activityStarted", true)
}

func (c *Control) StopActivity() {
	if c.CurrentActivity.End.IsZero() {
		c.CurrentActivity.End = time.Now()
		c.SaveActivity(c.CurrentActivity)

		ctrl.Root.Set("currentActivity", "")
		ctrl.Root.Set("activityStarted", false)
	}
}

func (c *Control) SaveActivity(activity *Activity) {
	db := getDatabase()
	defer db.Close()
}

var (
	ctrl Control
)

func updateCurrentActivity(currentTime time.Time) {
	fmt.Println(currentTime)
	if ctrl.CurrentActivity != nil {
		ctrl.Root.Set("duration", ctrl.CurrentActivity.GetDuration())
	}
}

func tick() {
	for {
		timer := time.NewTimer(time.Second * 5)
		currentTime := <-timer.C
		updateCurrentActivity(currentTime)
	}
}

func main() {
	initDatabase()

	qml.Init(nil)
	engine := qml.NewEngine()
	component, err := engine.LoadFile("main.qml")
	if err != nil {
		panic(err)
	}

	go tick()

	ctrl = Control{}
	context := engine.Context()
	context.SetVar("ctrl", &ctrl)

	//context := engine.Context()
	window := component.CreateWindow(nil)
	ctrl.Root = window.Root()
	window.Show()
	window.Wait()
}
