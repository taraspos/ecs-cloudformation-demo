package main

import (
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"time"

	"github.com/paddycarey/gophy"
)

var giphy = gophy.NewClient(&gophy.ClientOptions{})

func handler(w http.ResponseWriter, r *http.Request) {
	gif, err := getRandomGif()
	if err != nil {
		fmt.Println(err)
	}
	_ = gif
	html := "hello world"
	// html := fmt.Sprintf(`<iframe src="%s" width="800" height="600" frameBorder="0" class="giphy-embed" allowFullScreen></iframe>`, gif)

	fmt.Fprintf(w, html)
}

func main() {

	if len(os.Args) >= 2 && os.Args[1] == "crash" {
		time.Sleep(1 * time.Second)
		panic("Danger Zone!!!!!!!!!")
	}

	http.HandleFunc("/", handler)
	http.ListenAndServe(":8080", nil)
}

func random(max int) int {
	rand.Seed(time.Now().Unix())
	return rand.Intn(max)
}

func getRandomGif() (string, error) {
	gifs, _, err := giphy.SearchGifs("archersaurus", "G", 100, 0)
	if err != nil {
		return "", err
	}

	if len(gifs) == 0 {
		return "", fmt.Errorf("No gifs found")
	}

	randGif := gifs[random(len(gifs))]

	return randGif.EmbedURL, nil
}
