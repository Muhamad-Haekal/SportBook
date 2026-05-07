package models

import "gorm.io/gorm"

type Booking struct {
	gorm.Model
	UserID    uint   `json:"user_id"`
	User      User   `json:"user" gorm:"foreignKey:UserID"`
	FieldID   uint   `json:"field_id"`
	Field     Field  `json:"field" gorm:"foreignKey:FieldID"`
	Date      string `json:"date"`
	StartTime string `json:"start_time"`
	EndTime   string `json:"end_time"`
	Status    string `json:"status" gorm:"default:pending"`
	PaymentMethod string `json:"payment_method"`
	PaymentStatus string `json:"payment_status" gorm:"default:unpaid"`
	TotalPrice    int    `json:"total_price"`
}
