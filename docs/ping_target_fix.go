package main

import (
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/go-ping/ping"
	"github.com/jackc/pgx/v4/pgxpool"
)

// Modified pingTarget function to fix issues with CIDR notation and improve reliability
func pingTarget(db *pgxpool.Pool, id, ip string) {
	// Extract IP without CIDR notation if present
	cleanIP := strings.Split(ip, "/")[0]

	log.Printf("🏓 Pinging %s (original: %s)", cleanIP, ip)

	pinger, err := ping.NewPinger(cleanIP)
	if err != nil {
		log.Printf("⚠️ Ping init error [%s]: %v", cleanIP, err)
		structuredLogger.Error(internal.LogCategoryPing, fmt.Sprintf("Ping init error: %v", err),
			internal.WithEndpointID(id),
			internal.WithIPAddress(ip),
			internal.WithMetadata("error", err.Error()))
		storage.SavePingResult(db, id, ip, 0, false)
		return
	}

	// Increase reliability with multiple pings and longer timeout
	pinger.Count = 3
	pinger.Timeout = 5 * time.Second
	pinger.SetPrivileged(true)

	if err := pinger.Run(); err != nil {
		log.Printf("❌ Ping failed [%s]: %v", cleanIP, err)
		structuredLogger.Error(internal.LogCategoryPing, fmt.Sprintf("Ping failed: %v", err),
			internal.WithEndpointID(id),
			internal.WithIPAddress(ip),
			internal.WithMetadata("error", err.Error()))
		storage.SavePingResult(db, id, ip, 0, false)
		return
	}

	stats := pinger.Statistics()
	if stats.PacketsRecv > 0 {
		// Success if ANY packet is received
		log.Printf("✅ Host alive: %s (%d/%d packets, avg RTT: %v)",
			cleanIP, stats.PacketsRecv, stats.PacketsSent, stats.AvgRtt)
		structuredLogger.Info(internal.LogCategoryPing, "Host alive",
			internal.WithEndpointID(id),
			internal.WithIPAddress(ip),
			internal.WithMetadata("ping_ms", int(stats.AvgRtt.Milliseconds())),
			internal.WithMetadata("packets_sent", stats.PacketsSent),
			internal.WithMetadata("packets_recv", stats.PacketsRecv))
		storage.SavePingResult(db, id, ip, int(stats.AvgRtt.Milliseconds()), true)
	} else {
		log.Printf("⛔ Host unreachable: %s (0/%d packets)", cleanIP, stats.PacketsSent)
		structuredLogger.Warn(internal.LogCategoryPing, "Host unreachable",
			internal.WithEndpointID(id),
			internal.WithIPAddress(ip),
			internal.WithMetadata("packets_sent", stats.PacketsSent),
			internal.WithMetadata("packets_recv", stats.PacketsRecv))
		storage.SavePingResult(db, id, ip, 0, false)
	}
}
