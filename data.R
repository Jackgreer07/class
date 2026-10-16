url <- paste0(
  "https://api.open-meteo.com/v1/forecast",
  "?latitude=27.3364&longitude=-82.5307",
  "&hourly=temperature_2m,precipitation,relative_humidity_2m,wind_speed_10m",
  "&past_days=7&forecast_days=0&timezone=America%2FNew_York&format=csv"
)

download_path <- tempfile(fileext = ".csv")
utils::download.file(url, download_path, mode = "wb", quiet = TRUE)

weather <- utils::read.csv(download_path, skip = 2, check.names = FALSE)
if (nrow(weather) == 0) {
  stop("The weather API returned no hourly observations.")
}

utils::write.csv(weather, "sarasota-weather.csv", row.names = FALSE)
