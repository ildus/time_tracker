package main

import (
	"fmt"
	"github.com/jinzhu/gorm"
	_ "github.com/mattn/go-sqlite3"
	"gopkg.in/qml.v0"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"
)

const (
	ONE_MIN_LESS_TEXT_HEADER = "Just started"
	ONE_MIN_LESS_TEXT_TABLE  = "Almost nothing"
)

var (
	ctrl         Control
	db           gorm.DB
	baseLocation *time.Location
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
	Duration    string `sql:"-"`
	DayName     string `sql:"-"`
	TimePeriod  string `sql:"-"`
}

func (a *Activity) UpdateFields() {
	a.Duration = a.GetTableDuration()
	a.DayName = a.GetDay()
	a.TimePeriod = a.GetTimePeriod()
}

func verboseDuration(duration time.Duration) (result string) {
	if (duration.Minutes()) < 1 {
		result = ONE_MIN_LESS_TEXT_HEADER
	} else {
		if duration.Hours() < 1 {
			result = fmt.Sprintf("%d min", int(duration.Minutes()))
		} else {
			minutes := duration.Minutes() - 60*duration.Hours()
			result = fmt.Sprintf("%dh %dmin", int(duration.Hours()), int(minutes))
		}
	}
	return result
}

func (a *Activity) GetDuration() time.Duration {
	var duration time.Duration
	if a.End.IsZero() {
		duration = time.Since(a.Start)
	} else {
		duration = a.End.Sub(a.Start)
	}
	return duration
}

func (a *Activity) GetDurationText() string {
	duration := a.GetDuration()
	return verboseDuration(duration)
}

func (a *Activity) GetTableDuration() string {
	duration := a.GetDurationText()
	if strings.EqualFold(duration, ONE_MIN_LESS_TEXT_HEADER) {
		return ONE_MIN_LESS_TEXT_TABLE
	}
	return duration
}

func getToday() time.Time {
	today := time.Now()
	d := time.Duration(-today.Hour())*time.Hour + 6*time.Hour
	today = today.Add(d)

	//if new day has started today is yesterday
	if time.Now().Hour() < 6 {
		today = today.Add(-24 * time.Hour)
	}
	return today
}

func (a *Activity) GetDay() string {
	today := getToday()
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

func (c *Control) Activity(index int) *Activity {
	activity := c.Activities[index]
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
	c.SaveActivity(activity)
	c.SetCurrentActivity(activity)
}

func (c *Control) CopyActivity(index int) {
	if c.CurrentActivity == nil {
		activity := c.Activities[index]
		c.NewActivity(activity.Name, activity.Tags)
	}
}

func (c *Control) StopActivity() {
	if c.CurrentActivity != nil {
		c.CurrentActivity.End = time.Now()
		c.SaveActivity(c.CurrentActivity)
		c.SetCurrentActivity(nil)
		c.UpdateActivities()
	}
}

func (c *Control) SetCurrentActivity(a *Activity) {
	ctrl.CurrentActivity = a
	if a == nil {
		ctrl.Root.Set("currentActivity", "")
		ctrl.Root.Set("activityStarted", false)
		ctrl.Root.Set("tagsCount", 0)
	} else {
		ctrl.Root.Set("currentActivity", a.Name)
		ctrl.Root.Set("activityStarted", true)
		ctrl.Root.Set("tagsCount", len(a.ForeignTags))
		updateCurrentDuration(a.Start)
	}
}

func (c *Control) SaveActivity(activity *Activity) {
	db.Save(activity)
	if activity.End.IsZero() {
		ctrl.Activities = append(ctrl.Activities, nil)
		copy(ctrl.Activities[1:], ctrl.Activities)
		ctrl.Activities[0] = activity
	}
	c.UpdateActivities()
}

func (c *Control) UpdateAllFields() {
	defer func() {
		if err := recover(); err != nil {
			log.Println(err)
		}
	}()

	var last *Activity

	for i := 0; i < ctrl.ActivitiesLen; i += 1 {
		act := ctrl.Activity(i)
		act.UpdateFields()
		if last != nil && last.DayName == act.DayName {
			act.DayName = ""
		}

		qml.Changed(act, &act.Name)
		qml.Changed(act, &act.Duration)
		qml.Changed(act, &act.TimePeriod)
		qml.Changed(act, &act.DayName)

		last = act
	}

	var todayDuration time.Duration
	for _, a := range ctrl.Activities {
		todayDuration += a.GetDuration()
	}
	if todayDuration > 0 {
		ctrl.Root.Set("todayText", "Today: "+verboseDuration(todayDuration))
	}
}

func (c *Control) UpdateActivities() {
	ctrl.ActivitiesLen = len(ctrl.Activities)
	ctrl.Root.Set("lastDayText", "")
	qml.Changed(&ctrl, &ctrl.ActivitiesLen)
	go c.UpdateAllFields()
}

func (c *Control) LoadActivities(init bool) {
	var activities []Activity
	dt := time.Now().Add(-time.Hour * 24 * 3)
	db.Order("start desc").Where("start >= ?", dt).Find(&activities)
	for _, v := range activities {
		var activity = v
		activity.End = activity.End.In(baseLocation)
		activity.Start = activity.Start.In(baseLocation)
		ctrl.Activities = append(ctrl.Activities, &activity)
	}

	if len(ctrl.Activities) > 0 && ctrl.Activities[0].End.IsZero() {
		ctrl.SetCurrentActivity(ctrl.Activity(0))
	}

	c.UpdateActivities()
}

func (c *Control) GetTag(index int) string {
	if c.CurrentActivity != nil {
		return c.CurrentActivity.ForeignTags[index].Tag
	}
	return ""
}

func getDatabase() gorm.DB {
	db, err := gorm.Open("sqlite3", "./activities.db")
	if err != nil {
		log.Fatal("Database connection error", err)
	}

	db.SingularTable(true)

	//db.DropTable(Activity{})
	//db.DropTable(Tag{})
	db.CreateTable(Activity{})
	db.CreateTable(Tag{})

	return db
}

func updateCurrentDuration(currentTime time.Time) {
	if ctrl.CurrentActivity != nil {
		ctrl.Root.Set("duration", ctrl.CurrentActivity.GetDurationText())
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
	dir, err := filepath.Abs(filepath.Dir(os.Args[0]))
	if err != nil {
		log.Fatal(err)
	}
	os.Chdir(dir)

	baseLocation, err = time.LoadLocation("Local")
	if err != nil {
		log.Fatal(err)
	}

	db = getDatabase()
	qml.Init(nil)
	engine := qml.NewEngine()
	component, err := engine.LoadFile("resources/qml/main.qml")
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
