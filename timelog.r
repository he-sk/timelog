library(ggplot2)
library(plyr)
library(lubridate)

# Number of weeks
weeks <- 4

# Order of categories
order <- c("Schlafen", "Essen",
           "Arbeit", "Pause",
           "Review", "Erledigung", "Projekt",
           "Familie", "Date", "Freunde", "Ausgehen",
           "Fotografie", "Beauty",
           "Pendeln", "Prokrastination")

# Colors
# http://sape.inf.usi.ch/sites/default/files/ggplot2-colour-names.png
colors <- c("steelblue1",     # Schlafen
            "steelblue4",     # Essen
            "gold",           # Arbeit
            "goldenrod3",     # Pause
            "darkseagreen4",  # Review
            "darkseagreen3",  # Erledigung
            "darkseagreen1",  # Projekt
            "darkorchid4",    # Familie
            "darkorchid2",    # Date
            "orchid2",        # Freunde
            "plum1",          # Ausgehen
            "tomato",         # Fotografie
            "pink",           # Beauty
            "white",          # Pendeln
            "black")          # Prokrastination

# read arguments
args <- commandArgs(trailingOnly=TRUE)
filename <- args[1]
print(filename)
detail_plot <- args[2]

# read data
ds <- read.table(filename, header=T, sep="\t")

# Set orders
ds <- within(ds, ActivityType <- factor(ActivityType, levels=order))

# compute range
today <- format(Sys.time(), "%Y-%m-%d")
end <- ymd(today) + (8 - wday(today)) %% 7
start <- ymd(end) - weeks * 7 + 1

# compute labels
breaks <- seq(yday(start), yday(end), 7)
labels <- seq(ymd(start), ymd(end), 7)
labels <- sprintf("%s.%s.", day(labels), month(labels))

# plot timelog
p <- ggplot(ds, aes(xmin=60*hour(Start)+minute(Start), 
                    xmax=60*hour(End)+minute(End), 
                    ymin=yday(Start)-0.5,
                    ymax=yday(Start)+0.5,
                    fill=ActivityType)) 
p <- p + geom_rect(color="#808080", size=0.1)
p <- p + scale_x_continuous(expand=c(0, 0), limit=c(0, 1440), breaks=seq(0, 1440, 60), labels=seq(0, 24, 1))
p <- p + scale_y_reverse(expand=c(0, 0), limit=c(yday(end) + 0.5, yday(start) - 0.5), breaks=breaks, labels=labels)
p <- p + scale_fill_manual("", values=colors)
p <- p + theme_bw()
p <- p + theme(panel.grid.major.y = element_blank(),
               panel.grid.minor.x = element_blank(), 
               panel.grid.minor.y = element_blank())
ggsave(detail_plot, width=14.5, height=8)
