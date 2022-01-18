package main

// go mod init github.com/jhannah/legislature_calendar
// go get -u github.com/gin-gonic/gin
// go get -u gorm.io/gorm
// go get -u gorm.io/driver/sqlite
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
	ID       int
	Username string
	BillID   int
	Stance   string
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
		username, _ := c.Cookie("username")
		var myBills []MyBill
		var result2 *gorm.DB
		if username != "" {
			// Add .Debug() to the front of the chain to see debug stuff :)
			result2 = db.Order("last_action_date desc").Table("bills").Select("bills.*, watchlists.stance").Joins(
				"JOIN watchlists on watchlists.bill_id = bills.id AND watchlists.username = ? AND watchlists.deleted_at IS NULL",
				username,
			).Find(&myBills)
		}
		// uhh... not sure how to make Go happy here (unused var, sometimes)
		if result2 == nil {
			result2 = nil
		}
		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"Username":      username,
			"Title":         "Nebraska 2021-2022 Regular Session 107th Legislature",
			"AllBills":      allBills,
			"MyBills":       myBills,
			"RowsAffected1": result1.RowsAffected,
			"Error1":        result1.Error,
			//"RowsAffected2": result2.RowsAffected,
			//"Error2":        result2.Error,
		})
	})

	router.GET("/watch/:billID/:stance", func(c *gin.Context) {
		username, _ := c.Cookie("username")
		billID := c.Param("billID")
		intBillID, err := strconv.Atoi(billID)
		if err != nil {
			c.Error(err)
			return
		}
		stance := c.Param("stance")
		var w Watchlist
		db.Where("username = ? and bill_id = ?", username, intBillID).Find(&w)
		db.Delete(&w)
		if stance != "U" {
			db.Create(&Watchlist{Username: username, BillID: intBillID, Stance: stance})
		}
		// db.Commit()
		location := url.URL{Path: "/"} // , RawQuery: q.Encode()}
		c.Redirect(http.StatusFound, location.RequestURI())
	})

	router.POST("/login", func(c *gin.Context) {
		// https://chenyitian.gitbooks.io/gin-tutorials/content/docker/4.html
		username := c.PostForm("username")
		//password := c.PostForm("password")
		c.SetCookie("username", username, 3600, "", "", false, true)
		// https://stackoverflow.com/questions/61970551/golang-gin-redirect-and-render-a-template-with-new-variables
		location := url.URL{Path: "/"} // , RawQuery: q.Encode()}
		c.Redirect(http.StatusFound, location.RequestURI())
	})

	router.GET("/logout", func(c *gin.Context) {
		c.SetCookie("username", "", 3600, "", "", false, true)
		location := url.URL{Path: "/"} // , RawQuery: q.Encode()}
		c.Redirect(http.StatusFound, location.RequestURI())
	})

	router.GET("/init", func(c *gin.Context) {
		// Migrate the schema
		db.AutoMigrate(&Bill{}, &Watchlist{})

		// Create
		// db.Create(&Bill{ID: 1, SessionID: 1810, Number: "LB875", Status: "Introduced", LastActionDate: "2022-01-07", LastAction: "Date of introduction", Title: "Rename the Director-State Engineer for the Department of Transportation as the Director of Transportation for the Department of Transportation", URL: "https://legiscan.com/NE/bill/LB875/2021"})

		location := url.URL{Path: "/"} // , RawQuery: q.Encode()}
		c.Redirect(http.StatusFound, location.RequestURI())
	})

	router.Run(":8080")
}
