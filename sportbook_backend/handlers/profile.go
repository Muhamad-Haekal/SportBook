package handlers

import (
	"sportbook/config"
	"sportbook/models"

	"github.com/gofiber/fiber/v2"
	"golang.org/x/crypto/bcrypt"
)

func GetProfile(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)
	var user models.User
	if err := config.DB.First(&user, userID).Error; err != nil {
		return c.Status(404).JSON(fiber.Map{"message": "User not found"})
	}
	return c.JSON(user)
}

func UpdateProfile(c *fiber.Ctx) error {
	userID := c.Locals("user_id").(uint)

	var body struct {
		Name     string `json:"name"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"message": "Invalid input"})
	}

	var user models.User
	if err := config.DB.First(&user, userID).Error; err != nil {
		return c.Status(404).JSON(fiber.Map{"message": "User not found"})
	}

	if body.Name != "" {
		user.Name = body.Name
	}
	if body.Email != "" {
		user.Email = body.Email
	}
	if body.Password != "" {
		hash, _ := bcrypt.GenerateFromPassword([]byte(body.Password), 14)
		user.Password = string(hash)
	}

	if err := config.DB.Save(&user).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"message": "Gagal update profile"})
	}

	return c.JSON(fiber.Map{"message": "Profile berhasil diupdate", "user": user})
}
