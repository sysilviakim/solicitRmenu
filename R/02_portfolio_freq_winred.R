categories <- "winred"
source(here::here("R", "01_data_import.R"))

# Wrote function: portfolio_summ ===============================================
temp <- df_ls[[categories]] %>%
  # To kick out duplicates
  mutate(url = gsub("\\?sc=winred-directory", "", url)) %>%
  mutate(name = gsub(" for Congress", "", name)) %>%
  mutate(
    race = ifelse(name == "Alison Hayden" & race == "CA-16", "CA-15", race),
    race = ifelse(name == "Liz Marty May" & race == "SD-1", "SD-AL", race),
    race = ifelse(name == "Matthew Morris" & race == "DE-NaN", "DE-AL", race),
    race = ifelse(name == "Scott Perry" & race == "PA-4", "PA-10", race),
    race = ifelse(name == "Vern Buchanan" & race == "FL-13", "FL-16", race)
  ) %>%
  # Changed jurisdiction but keep the record
  # filter(!(name == "Jimmy Rodriguez" & race == "AZ-8")) %>%
  filter(!is.na(url)) %>%
  portfolio_summ() %>%
  mutate(
    class = case_when(
      grepl("-", race) & !grepl("-SEN", race) ~ "us house",
      grepl("-SEN", race) ~ "us senate",
      grepl("Party", race) ~ "party",
      grepl("President", race) ~ "pres"
    )
  )

temp %>%
  .$class %>%
  table(useNA = "ifany")

head(sort(table(temp$amount), decreasing = TRUE), 10)

# Top 5 Most Frequent Distributions ============================================
p <- prop(temp, "amount", sort = TRUE, head = 5, print = FALSE) %>%
  unlist() %>%
  set_names(., nm = names(.)) %>%
  imap(~ tibble(label = .y, freq = as.numeric(.x))) %>%
  bind_rows() %>%
  mutate(
    label = gsub("-", "\n", label),
    label = factor(
      label,
      levels = gsub(
        "-", "\n",
        names(prop(temp, "amount", sort = TRUE, head = 5, print = FALSE))
      )
    )
  ) %>%
  ggplot(aes(x = label, y = freq)) +
  geom_bar(stat = "identity") +
  # xlab("\nSolicitation Amounts, Top 5, WinRed Directory") +
  xlab(NULL) + 
  ylab("Percentage (%)") +
  scale_y_continuous(limits = c(0, 50))

pdf(here("fig/portfolio_freq_top_5_winred.pdf"), width = 3.5, height = 3.5)
pdf_default(p)
dev.off()

# Save Output (Check for No-Prompt Referrals) ==================================
entities <- df_ls[[categories]] %>%
  select(!!c("name", "race")) %>%
  mutate(name = gsub(" for Congress", "", name)) %>%
  mutate(
    race = ifelse(name == "Alison Hayden" & race == "CA-16", "CA-15", race),
    race = ifelse(name == "Liz Marty May" & race == "SD-1", "SD-AL", race),
    race = ifelse(name == "Matthew Morris" & race == "DE-NaN", "DE-AL", race),
    race = ifelse(name == "Scott Perry" & race == "PA-4", "PA-10", race),
    race = ifelse(name == "Vern Buchanan" & race == "FL-13", "FL-16", race)
  ) %>%
  dedup()

View(anti_join(entities, temp))
nrow(full_join(temp, entities))

write_fst(
  full_join(temp, entities), here("data/tidy/portfolio_summ_winred.fst")
)