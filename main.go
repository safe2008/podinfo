package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {

	version := "1.0"
	if fromEnv := os.Getenv("VERSION"); fromEnv != "" {
		version = fromEnv
	}

	color := "#44B3C2" //Blue 44B3C2 and Yellow F1A94E and Red FF3333
	if fromEnv := os.Getenv("COLOR"); fromEnv != "" {
		color = fromEnv
	}

	http.HandleFunc("/callme", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "<div class='pod' style='background:%s'> ver: %s\n </div>", color, version)
	})

	fs := http.FileServer(http.Dir("./static"))
	http.Handle("/", fs)

	port := "8080"
	if fromEnv := os.Getenv("PORT"); fromEnv != "" {
		port = fromEnv
	}

	fmt.Println("Listening now at port " + port)
	http.ListenAndServe(":"+port, nil)
}
