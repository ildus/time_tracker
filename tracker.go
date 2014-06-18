package main

import (
	"fmt"
	"github.com/jinzhu/gorm"
	_ "github.com/mattn/go-sqlite3"
	"gopkg.in/qml.v0"
	"log"
	"strings"
	"time"
)

const (
	ONE_MIN_LESS_TEXT_HEADER = "Just started"
	ONE_MIN_LESS_TEXT_TABLE  = "Almost nothing"
)

type Tag struct {
	Id         int64
	ActivityId int64
	Tag        string `sql:"size:255;not null"`
}

type Activity struct {
	Id          int64
	Start       time.Time
	End         time.Time
	Name        string `sql:"size:500"`
	Description string `sql:"size:2000"`
	Tags        string `sql:"size:2000"`
	ForeignTags []Tag
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
		result = ONE_MIN_LESS_TEXT_HEADER
	} else {
		if duration.Hours() < 1 {
			result = fmt.Sprintf("%d min", int(duration.Minutes()))
		} else {
			result = fmt.Sprintf("%dh %dmin", int(duration.Hours()), int(duration.Minutes()))
		}
	}
	return result
}

func (a *Activity) GetTableDuration() string {
	duration := a.GetDuration()
	if strings.EqualFold(duration, ONE_MIN_LESS_TEXT_HEADER) {
		return ONE_MIN_LESS_TEXT_TABLE
	}
	return duration
}

func (a *Activity) GetDay() string {
	today := time.Now()
	d := time.Duration(-today.Hour())*time.Hour + 6*time.Hour
	today = today.Add(d)

	//if new day has started today is yesterday
	if time.Now().Hour() < 6 {
		today = today.Add(-24 * time.Hour)
	}

	yesterday := today.Add(-24 * time.Hour)

	if a.Start.After(today) {
		return "Today"
	} else {
		if a.Start.After(yesterday) {
			return "Yesterday"
		} else {
			return a.Start.Format("Jan 2")
		}
	}
}

func (a *Activity) GetTimePeriod() string {
	result := a.Start.Format("15:04") + " - "
	if !a.End.IsZero() {
		result = result + a.End.Format("15:04")
	}
	return result
}

type Control struct {
	Root            qml.Object
	Activities      []*Activity
	CurrentActivity *Activity
	ActivitiesLen   int
}

func (c *Control) GetActivity(index int) *Activity {
	activity := c.Activities[index]
	fmt.Println("get", index, activity)
	return activity
}

func (c *Control) NewActivity(name string, tags string) {
	tagsArr := strings.Split(tags, " ")
	var activityTags []Tag
	for _, tag := range tagsArr {
		cleaned := strings.ToLower(strings.Trim(tag, " "))
		if len(cleaned) > 1 {
			activityTags = append(activityTags, Tag{Tag: cleaned})
		}
	}

	activity := &Activity{
		Start:       time.Now(),
		Name:        name,
		ForeignTags: activityTags,
		Tags:        tags,
	}
	c.CurrentActivity = activity
	c.SaveActivity(activity)
	updateCurrentDuration(activity.Start)

	ctrl.Root.Set("currentActivity", name)
	ctrl.Root.Set("activityStarted", true)
}

func (c *Control) StopActivity() {
	if c.CurrentActivity.End.IsZero() {
		c.CurrentActivity.End = time.Now()
		c.SaveActivity(c.CurrentActivity)

		ctrl.Root.Set("currentActivity", "")
		ctrl.Root.Set("activityStarted", false)
		c.UpdateActivities()
	}
}

func (c *Control) SaveActivity(activity *Activity) {
	db.Save(activity)
	fmt.Println(activity)
	if activity.End.IsZero() {
		ctrl.Activities = append(ctrl.Activities, nil)
		copy(ctrl.Activities[1:], ctrl.Activities)
		ctrl.Activities[0] = activity
	}
	c.UpdateActivities()
}

func (c *Control) UpdateActivities() {
	ctrl.ActivitiesLen = len(ctrl.Activities)
	ctrl.Root.Set("lastDayText", "")

	fmt.Println(ctrl.Activities)
	qml.Changed(&ctrl, &ctrl.ActivitiesLen)
}

func (c *Control) LoadActivities(init bool) {
	var activities []Activity
	dt := time.Now().Add(-time.Hour * 24 * 3)
	db.Order("start desc").Where("start >= ?", dt).Find(&activities)
	for _, v := range activities {
		var activity = v
		ctrl.Activities = append(ctrl.Activities, &activity)
	}

	c.UpdateActivities()
}

func getDatabase() gorm.DB {
	db, err := gorm.Open("sqlite3", "./activities.db")
	if err != nil {
		log.Fatal("Database connection error", err)
	}

	db.SingularTable(true)

	db.DropTable(Activity{})
	db.DropTable(Tag{})
	db.CreateTable(Activity{})
	db.CreateTable(Tag{})

	return db
}

var (
	ctrl Control
	db   gorm.DB
)

func updateCurrentDuration(currentTime time.Time) {
	if ctrl.CurrentActivity != nil {
		ctrl.Root.Set("duration", ctrl.CurrentActivity.GetDuration())
	}
}

func tick() {
	for {
		timer := time.NewTimer(time.Second * 5)
		currentTime := <-timer.C
		updateCurrentDuration(currentTime)
		ctrl.UpdateActivities()
	}
}

func main() {
	db = getDatabase()

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
	ctrl.LoadActivities(true)
	window.Show()
	window.Wait()
}
