package handlers

import (
	"sportbook/config"
	"sportbook/models"

	"github.com/gofiber/fiber/v2"
)

func GetFields(c *fiber.Ctx) error {
	var fields []models.Field
	config.DB.Find(&fields)
	return c.JSON(fields)
}

func CreateField(c *fiber.Ctx) error {
	var field models.Field
	if err := c.BodyParser(&field); err != nil {
		return c.Status(400).JSON(fiber.Map{"message": "Invalid input"})
	}
	config.DB.Create(&field)
	return c.Status(201).JSON(field)
}

func UpdateField(c *fiber.Ctx) error {
	id := c.Params("id")
	var field models.Field
	if err := config.DB.First(&field, id).Error; err != nil {
		return c.Status(404).JSON(fiber.Map{"message": "Field not found"})
	}
	c.BodyParser(&field)
	config.DB.Save(&field)
	return c.JSON(field)
}

func DeleteField(c *fiber.Ctx) error {
	id := c.Params("id")
	config.DB.Delete(&models.Field{}, id)
	return c.JSON(fiber.Map{"message": "Field deleted"})
}
