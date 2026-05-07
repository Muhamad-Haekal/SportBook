package main

import (
	"log"
	"sportbook/config"
	"sportbook/routes"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
)

func main() {
	config.ConnectDB()

	app := fiber.New()

	app.Use(cors.New())

	routes.SetupRoutes(app)

	log.Fatal(app.Listen(":8080"))
}
