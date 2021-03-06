package main

import (
	"fmt"
	"github.com/jinzhu/gorm"
	_ "github.com/mattn/go-sqlite3"
	"gopkg.in/qml.v1"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

const (
	ONE_MIN_LESS_TEXT_HEADER = "Just started"
	ONE_MIN_LESS_TEXT_TABLE  = "Almost nothing"
	shortDateFormat          = "02.01.2006 15:04"
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
			hours := int(duration.Hours())
			minutes := int(duration.Minutes())
			minutes -= 60 * hours
			result = fmt.Sprintf("%dh %dmin", hours, minutes)
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

	//if new day has started today is `day
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
			day := a.Start
			if day.Hour() < 6 {
				day.Add(-time.Hour * 24)
			}
			return day.Format("Jan 2")
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

func parseTags(tags string) []Tag {
	tagsArr := strings.Split(tags, " ")
	var activityTags []Tag
	for _, tag := range tagsArr {
		cleaned := strings.ToLower(strings.Trim(tag, " "))
		if len(cleaned) > 1 {
			activityTags = append(activityTags, Tag{Tag: cleaned})
		}
	}
	return activityTags
}

func (c *Control) NewActivity(name string, tags string) {
	activity := &Activity{
		Start:       time.Now(),
		Name:        name,
		ForeignTags: parseTags(tags),
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

func (c *Control) EditActivity(index int) {
	activity := c.Activities[index]
	if activity != ctrl.CurrentActivity {
		ctrl.Root.Set("activityIndex", index)
		ctrl.Root.Set("activityName", activity.Name)
		ctrl.Root.Set("activityTags", activity.Tags)
		ctrl.Root.Set("activityDescription", activity.Description)
		ctrl.Root.Set("activityStart", activity.Start.Format(shortDateFormat))
		if !activity.End.IsZero() {
			ctrl.Root.Set("activityEnd", activity.End.Format(shortDateFormat))
		} else {
			ctrl.Root.Set("activityEnd", "")
		}
		ctrl.Root.Call("showDropdown")
	}
}

func (c *Control) AddEarlierActivity() {
	ctrl.Root.Set("activityIndex", -1)
	ctrl.Root.Set("activityName", "")
	ctrl.Root.Set("activityTags", "")
	ctrl.Root.Set("activityDescription", "")
	ctrl.Root.Set("activityStart", "")
	ctrl.Root.Set("activityEnd", "")
	ctrl.Root.Call("showDropdown")
}

func (c *Control) RemoveActivity(index int) {
	defer func() {
		if err := recover(); err != nil {
			log.Println(err)
		}
	}()
	activity := c.Activities[index]
	if activity != ctrl.CurrentActivity {
		a := ctrl.Activities
		ctrl.Activities = append(a[:index], a[index+1:]...)
		db.Delete(activity)
		c.UpdateActivities(-1)
	}
}

type ByStart []*Activity

func (a ByStart) Swap(i, j int) {
	a[i], a[j] = a[j], a[i]
}
func (a ByStart) Less(i, j int) bool {
	return a[i].Start.After(a[j].Start)
}
func (a ByStart) Len() int {
	return len(a)
}

func (c *Control) SaveEditedActivity(index int, name string, tags string,
	description string,
	start string, end string) {

	var (
		err      error
		activity *Activity
	)
	if index == -1 {
		activity = &Activity{}
	} else {
		activity = c.Activities[index]
	}
	if activity != ctrl.CurrentActivity {
		activity.Name = name
		activity.ForeignTags = parseTags(tags)
		activity.Tags = tags
		activity.Description = description
		activity.Start, err = time.ParseInLocation(shortDateFormat, start, baseLocation)
		if err != nil {
			return
		}
		activity.End, err = time.ParseInLocation(shortDateFormat, end, baseLocation)
		if err != nil {
			return
		}

		c.SaveActivity(activity)
		if index == -1 {
			ctrl.Activities = append(ctrl.Activities, activity)
		}
		c.UpdateActivities(-1)
	}
}

func (c *Control) StopActivity() {
	if c.CurrentActivity != nil {
		c.CurrentActivity.End = time.Now()
		c.SaveActivity(c.CurrentActivity)
		c.SetCurrentActivity(nil)
		c.UpdateActivities(0)
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
	c.UpdateActivities(-1)
}

func (c *Control) UpdateTable(idx int) {
	defer func() {
		if err := recover(); err != nil {
			log.Println(err)
		}
	}()

	// var lastDayName string

	for i := 0; i < len(ctrl.Activities); i += 1 {
		if idx != -1 && i != idx {
			continue
		}

		act := ctrl.Activity(i)
		act.UpdateFields()
		// if lastDayName != "" && lastDayName == act.DayName {
		// 	act.DayName = ""
		// }

		qml.Changed(act, &act.Name)
		qml.Changed(act, &act.Duration)
		qml.Changed(act, &act.TimePeriod)
		qml.Changed(act, &act.DayName)

		// if len(act.DayName) > 0 {
		// 	lastDayName = act.DayName
		// }
	}

	var todayDuration time.Duration
	today := getToday()
	for _, a := range ctrl.Activities {
		if a.Start.After(today) {
			todayDuration += a.GetDuration()
		}
	}
	if todayDuration > 0 {
		ctrl.Root.Set("todayText", "Today: "+verboseDuration(todayDuration))
	} else {
		ctrl.Root.Set("todayText", "")
	}
}

func (c *Control) UpdateActivities(idx int) {
	sort.Sort(ByStart(ctrl.Activities))
	ctrl.ActivitiesLen = len(ctrl.Activities)
	qml.Changed(&ctrl, &ctrl.ActivitiesLen)
	go c.UpdateTable(idx)
}

func (c *Control) LoadActivities(init bool) {
	var activities []Activity
	dt := getToday().Add(-time.Hour * 24 * 31)
	db.Order("start desc").Where("start >= ?", dt).Find(&activities)
	for _, v := range activities {
		var activity = v
		activity.End = activity.End.In(baseLocation)
		activity.Start = activity.Start.In(baseLocation)
		ctrl.Activities = append(ctrl.Activities, &activity)
		activity.UpdateFields()
	}

	if len(ctrl.Activities) > 0 && ctrl.Activities[0].End.IsZero() {
		ctrl.SetCurrentActivity(ctrl.Activity(0))
	}

	c.UpdateActivities(-1)
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
		ctrl.UpdateActivities(-2)
	}
}

func run() error {
	engine := qml.NewEngine()
	component, err := engine.LoadFile("resources/qml/MainWindow.qml")
	if err != nil {
		return err
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

	return nil
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
	if err := qml.Run(nil, run); err != nil {
		log.Fatalf("Error: %v\n", err)
	}
}
