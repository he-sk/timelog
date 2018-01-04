library(ggplot2)
library(plyr)
library(lubridate)

# Weeks start on Monday
options(lubridate.week.start = 1)

# Number of weeks
weeks <- 4

# Order of categories
order <- c("Schlafen", "Morgen/Abend",
           "Essen",
           "Arbeit", "Pause",
           "Review", "Erledigung", "Projekt",
           "Familie", "Date", "Ausgehen", "Freunde",
           "Fotografie", "Lesen", "Sport", "Ausruhen", "Spazieren", "Beauty",
           "Pendeln", "Prokrastination")

# Colors
# http://sape.inf.usi.ch/sites/default/files/ggplot2-colour-names.png
colors <- c("steelblue1",     # Schlafen
            "lightskyblue",   # Morgens/Abends
            "steelblue4",     # Essen
            "gold",           # Arbeit
            "goldenrod3",     # Pause
            "darkseagreen4",  # Review
            "darkseagreen3",  # Erledigung
            "darkseagreen1",  # Projekt
            "darkorchid4",    # Familie
            "darkorchid2",    # Date
            "orchid2",        # Ausgehen
            "plum1",          # Freunde
            "tomato",         # Fotografie
            "coral",          # Lesen
	    "lightsalmon",    # Sport
	    "peachpuff",      # Ausruhen
            "seashell",       # Reisen
            "pink",           # Beauty
            "white",          # Pendeln
            "black")          # Prokrastination

# read arguments
args <- commandArgs(trailingOnly=TRUE)
filename <- args[1]
detail_plot <- args[2]
summary_plot <- args[3]
weekly_plot <- args[4]

# read data
ds <- read.table(filename, header=T, sep="\t")

# set order of activities
ds <- within(ds, ActivityType <- factor(ActivityType, levels=order))

# compute durations
ds$Date <- sprintf("%4d-%02d-%02d", year(ds$Start), month(ds$Start), day(ds$Start))
ds$Weekday <- wday(ds$Start)
ds$Week <- isoweek(ds$Start)
ds$WeekLabel <- sprintf("%s (%d)", ymd(ds$Date) - wday(ds$Date) + 1, isoweek(ds$Date))
ds$Duration <- interval(ds$Start, ds$End) %/% minutes(1)

# compute range
today <- format(Sys.time(), "%Y-%m-%d")
end <- ymd(today) + (7 - wday(today))
start <- ymd(end) - weeks * 7 + 1

plot_daily_detail <- function(ds) {

  # restrict
  ds <- subset(ds, Date >= start)

  # compute labels
  labels <- seq(ymd(start), ymd(end), 7)
  labels <- sprintf("%s.%s.", day(labels), month(labels))
  
  ds$Index <- as.numeric(ymd(ds$Date) - start)
  breaks <- seq(0, (weeks - 1) * 7, 7)

  # compute colors
  used_colors <- data.frame(ActivityType=order, Color=colors)
  used_colors <- subset(used_colors, ActivityType %in% ds$ActivityType, select=c("Color"))
  used_colors <- as.character(used_colors$Color)

  # plot timelog
  p <- ggplot(ds, aes(xmin=60*hour(Start)+minute(Start), 
                      xmax=60*hour(End)+minute(End), 
                      ymin=Index-0.5,
                      ymax=Index+0.5,
                      fill=ActivityType)) 
  p <- p + geom_rect(color="#808080", size=0.1)
  p <- p + scale_x_continuous(expand=c(0, 0), limit=c(0, 1440), breaks=seq(0, 1440, 60), labels=seq(0, 24, 1))
  p <- p + scale_y_reverse(expand=c(0, 0), limit=c(27+0.5, 0-0.5), breaks=breaks, labels=labels)
  p <- p + scale_fill_manual("", values=used_colors)
  p <- p + theme_bw()
  p <- p + theme(panel.grid.major.y = element_blank(),
                 panel.grid.minor.x = element_blank(), 
                 panel.grid.minor.y = element_blank())
  ggsave(detail_plot, width=14.5, height=8)
}

