package main

// go mod init github.com/jhannah/legislature_calendar
// go get -u github.com/gin-gonic/gin
// go get -u gorm.io/gorm
// go get -u gorm.io/driver/sqlite
// go run server.go
// http://localhost:8080

import (
	"fmt"
	"net/http"
	"net/url"

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

func main() {
	router := gin.Default()
	router.LoadHTMLGlob("templates/*.tmpl")
	//router.LoadHTMLFiles("templates/template1.html", "templates/template2.html")

	db, err := gorm.Open(sqlite.Open("leg.sqlite3"), &gorm.Config{})
	if err != nil {
		panic("failed to connect to database")
	}
	var bills []Bill
	result := db.Order("last_action_date desc").Find(&bills)

	router.GET("/", func(c *gin.Context) {
		username, err := c.Cookie("username")
		if err != nil {
			return
		}

		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"Username":     username,
			"Title":        "Nebraska 2021-2022 Regular Session 107th Legislature",
			"Bills":        bills,
			"RowsAffected": result.RowsAffected,
			"Error":        result.Error,
		})
	})

	router.POST("/login", func(c *gin.Context) {
		// https://chenyitian.gitbooks.io/gin-tutorials/content/docker/4.html
		username := c.PostForm("username")
		fmt.Println("JAY0", username)
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
		db.AutoMigrate(&Bill{})

		// Create
		db.Create(&Bill{ID: 1, SessionID: 1810, Number: "LB875", Status: "Introduced", LastActionDate: "2022-01-07", LastAction: "Date of introduction", Title: "Rename the Director-State Engineer for the Department of Transportation as the Director of Transportation for the Department of Transportation", URL: "https://legiscan.com/NE/bill/LB875/2021"})

		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"Title":        "Main website",
			"Bills":        bills,
			"RowsAffected": result.RowsAffected,
			"Error":        result.Error,
		})
	})

	router.Run(":8080")
}
