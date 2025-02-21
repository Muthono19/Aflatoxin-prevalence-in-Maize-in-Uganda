library(dotwhisker)
library(broom.mixed)
library(ggplot2)
library(dplyr) 
library(lme4)
library(glmmTMB)
library(car)
library(ggeffects)

# Load the Uganda database
d.uganda <- read.csv("Uganda_MaizeAfla_Raw.csv")
d.uganda <- d.uganda %>% mutate(across(where(is.character), as.factor))
str(d.uganda)

#### GLMM model
mod.uganda <- glmmTMB(Aflatoxin ~ Altitude * Treatment + Season + (1|Region/District),
                      family = tweedie(link = "log"), 
                      data = d.uganda,
                      control = glmmTMBControl(optimizer = optim, optArgs = list(method = "BFGS")))

summary(mod.uganda)
Anova(mod.uganda) # significant: Treatment and season

# Make predictions based on the significant factors
preds <- ggemmeans(mod.uganda, terms = c("Treatment", "Season"))

# Save as png to visualize
png(file="PredictedMaizeAffla_UG.png", width = 6500, height =4000, units = "px", res = 800, type = "cairo")
ggplot(preds, aes(x = group, y = predicted, color = x, group = x)) +
  geom_point(size = 3) +
  geom_line(size = 1) +
  geom_errorbar(aes(ymin = conf.low, ymax = conf.high), width = 0.2) +
  theme_minimal() +
  labs(title = "",y = "Predicted Aflatoxin", x = "Season") +
  theme(legend.position = "top")
dev.off()

# Extract random effects and convert to data frame
re_df <- tidy(mod.uganda, effects = "ran_vals")

# Order from highest to lowest estimate
re_df <- re_df %>%
  select(-term) %>%  # Remove the old 'term' column
  rename(term = level) %>%  # Rename 'level' to 'term'
  arrange(desc(estimate))  # Sort in descending order

re_df <- re_df %>%
  mutate(term = reorder(term, estimate)) 

# Convert to a standard ggplot to control aesthetics better
png(file="DistrictEffect_UG.png", width = 6500, height =8000, units = "px", res = 800, type = "cairo")
ggplot(re_df, aes(x = estimate, y = term, color = estimate)) +
  geom_point(size = 3, shape=17) +  # Adjust dot size
  geom_errorbarh(aes(xmin = estimate - std.error, xmax = estimate + std.error), height = 0.2, size = 1) +  
  scale_color_gradientn(colors = c("green", "yellow", "red")) +  # Gradient from red to yellow to green
  theme_minimal() +
  labs(title = "Random Effects Visualization", x = "Estimate", y = "Groups", color = "Estimate")
dev.off()

#---------------------- THE END   ---------------------------------------------#



