categories <- "actblue"
source(here::here("R", "01_scraped_data_import.R"))

assert_that(all(!is.na(df_raw$url)))
df_raw <- df_raw %>%
  group_by(url, year, date, portfolio) %>%
  # e.g., https://secure.actblue.com/donate/vtdems : same-date record
  # The Vermont Democratic Party & Donate to the Vermont Democratic Party
  # both exist
  slice(n())

temp <- df_raw %>%
  rename(name = fundraiser) %>%
  group_split(url, .keep = TRUE) %>%
  map_dfr(~ portfolio_summ(.x, exclude_cols = c("name", "year", "url")))

assert_that(all(temp$min <= temp$max))
write_fst(temp, here("data/tidy/actblue_portfolio_temp_names_included.fst"))

# Check for within-URL changes =================================================
temp %>%
  group_by(url, seq, amount) %>%
  filter(n() > 1) %>%
  arrange(url, seq) %>%
  View()

temp <- df_raw %>%
  select(-fundraiser) %>%
  group_split(url, .keep = TRUE) %>%
  map_dfr(~ portfolio_summ(.x, exclude_cols = c("year", "url")))
write_fst(temp, here("data/tidy/actblue_portfolio_temp_only_url.fst"))

head(sort(table(temp$amount), decreasing = TRUE), 10)

# Top 5 Most Frequent Distributions ============================================
pdf(here("fig/portfolio_freq_top_5_actblue.pdf"), width = 3, height = 3)
print(pdf_default(top5(temp, fill = "#0571B0")))
dev.off()

# Save Output (Check for No-Prompt Referrals) ==================================
temp <- left_join(
  read_fst(here("data/tidy/actblue_portfolio_temp_only_url.fst")),
  read_fst(here("data/tidy/actblue_portfolio_temp_names_included.fst")) %>%
    group_by(url, amount) %>%
    mutate(name_full = list(unique(name))) %>%
    slice(n()) %>%
    ungroup() %>%
    select(-min, -max, -seq) %>%
    dedup()
)
assert_that(
  temp %>%
    group_by(year, url, seq, min, max, amount) %>%
    filter(n() > 1) %>%
    nrow() %>%
    {. == 0}
)

save(
  temp,
  file = here("data/tidy/portfolio_summ_actblue_incomplete.Rda")
)
