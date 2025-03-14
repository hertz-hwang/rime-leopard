package utils

import "time"

// Now 返回当前时间
func Now() time.Time {
	return time.Now()
}

// Since 计算从某个时间点到现在经过的时间
func Since(t time.Time) time.Duration {
	return time.Since(t)
}
