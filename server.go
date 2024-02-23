package main

// go mod init github.com/jhannah/legislature_calendar
// go get -u github.com/gin-gonic/gin
// go get -u gorm.io/gorm
// go get -u gorm.io/driver/sqlite
// go get -u golang.org/x/exp/maps
// go run server.go
// http://localhost:8080

import (
	"net/http"
	"net/url"
	"strconv"

	"github.com/gin-gonic/gin"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

var title = "Nebraska 2023-2024 Regular Session 108th Legislature"

type Bill struct {
	gorm.Model
	ID             int
	SessionID      int
	Number         string
	NumberNumeric  int
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
	// Add .Debug() to the front of the chain to see debug stuff :)
	result1 := db.Order("last_action_date DESC, number_numeric ASC").Find(&allBills)

	router.GET("/", func(c *gin.Context) {
		var myBills []MyBill
		var result2 *gorm.DB
		var u User
		userID, _ := c.Cookie("userID")
		if userID != "" {
			result2 = db.Order("last_action_date DESC, number_numeric ASC").Table("bills").Select("bills.*, watchlists.stance").Joins(
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
			"Title":         title,
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

		/*
			1) So here's our original one-liner GORM version, which magically cascades to all our tables.
			But we're unhappy with the sub-sorting. So we try more complicated things below.
			db.Debug().Preload("Watchlists.Bill").Preload(clause.Associations).Find(&users)

			2) https://gorm.io/docs/preload.html#Custom-Preloading-SQL
			This also doesn't work because GORM's not sorting the watchlists (per the bills fields)
			it sorts the bills. But we don't iterate the bills, we iterate the watchlists.
			db.Debug().Preload("Watchlists.Bill", func(db *gorm.DB) *gorm.DB {
				return db.Order("bills.last_action_date DESC, bills.number_numeric ASC")
			}).Order("users.name ASC").Find(&users)

			3) And this variation tries to work but fails on the backend: no such column: bills.last_action_date
			db.Debug().Preload("Watchlists", func(db *gorm.DB) *gorm.DB {
				return db.Order("bills.last_action_date DESC, bills.number_numeric ASC")
			}).Order("users.name ASC").Find(&users)

			4) https://stackoverflow.com/a/67078725
			And this rumor is fascinating, but I can't get any variation of this to work either.
			All variations I've tried either runtime explode Golang, or generate invalid SQL that SQLite rejects.
			db.Debug().Model(&User{}).
				Order("users.name ASC").
				Joins("Watchlists").
				Joins("Bills").
				Order("bills.last_action_date DESC, bills.number_numeric ASC").
				Find(&users)

			So... we'll write 50 lines of our own code. -sigh-
		*/

		var sqlStr string
		knownUserIds := make(map[int]User)
		sqlStr = `
			SELECT users.id, users.name, users.url,
				bills.url, bills.number,
				watchlists.stance,
				bills.last_action_date, bills.last_action, bills.title
			FROM users
			JOIN watchlists on watchlists.user_id = users.id
			JOIN bills on watchlists.bill_id = bills.id
			WHERE users.deleted_at IS NULL
			AND watchlists.deleted_at IS NULL
			AND bills.deleted_at IS NULL
			ORDER BY users.name ASC, bills.last_action_date DESC, bills.number_numeric ASC
		`
		var user_id int
		var user_name, user_url, bill_url, bill_number, watchlist_stance, bill_last_action_date, bill_last_action, bill_title string
		// ignore err. Add .Debug() up front to debug the SQL
		rows, _ := db.Raw(sqlStr).Rows()
		defer rows.Close()
		var user_index = 0
		for rows.Next() {
			rows.Scan(&user_id, &user_name, &user_url, &bill_url, &bill_number, &watchlist_stance, &bill_last_action_date, &bill_last_action, &bill_title)
			thisUser := knownUserIds[user_id]
			thisUser.ID = user_id
			thisUser.Name = user_name
			thisUser.URL = user_url
			thisUser.Watchlists = append(thisUser.Watchlists, Watchlist{
				UserID: user_id,
				Stance: watchlist_stance,
				Bill: Bill{
					Number:         bill_number,
					URL:            bill_url,
					LastActionDate: bill_last_action_date,
					LastAction:     bill_last_action,
					Title:          bill_title,
				},
			})
			_, ok := knownUserIds[user_id]
			if !ok {
				// store users in SQL sorted order
				user_index += 1
				users = append(users, thisUser)
			}
			knownUserIds[user_id] = thisUser
			users[user_index-1] = thisUser
		}

		c.HTML(http.StatusOK, "users.tmpl", gin.H{
			"User":  user,
			"Users": users,
			"Title": title,
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

	router.Static("/img", "./img")

	// By default it serves on :8080 unless a
	// PORT environment variable was defined.
	router.Run()
}
