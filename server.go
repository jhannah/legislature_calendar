package main

// go mod init github.com/jhannah/legislature_calendar
// go get -u github.com/gin-gonic/gin
// go get -u gorm.io/gorm
// go get -u gorm.io/driver/sqlite
// go run server.go
// http://localhost:8080

import (
  "github.com/gin-gonic/gin"
  "net/http"
  "gorm.io/gorm"
  "gorm.io/driver/sqlite"
)

type Bill struct {
  gorm.Model
  ID int
  SessionID int
  Number string
  Status string
  LastActionDate string
  LastAction string
  Title string
  URL string
}

func main() {
	router := gin.Default()
	router.LoadHTMLGlob("templates/*.tmpl")
	//router.LoadHTMLFiles("templates/template1.html", "templates/template2.html")

	router.GET("/", func(c *gin.Context) {
		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"title": "Main website",
		})
	})

	router.GET("/init", func(c *gin.Context) {
    db, err := gorm.Open(sqlite.Open("leg.sqlite3"), &gorm.Config{})
    if err != nil {
      panic("failed to connect database")
    }
    // Migrate the schema
    db.AutoMigrate(&Bill{})

    // Create
    db.Create(&Bill{ID: 1, SessionID: 1810, Number: "LB875", Status: "Introduced", LastActionDate: "2022-01-07", LastAction: "Date of introduction", Title: "Rename the Director-State Engineer for the Department of Transportation as the Director of Transportation for the Department of Transportation", URL: "https://legiscan.com/NE/bill/LB875/2021"})
    var bills []Bill
    result := db.Find(&bills)

		c.HTML(http.StatusOK, "index.tmpl", gin.H{
			"Title": "Main website",
      "Bills": bills,
      "RowsAffected": result.RowsAffected,
      "Error": result.Error,
		})
	})

	router.Run(":8080")
}


