package handlers

import (
    "fmt"
    "sportbook/config"
    "sportbook/models"
    "strconv"
    "strings"

    "github.com/gofiber/fiber/v2"
    "gorm.io/gorm"
)

func calculateHours(start, end string) int {
	startParts := strings.Split(start, ":")
	endParts := strings.Split(end, ":")
	startHour, _ := strconv.Atoi(startParts[0])
	startMin, _ := strconv.Atoi(startParts[1])
	endHour, _ := strconv.Atoi(endParts[0])
	endMin, _ := strconv.Atoi(endParts[1])
	totalMinutes := (endHour*60 + endMin) - (startHour*60 + startMin)
	if totalMinutes <= 0 {
		return 1
	}
	hours := totalMinutes / 60
	if totalMinutes%60 > 0 {
		hours++
	}
	return hours
}

func CreateBooking(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)

	var body struct {
		FieldID       uint   `json:"field_id"`
		Date          string `json:"date"`
		StartTime     string `json:"start_time"`
		EndTime       string `json:"end_time"`
		PaymentMethod string `json:"payment_method"`
	}

	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"message": "Invalid input"})
	}

	var conflictCount int64
	config.DB.Model(&models.Booking{}).Where(`
		field_id = ? AND date = ? AND status != 'cancelled' AND status != 'rejected' AND (
			(start_time <= ? AND end_time > ?) OR
			(start_time < ? AND end_time >= ?) OR
			(start_time >= ? AND end_time <= ?)
		)`,
		body.FieldID, body.Date,
		body.StartTime, body.StartTime,
		body.EndTime, body.EndTime,
		body.StartTime, body.EndTime,
	).Count(&conflictCount)

	if conflictCount > 0 {
		return c.Status(409).JSON(fiber.Map{"message": "Lapangan sudah dibooking pada jam tersebut!"})
	}

	var field models.Field
	config.DB.First(&field, body.FieldID)
	hours := calculateHours(body.StartTime, body.EndTime)
	totalPrice := field.PricePerHour * hours

	fmt.Printf("Hours: %d, Price per hour: %d, Total: %d\n", hours, field.PricePerHour, totalPrice)

	booking := models.Booking{
		UserID:        userID,
		FieldID:       body.FieldID,
		Date:          body.Date,
		StartTime:     body.StartTime,
		EndTime:       body.EndTime,
		Status:        "pending",
		PaymentMethod: body.PaymentMethod,
		PaymentStatus: "unpaid",
		TotalPrice:    totalPrice,
	}

	config.DB.Create(&booking)
	return c.Status(201).JSON(booking)
}

func GetMyBookings(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	var bookings []models.Booking
	config.DB.Preload("Field").Where("user_id = ?", userID).Find(&bookings)
	return c.JSON(bookings)
}

func GetFieldBookings(c *fiber.Ctx) error {
	fieldID := c.Params("id")
	date := c.Query("date")

	if date == "" {
		return c.Status(400).JSON(fiber.Map{"message": "Date is required"})
	}

	var bookings []models.Booking
	config.DB.Where("field_id = ? AND date = ? AND status != 'cancelled' AND status != 'rejected'", fieldID, date).Find(&bookings)

	return c.JSON(bookings)
}

func CancelBooking(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	id := c.Params("id")

	var booking models.Booking
	if err := config.DB.Where("id = ? AND user_id = ?", id, userID).First(&booking).Error; err != nil {
		return c.Status(404).JSON(fiber.Map{"message": "Booking not found"})
	}

	booking.Status = "cancelled"
	config.DB.Save(&booking)
	return c.JSON(fiber.Map{"message": "Booking cancelled"})
}

func GetAllBookings(c *fiber.Ctx) error {
	var bookings []models.Booking
	config.DB.Preload("User").Preload("Field").Find(&bookings)
	return c.JSON(bookings)
}

func UpdateBookingStatus(c *fiber.Ctx) error {
	id := c.Params("id")

	var body struct {
		Status string `json:"status"`
	}

	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"message": "Invalid input"})
	}

	var booking models.Booking
	if err := config.DB.First(&booking, id).Error; err != nil {
		return c.Status(404).JSON(fiber.Map{"message": "Booking not found"})
	}

	booking.Status = body.Status
	if body.Status == "confirmed" && booking.PaymentMethod == "cash" {
		booking.PaymentStatus = "pending_cash"
	}
	config.DB.Save(&booking)
	return c.JSON(fiber.Map{"message": "Status updated", "booking": booking})
}

func DeleteBooking(c *fiber.Ctx) error {
	id := c.Params("id")
	
	var booking models.Booking
	if err := config.DB.First(&booking, id).Error; err != nil {
		return c.Status(404).JSON(fiber.Map{"message": "Booking not found"})
	}

	config.DB.Delete(&booking)
	return c.JSON(fiber.Map{"message": "Booking deleted"})
}

func DeleteAllBookings(c *fiber.Ctx) error {
	if err := config.DB.Session(&gorm.Session{AllowGlobalUpdate: true}).Delete(&models.Booking{}).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"message": "Gagal menghapus semua booking"})
	}
	return c.JSON(fiber.Map{"message": "Semua booking berhasil dihapus"})
}
