# downloading a website for offline usage

`` bash
# Main blog
wget --mirror --convert-links --adjust-extension --page-requisites \
     --no-parent --wait=1 --random-wait --execute robots=on \
     --user-agent="ResearchBot (contact: you@example.com)" \
     https://invertedpassion.com/

# Knowledge Garden
wget --mirror --convert-links --adjust-extension --page-requisites \
     --no-parent --wait=1 --random-wait --execute robots=on \
     --user-agent="ResearchBot (contact: you@example.com)" \
     https://notes.invertedpassion.com/

``` 

``` python

```