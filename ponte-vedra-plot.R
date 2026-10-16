library(ggplot2)

weather <- read.csv("ponte-vedra-weather.csv", check.names = FALSE)
weather$time <- as.POSIXct(
  weather$time,
  format = "%Y-%m-%dT%H:%M",
  tz = "America/New_York"
)

weather_long <- rbind(
  data.frame(time = weather$time, measure = "Temperature (°C)", value = weather[["temperature_2m (°C)"]]),
  data.frame(time = weather$time, measure = "Precipitation (mm)", value = weather[["precipitation (mm)"]]),
  data.frame(time = weather$time, measure = "Humidity (%)", value = weather[["relative_humidity_2m (%)"]]),
  data.frame(time = weather$time, measure = "Wind speed (km/h)", value = weather[["wind_speed_10m (km/h)"]])
)
weather_long$measure <- factor(
  weather_long$measure,
  levels = c("Temperature (°C)", "Precipitation (mm)", "Humidity (%)", "Wind speed (km/h)")
)

weather_long$tooltip <- paste0(
  format(weather_long$time, "%b %d, %I %p"),
  "<br>",
  weather_long$measure,
  ": ",
  round(weather_long$value, 1)
)

daily_extremes <- do.call(
  rbind,
  lapply(split(weather_long, weather_long$measure), \(series) {
    days <- split(seq_len(nrow(series)), as.Date(series$time))
    do.call(rbind, lapply(days, \(indices) {
      day <- series[indices, , drop = FALSE]
      high <- which.max(day$value)
      low <- which.min(day$value)
      if (high == low) {
        extreme <- day[high, , drop = FALSE]
        extreme$label <- sprintf("%.1f", extreme$value)
        extreme$vjust <- 0.5
        extreme
      } else {
        extremes <- day[c(high, low), , drop = FALSE]
        extremes$label <- sprintf("%.1f", extremes$value)
        extremes$vjust <- c(-0.8, 1.4)
        extremes
      }
    }))
  })
)

weather_plot <- ggplot(
  weather_long,
  aes(x = time, y = value, color = measure, fill = measure, group = measure, text = tooltip)
) +
  geom_area(alpha = 0.18, show.legend = FALSE) +
  geom_line(linewidth = 0.55, show.legend = FALSE) +
  geom_text(
    data = daily_extremes,
    aes(x = time, y = value, label = label, color = measure, vjust = vjust),
    inherit.aes = FALSE,
    fontface = "bold",
    size = 2.7,
    show.legend = FALSE
  ) +
  facet_wrap(~measure, ncol = 2, scales = "free_y") +
  scale_color_manual(values = c("#4dd0e1", "#ffb74d", "#81c784", "#ba68c8")) +
  scale_fill_manual(values = c("#4dd0e1", "#ffb74d", "#81c784", "#ba68c8")) +
  labs(
    title = "Ponte Vedra, hour by hour",
    subtitle = "Weather over the past week",
    x = NULL,
    y = NULL,
    caption = "Source: Open-Meteo"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    plot.background = element_rect(fill = "#0b1220", color = NA),
    panel.background = element_rect(fill = "#0b1220", color = NA),
    panel.grid = element_line(color = "#263247"),
    strip.background = element_rect(fill = "#172338", color = NA),
    strip.text = element_text(color = "#e5eefb", face = "bold"),
    text = element_text(color = "#e5eefb"),
    axis.text = element_text(color = "#aebbd0"),
    plot.title = element_text(size = 20, face = "bold"),
    plot.subtitle = element_text(color = "#aebbd0"),
    plot.caption = element_text(color = "#7f8da3")
  )

ggsave("ponte-vedra-weather.png", plot = weather_plot, width = 12, height = 8, dpi = 300, bg = "#0b1220")

weather_interactive <- plotly::ggplotly(weather_plot, tooltip = "text")
htmlwidgets::saveWidget(
  weather_interactive,
  "ponte-vedra-weather.html",
  selfcontained = TRUE
)
