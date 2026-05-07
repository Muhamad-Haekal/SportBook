package main

import (
	"fmt"
	"log"
	"sportbook/config"
	"sportbook/models"
)

func main() {
	config.ConnectDB()

	var user models.User
	if err := config.DB.Where("email = ?", "haekal@gmail.com").First(&user).Error; err != nil {
		log.Fatal("User not found:", err)
	}

	fmt.Println("Admin User Hash:", user.Password)
}
