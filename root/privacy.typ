#import "lib.typ": *
#show: schema.with("index")

#page-title[Privacy | Justin Restivo]
#description[What this site collects and how to turn analytics off.]

I use self-hosted, cookie-free analytics to see which pages get read and where visitors come from. IP addresses aren't stored, and nothing is sold or shared. Analytics are off if your browser sends Do Not Track or Global Privacy Control.

#context if target() == "html" {
  html.elem("div", attrs: (class: "analytics-panel"))[
    #html.elem("p", attrs: (id: "analytics-status", role: "status", "aria-live": "polite"))[Analytics don't run without JavaScript.]
    #html.elem(
      "button",
      attrs: (type: "button", "data-analytics-toggle": "", "aria-describedby": "analytics-status", hidden: ""),
    )[Turn off analytics]
  ]
}