plot_daily_summary <- function(ds) {
  # group by day
  ds <- ddply(ds, .(ActivityType, WeekLabel, Week, Weekday, Date), summarize, Duration=sum(Duration)/60)
  ds$Label <- ifelse(ds$Duration < 0.5, "", sprintf("%.0f:%02.0f", floor(ds$Duration), (ds$Duration - floor(ds$Duration)) * 60))
  
  # restrict to previous weeks
  ds <- subset(ds, Date >= start)
  
  # compute colors
  used_colors <- data.frame(ActivityType=order, Color=colors)
  used_colors <- subset(used_colors, ActivityType %in% ds$ActivityType, select=c("Color"))
  used_colors <- as.character(used_colors$Color)
  
  # plot timelog
  p <- ggplot(ds, aes(x=Weekday, y=Duration, fill=ActivityType)) 
  p <- p + facet_wrap(~ WeekLabel, nrow=1)
  p <- p + geom_bar(stat="identity", color="black", size=0.1, width=0.9)
  p <- p + geom_text(aes(label=Label), size = 3, position = position_stack(vjust = 0.5))
  p <- p + geom_text(data=subset(ds, ActivityType=="Prokrastination"), aes(label=Label), size = 3, position = position_stack(vjust = 0.5), color="white")
  p <- p + scale_x_continuous("", expand=c(0, 0), breaks=seq(1, 7, 1), labels=c("Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"))
  p <- p + scale_y_continuous("Hours", expand=c(0, 0), breaks=seq(0, 24, 6), limit=c(0, 24))
  p <- p + scale_fill_manual("", values=used_colors)
  p <- p + theme_bw()
  p <- p + theme(panel.grid.major.x = element_blank(),
                 panel.grid.minor.x = element_blank(),
                 panel.grid.minor.y = element_blank(),
                 panel.spacing = unit(2, "lines"))
  ggsave(summary_plot, width=14.5, height=8)
}

plot_weekly_summary <- function(ds) {

  # restrict to previous weeks
  ds <- subset(ds, Date >= end - weeks(26))

  # group by day
  ds <- ddply(ds, .(ActivityType, WeekLabel, Week), summarize, Duration=sum(Duration)/(60*7))
  ds$Label <- ifelse(ds$Duration < 0.5, "", sprintf("%.0f:%02.0f", floor(ds$Duration), (ds$Duration - floor(ds$Duration)) * 60))
  
  # compute colors
  used_colors <- data.frame(ActivityType=order, Color=colors)
  used_colors <- subset(used_colors, ActivityType %in% ds$ActivityType, select=c("Color"))
  used_colors <- as.character(used_colors$Color)
  
  # plot timelog
  p <- ggplot(ds, aes(x=WeekLabel, y=Duration, fill=ActivityType)) 
  p <- p + geom_bar(stat="identity", color="black", size=0.1, width=0.9)
  p <- p + geom_text(aes(label=Label), size = 3, position = position_stack(vjust = 0.5))
  p <- p + geom_text(data=subset(ds, ActivityType=="Prokrastination"), aes(label=Label), size = 3, position = position_stack(vjust = 0.5), color="white")
  p <- p + scale_x_discrete("Week", expand=c(0, 0), labels=unique(ds$Week))
  p <- p + scale_y_continuous("Hours", expand=c(0, 0), breaks=seq(0, 24, 6), limit=c(0, 24))
  p <- p + scale_fill_manual("", values=used_colors)
  p <- p + theme_bw()
  p <- p + theme(panel.grid.major.x = element_blank(),
                 panel.grid.minor.x = element_blank(),
                 panel.grid.minor.y = element_blank(),
                 panel.spacing = unit(2, "lines"))
  ggsave(weekly_plot, width=14.5, height=8)
}

plot_daily_detail(ds)
plot_daily_summary(ds)
plot_weekly_summary(ds)
