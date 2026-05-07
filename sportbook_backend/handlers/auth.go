package handlers

import (
	"os"
	"regexp"
	"sportbook/config"
	"sportbook/models"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
)

func isValidPassword(s string) bool {
	if len(s) < 8 {
		return false
	}
	hasNumber := regexp.MustCompile(`[0-9]`).MatchString(s)
	hasUpper := regexp.MustCompile(`[A-Z]`).MatchString(s)
	return hasNumber && hasUpper
}

func Register(c *fiber.Ctx) error {
	var body struct {
		Name     string `json:"name"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"message": "Invalid input"})
	}

	if !isValidPassword(body.Password) {
		return c.Status(400).JSON(fiber.Map{"message": "Password minimal 8 karakter, mengandung angka, dan minimal 1 huruf besar (Contoh: Ekal1234)"})
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(body.Password), 14)

	user := models.User{
		Name:     body.Name,
		Email:    body.Email,
		Password: string(hash),
		Role:     "user",
	}

	if err := config.DB.Create(&user).Error; err != nil {
		return c.Status(500).JSON(fiber.Map{"message": "Email already exists"})
	}

	return c.Status(201).JSON(fiber.Map{"message": "Register success"})
}

func Login(c *fiber.Ctx) error {
	var body struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := c.BodyParser(&body); err != nil {
		return c.Status(400).JSON(fiber.Map{"message": "Invalid input"})
	}

	var user models.User
	if err := config.DB.Where("email = ?", body.Email).First(&user).Error; err != nil {
		return c.Status(401).JSON(fiber.Map{"message": "Email not found"})
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(body.Password)); err != nil {
		return c.Status(401).JSON(fiber.Map{"message": "Wrong password"})
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id": user.ID,
		"role":    user.Role,
		"exp":     time.Now().Add(24 * time.Hour).Unix(),
	})

	tokenStr, _ := token.SignedString([]byte(os.Getenv("JWT_SECRET")))

	return c.JSON(fiber.Map{
		"token": tokenStr,
		"user":  user,
	})
}
