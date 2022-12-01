package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	gin.SetMode(setting.ServerSetting.RunMode)
}
