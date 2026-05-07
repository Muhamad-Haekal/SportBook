package handlers

import (
	"fmt"
	"path/filepath"
	"strings"
	"time"

	"github.com/gofiber/fiber/v2"
)

func UploadPhoto(c *fiber.Ctx) error {
	file, err := c.FormFile("photo")
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"message": "File tidak ditemukan"})
	}

	// Validasi ekstensi
	ext := strings.ToLower(filepath.Ext(file.Filename))
	if ext != ".jpg" && ext != ".jpeg" && ext != ".png" {
		return c.Status(400).JSON(fiber.Map{"message": "Format file harus jpg/jpeg/png"})
	}

	// Buat nama file unik
	filename := fmt.Sprintf("%d%s", time.Now().UnixNano(), ext)
	savePath := fmt.Sprintf("./uploads/%s", filename)

	if err := c.SaveFile(file, savePath); err != nil {
		return c.Status(500).JSON(fiber.Map{"message": "Gagal upload file"})
	}

	return c.JSON(fiber.Map{
		"message":  "Upload berhasil",
		"filename": filename,
		"url":      fmt.Sprintf("/uploads/%s", filename),
	})
}
