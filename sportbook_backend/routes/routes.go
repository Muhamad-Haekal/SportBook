package routes

import (
	"sportbook/handlers"
	"sportbook/middleware"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/filesystem"
	"net/http"
	"os"
)

func SetupRoutes(app *fiber.App) {
	app.Post("/auth/register", handlers.Register)
	app.Post("/auth/login", handlers.Login)

	app.Get("/fields", handlers.GetFields)

	// Serve static uploads
	app.Use("/uploads", filesystem.New(filesystem.Config{
		Root: http.FS(os.DirFS("./uploads")),
	}))

	user := app.Group("/", middleware.AuthRequired)
	user.Post("/bookings", handlers.CreateBooking)
	user.Get("/bookings/my", handlers.GetMyBookings)
	user.Get("/fields/:id/bookings", handlers.GetFieldBookings)
	user.Put("/bookings/:id/cancel", handlers.CancelBooking)
	user.Get("/profile", handlers.GetProfile)
	user.Put("/profile", handlers.UpdateProfile)

	admin := app.Group("/admin", middleware.AuthRequired, middleware.AdminOnly)
	admin.Post("/upload", handlers.UploadPhoto)
	admin.Post("/fields", handlers.CreateField)
	admin.Put("/fields/:id", handlers.UpdateField)
	admin.Delete("/fields/:id", handlers.DeleteField)
	admin.Get("/bookings", handlers.GetAllBookings)
	admin.Put("/bookings/:id/status", handlers.UpdateBookingStatus)
}
