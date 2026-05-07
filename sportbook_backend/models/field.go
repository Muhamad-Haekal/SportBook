package models

import "gorm.io/gorm"

type Field struct {
	gorm.Model
	Name         string `json:"name"`
	Type         string `json:"type"`
	Description  string `json:"description"`
	Photo        string `json:"photo"`
	PricePerHour int    `json:"price_per_hour"`
	OpenTime     string `json:"open_time"`
	CloseTime    string `json:"close_time"`
	IsClosed     bool   `json:"is_closed"`
	LocationLink string `json:"location_link"`
}
