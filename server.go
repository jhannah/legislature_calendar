package main

// go mod init github.com/jhannah/legislature_calendar
// go get -u github.com/gin-gonic/gin
// go get -u gorm.io/gorm
// go get -u gorm.io/driver/sqlite
// go get -u golang.org/x/exp/maps
// go run server.go
// http://localhost:8080

import (
	"fmt"
	"net/http"
	"net/url"
	"strconv"

	"github.com/gin-gonic/gin"
	"golang.org/x/exp/maps"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type Bill struct {
	gorm.Model
	ID             int
	SessionID      int
	Number         string
	Status         string
	LastActionDate string
	LastAction     string
	Title          string
	URL            string
}

type MyBill struct {
	ID             int
	SessionID      int
	Number         string
	Status         string
	LastActionDate string
	LastAction     string
	Title          string
	URL            string
	Stance         string
}

type Watchlist struct {
	gorm.Model
	ID     int
	UserID int
	BillID int
	Stance string
	Bill   Bill
}

type User struct {
	gorm.Model
	ID         int
	Username   string
	Password   string
	Name       string
	Email      string
	URL        string
	Watchlists []Watchlist
}

func main() {
	router := gin.Default()
	router.LoadHTMLGlob("templates/*.tmpl")
	//router.LoadHTMLFiles("templates/template1.html", "templates/template2.html")

	db, err := gorm.Open(sqlite.Open("leg.sqlite3"), &gorm.Config{})
	if err != nil {
		panic("failed to connect to database")
	}
	var allBills []Bill
	// Add .Limit(5) to the front of the chain to see less data
	result1 := db.Order("last_action_date desc").Find(&allBills)

	router.GET("/", func(c *gin.Context) {
		var myBills []MyBill
		var result2 *gorm.DB
		var u User
		userID, _ := c.Cookie("userID")
		if userID != "" {
			// Add .Debug() to the front of the chain to see debug stuff :)
			result2 = db.Order("last_action_date desc").Table("bills").Select("bills.*, watchlists.stance").Joins(
				"JOIN watchlists on watchlists.bill_id = bills.id AND watchlists.user_id = ? AND watchlists.deleted_at IS NULL",
				userID,
			).Find(&myBills)
			db.Where("id = ?", userID).Find(&u)
		}
		// uhh... not sure how to make Go happy here (unused var, sometimes)
		if result2 == nil {
			result2 = nil
		}
		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"User":          u,
			"Title":         "Nebraska 2023-2024 Regular Session 108th Legislature",
			"AllBills":      allBills,
			"MyBills":       myBills,
			"RowsAffected1": result1.RowsAffected,
			"Error1":        result1.Error,
			//"RowsAffected2": result2.RowsAffected,
			//"Error2":        result2.Error,
		})
	})

	router.GET("/watch/:billID/:stance", func(c *gin.Context) {
		userID, _ := c.Cookie("userID")
		intUserID, err := strconv.Atoi(userID)
		if err != nil {
			c.Error(err)
			return
		}
		billID := c.Param("billID")
		intBillID, err := strconv.Atoi(billID)
		if err != nil {
			c.Error(err)
			return
		}
		stance := c.Param("stance")
		var w Watchlist
		db.Where("user_id = ? and bill_id = ?", intUserID, intBillID).Delete(&w)
		if stance != "U" {
			db.Create(&Watchlist{UserID: intUserID, BillID: intBillID, Stance: stance})
		}
		// db.Commit()
		location := url.URL{Path: "/"} // , RawQuery: q.Encode()}
		c.Redirect(http.StatusFound, location.RequestURI())
	})

	router.POST("/login", func(c *gin.Context) {
		// https://chenyitian.gitbooks.io/gin-tutorials/content/docker/4.html
		username := c.PostForm("username")
		//password := c.PostForm("password")

		var u User
		db.Where("username = ?", username).Find(&u)
		if u.ID == 0 {
			db.Create(&User{Username: username})
			db.Where("username = ?", username).Find(&u)
		}
		c.SetCookie("userID", strconv.Itoa(u.ID), 3600, "", "", false, true)
		// https://stackoverflow.com/questions/61970551/golang-gin-redirect-and-render-a-template-with-new-variables
		location := url.URL{Path: "/"} // , RawQuery: q.Encode()}
		c.Redirect(http.StatusFound, location.RequestURI())
	})

	router.GET("/logout", func(c *gin.Context) {
		c.SetCookie("userID", "", 3600, "", "", false, true)
		location := url.URL{Path: "/"} // , RawQuery: q.Encode()}
		c.Redirect(http.StatusFound, location.RequestURI())
	})

	router.GET("/user", func(c *gin.Context) {
		userID, _ := c.Cookie("userID")
		intUserID, err := strconv.Atoi(userID)
		if err != nil {
			c.Error(err)
			return
		}
		var u User
		db.Where("id = ?", intUserID).Find(&u)
		c.HTML(http.StatusOK, "user.tmpl", gin.H{
			"User": u,
		})
	})

	router.POST("/user", func(c *gin.Context) {
		userID, _ := c.Cookie("userID")
		intUserID, err := strconv.Atoi(userID)
		if err != nil {
			c.Error(err)
			return
		}
		var u User
		db.Where("id = ?", intUserID).Find(&u)
		u.Username = c.PostForm("username")
		u.Password = c.PostForm("password")
		u.Name = c.PostForm("name")
		u.Email = c.PostForm("email")
		u.URL = c.PostForm("url")
		db.Save(&u)
		location := url.URL{Path: "/"} // , RawQuery: q.Encode()}
		c.Redirect(http.StatusFound, location.RequestURI())
	})

	router.GET("/users", func(c *gin.Context) {
		userID, _ := c.Cookie("userID")
		var intUserID int
		if userID != "" {
			intUserID, _ = strconv.Atoi(userID)
		}
		var user User
		db.Where("id = ?", intUserID).Find(&user)

		var users []User

		// So here's our original one-liner version, which magically cascades to all our tables,
		// but we're unhappy with the sub-sorting so we do more complicated things:
		db.Debug().Preload("Watchlists.Bill").Preload(clause.Associations).Find(&users)

		var sqlStr string
		knownUserIds := make(map[any]User)
		sqlStr = `
			SELECT users.id, users.name, users.url,
				bills.url, bills.number,
			  watchlists.stance,
				bills.last_action_date, bills.last_action, bills.title
			FROM users
			JOIN watchlists on watchlists.user_id = users.id
			JOIN bills on watchlists.bill_id = bills.id
			ORDER BY users.name ASC, bills.last_action_date DESC
			;
		`
		thisRow := make([]interface{}, 9) // 9 columns
		for i := range thisRow {
			thisRow[i] = new(interface{})
		}
		// ignore err
		rows, _ := db.Debug().Raw(sqlStr).Rows()
		defer rows.Close()
		for rows.Next() {
			rows.Scan(thisRow...)
			fmt.Println("thisRow is", thisRow)
			fmt.Println("thisRow[0] is", &thisRow[0])
			thisUser := knownUserIds[thisRow[0]]
			thisUser.ID = thisRow[0].(int)
			thisUser.Name = thisRow[1].(string)
			thisUser.URL = thisRow[2].(string)
			thisUser.Watchlists = append(thisUser.Watchlists, Watchlist{
				UserID: thisUser.ID,
				Stance: thisRow[5].(string),
				Bill: Bill{
					Number:         thisRow[4].(string),
					URL:            thisRow[3].(string),
					LastActionDate: thisRow[6].(string),
					LastAction:     thisRow[7].(string),
					Title:          thisRow[8].(string),
				},
			})
		}

		// Add .Debug() to the front of the chain to see debug stuff :)
		// .Order("bills.last_action_date DESC")
		// db.Debug().Preload("Watchlists.Bill").Order("bills.last_action_date desc").Preload(clause.Associations).Find(&users)
		//db.Debug().Preload("Watchlists.Bill", func(db *gorm.DB) *gorm.DB {
		//	return db.Order("bills.last_action_date DESC")
		//}).Find(&users)
		// db.Debug().Table("users").Preload(clause.Associations).Select("users.*, bills.*, watchlists.stance").Joins("JOIN watchlists on users.id = watchlists.user_id AND watchlists.deleted_at IS NULL").Joins("JOIN bills on watchlists.bill_id = bills.id").Order("bills.last_action_date desc").Find(&users)

		fmt.Println("howdy")
		fmt.Println(maps.Values(knownUserIds))
		c.HTML(http.StatusOK, "users.tmpl", gin.H{
			"User":  user,
			"Users": maps.Values(knownUserIds),
			"Title": "Nebraska 2021-2022 Regular Session 107th Legislature",
		})
	})

	router.GET("/init", func(c *gin.Context) {
		// Migrate the schema
		db.AutoMigrate(&Bill{}, &Watchlist{}, &User{})

		// Create
		// db.Create(&Bill{ID: 1, SessionID: 1810, Number: "LB875", Status: "Introduced", LastActionDate: "2022-01-07", LastAction: "Date of introduction", Title: "Rename the Director-State Engineer for the Department of Transportation as the Director of Transportation for the Department of Transportation", URL: "https://legiscan.com/NE/bill/LB875/2021"})

		location := url.URL{Path: "/"} // , RawQuery: q.Encode()}
		c.Redirect(http.StatusFound, location.RequestURI())
	})

	// By default it serves on :8080 unless a
	// PORT environment variable was defined.
	router.Run()
}
