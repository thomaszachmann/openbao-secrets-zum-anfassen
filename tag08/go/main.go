// Lab-App: liest secret/shop/api und erneuert den Token per LifetimeWatcher.
package main

import (
	"context"
	"log"
	"os"
	"time"

	k8s "github.com/openbao/openbao/api/auth/kubernetes/v2"
	bao "github.com/openbao/openbao/api/v2"
)

func env(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

// login: Kubernetes-Auth; der Helper liest die JWT-Datei bei jedem Aufruf neu.
func login(ctx context.Context, c *bao.Client) (*bao.Secret, error) {
	m, err := k8s.NewKubernetesAuth(env("BAO_ROLE", "shop-api"),
		k8s.WithServiceAccountTokenPath(
			env("BAO_JWT_FILE", "/var/run/secrets/openbao/token")))
	if err != nil {
		return nil, err
	}
	s, err := c.Auth().Login(ctx, m) // setzt den Token im Client
	if err != nil {
		return nil, err
	}
	log.Printf("login: ttl=%ds policies=%v", s.Auth.LeaseDuration,
		s.Auth.Policies)
	return s, nil
}

func readSecret(ctx context.Context, c *bao.Client) {
	kv, err := c.KVv2("secret").Get(ctx, "shop/api")
	if err != nil {
		log.Printf("read: %v", err)
		return
	}
	pw, _ := kv.Data["db_password"].(string)
	if len(pw) > 3 {
		pw = pw[len(pw)-3:]
	}
	log.Printf("v%d db_user=%v db_password=***%s",
		kv.VersionMetadata.Version, kv.Data["db_user"], pw)
}

func main() {
	ctx := context.Background()
	c, err := bao.NewClient(bao.DefaultConfig()) // liest BAO_ADDR
	if err != nil {
		log.Fatal(err)
	}
	tick := time.NewTicker(10 * time.Second)
	for { // äußere Schleife: (re-)login
		s, err := login(ctx, c)
		if err != nil {
			log.Printf("login: %v", err)
			time.Sleep(5 * time.Second)
			continue
		}
		w, err := c.NewLifetimeWatcher(&bao.LifetimeWatcherInput{Secret: s})
		if err != nil {
			log.Fatal(err)
		}
		go w.Start()
		readSecret(ctx, c)
	watch:
		for {
			select {
			case err := <-w.DoneCh(): // max_ttl erreicht oder Fehler
				log.Printf("watcher done (err=%v) -> re-login", err)
				break watch
			case r := <-w.RenewCh():
				log.Printf("renewed: ttl=%ds", r.Secret.Auth.LeaseDuration)
			case <-tick.C:
				readSecret(ctx, c)
			}
		}
		w.Stop()
	}
}
