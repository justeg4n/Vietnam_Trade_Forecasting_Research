#Dự đoán 1 data
library(prophet)
library(ggplot2)
library(readr)
library(dplyr)
library(tidyr)
library(scales)

#️ĐỌC DỮ LIỆU
data_raw <- read_csv("D:\\Download\\Data for subject\\DSR_cleaned\\Im05_2022_2024_merged_summary.csv")
#LỌC DỮ LIỆU THEO YÊU CẦU
data_eu <- data_raw %>%
  filter(
    Names == "Ukraine",
    Group == "Summary"       # chỉ lấy dòng tổng hợp
  )

#CHUYỂN WIDE → LONG (gom tháng)
data_eu_long <- data_eu %>%
  pivot_longer(
    cols = ends_with("_Value"),
    names_to = "Month",
    values_to = "y"
  ) %>%
  mutate(
    Month = sub("_Value", "", Month),
    month_num = match(Month, month.name),
    ds = as.Date(paste0(Year, "-", month_num, "-01"), format = "%Y-%m-%d")
  ) %>%
  group_by(ds) %>%
  summarise(y = sum(y, na.rm = TRUE)) %>%
  arrange(ds) %>%
  filter(!is.na(ds) & !is.na(y))

#TẠO MÔ HÌNH PROPHET
model_prophet <- prophet(
  growth = "linear",
  yearly.seasonality = TRUE,
  weekly.seasonality = FALSE,
  daily.seasonality = FALSE,
  changepoint.prior.scale = 0.5,
  interval.width = 0.95
)

model_prophet <- fit.prophet(model_prophet, data_eu_long)

#DỰ BÁO 12 THÁNG TIẾP THEO
future <- make_future_dataframe(model_prophet, periods = 12, freq = "month")
forecast <- predict(model_prophet, future)

#VẼ BIỂU ĐỒ DỰ BÁO
name <- unique(data_eu$Names)

plot(model_prophet, forecast) +
  ggtitle(paste("Prophet Forecast –", name, "Import (Next 12 Months)")) +
  xlab("Năm") + 
  ylab("Giá trị xuất khẩu (VND)") +
  theme_minimal(base_size = 13) +
  scale_y_continuous(labels = comma)

#HIỂN THỊ THÀNH PHẦN (xu hướng + mùa vụ)

prophet_plot_components(model_prophet, forecast)

#XEM DỰ BÁO CỤ THỂ
forecast %>%
  select(ds, yhat, yhat_lower, yhat_upper) %>%
  tail(12)



############################################################


#Dự đoán 2 data
library(tidyverse)
library(prophet)
library(scales)
library(lubridate)

#ĐỌC DỮ LIỆU GỐC
data_raw <- read_csv("D:\\Download\\Data for subject\\DSR_cleaned\\Im05_2022_2024_merged_summary.csv")
data_2025 <- read_csv("D:\\Download\\Data for subject\\DSR_cleaned\\Im05-2025-6_clean.csv")

#CHỌN TÊN KHU VỰC 
target_name <- "Ukraine"  

#DỮ LIỆU THỰC TẾ NĂM 2025
actual_df <- data_2025 %>%
  filter(Names == target_name, is.na(Group)) %>%
  pivot_longer(
    cols = ends_with("_Value"),
    names_to = "Month",
    values_to = "actual"
  ) %>%
  mutate(
    Month = str_replace(Month, "_Value", ""),
    Month = str_to_title(Month),
    month_num = match(Month, month.name),
    ds = as.Date(paste(2025, month_num, "01", sep = "-"), format = "%Y-%m-%d")
  ) %>%
  select(ds, actual) %>%
  arrange(ds)

#DỮ LIỆU TRAIN PROPHET (2022–2024)
train_df <- data_raw %>%
  filter(Names == target_name, Group == "Summary", Year >= 2022 & Year <= 2024) %>%
  pivot_longer(
    cols = ends_with("_Value"),
    names_to = "Month",
    values_to = "y"
  ) %>%
  mutate(
    Month = str_replace(Month, "_Value", ""),
    Month = str_to_title(Month),
    month_num = match(Month, month.name),
    ds = as.Date(paste0(Year, "-", month_num, "-01"), format = "%Y-%m-%d")
  ) %>%
  group_by(ds) %>%
  summarise(y = sum(y, na.rm = TRUE)) %>%
  arrange(ds) %>%
  filter(!is.na(ds) & !is.na(y))

#FIT PROPHET MODEL
m <- prophet(
  growth = "linear",
  yearly.seasonality = TRUE,
  weekly.seasonality = FALSE,
  daily.seasonality = FALSE,
  changepoint.prior.scale = 0.5,
  interval.width = 0.95
)

m <- fit.prophet(m, train_df)

#DỰ BÁO 12 THÁNG TIẾP THEO
future <- make_future_dataframe(m, periods = 12, freq = "month")
forecast <- predict(m, future)

#GHÉP DỮ LIỆU DỰ BÁO & THỰC TẾ
compare_df <- forecast %>%
  select(ds, yhat, yhat_lower, yhat_upper) %>%
  left_join(actual_df, by = "ds") %>%
  filter(year(ds) == 2025)

#BIỂU ĐỒ SO SÁNH DỰ BÁO – THỰC TẾ
ggplot(compare_df, aes(x = ds)) +
  geom_ribbon(aes(ymin = yhat_lower, ymax = yhat_upper),
              fill = "lightblue", alpha = 0.4) +
  geom_line(aes(y = yhat, color = "Dự báo Prophet"), size = 1.2) +
  geom_point(aes(y = actual, color = "Thực tế"), size = 2.5) +
  geom_line(aes(y = actual, color = "Thực tế"), linetype = "dashed", size = 1.1) +
  geom_text(aes(y = actual, label = comma(round(actual, 0))),
            vjust = -0.8, size = 3) +
  scale_color_manual(values = c("Dự báo Prophet" = "blue", "Thực tế" = "red")) +
  labs(
    title = paste("So sánh Dự báo Prophet và Dữ liệu Thực tế –", target_name, "(2025)"),
    x = "Tháng",
    y = "Giá trị xuất khẩu (VND)",
    color = ""
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "top")

#ĐÁNH GIÁ MỨC ĐỘ CHÍNH XÁC

compare_df <- compare_df %>% drop_na(actual)

mape <- mean(abs((compare_df$actual - compare_df$yhat) / compare_df$actual)) * 100
rmse <- sqrt(mean((compare_df$actual - compare_df$yhat)^2))

cat("Kết quả cho khu vực:", target_name, "\n")
cat("MAPE:", round(mape, 2), "%\n")
cat("RMSE:", round(rmse, 2), "\n")

