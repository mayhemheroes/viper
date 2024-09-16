package myfuzz
import "github.com/spf13/viper"

func Fuzz(data[] byte) int {
	viper.SetDefault(string(data), string(data))
	return 0
}
