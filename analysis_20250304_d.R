# RSC analysis

# Isabell Landwehr
# 04-03-2025

# RQ1: Are more complex noun phrases (NPs) more likely to be post-modified than pre-modified?
# RQ1a: Does a noun phrase's number of dependents correlate with its likelihood of post-modification? 

# differences to analysis c:
# - new data from improved script
# - considering only nsubj, obj and obl as syntactic roles
# - testing interactions

# frequentist analysis


#### FIRST STEPS ####

# libraries
library(car)
library(DHARMa)
library(dplyr)
library(ggeffects)
library(ggplot2)
library(glmmTMB)
library(performance)
library(sjPlot)

# open data file
data <- read.table(file="./data/noun_data_b1_v3.csv",
                   sep=",",
                   header=TRUE,
                   quote='"',
                   fill=TRUE)
head(data)

# filter and preprocess data:
# consider only NPs with modifiers
data_filtered <- data %>%
  filter(data$pre_mod_num != 0 | data$post_mod_num != 0)

# column for modification type 1
# three levels: pre-modification, post-modification, both
data_filtered <- data_filtered %>%  mutate(mod_type = case_when(
  pre_mod_num != 0  & post_mod_num == 0 ~ "pre_mod",
  pre_mod_num == 0  & post_mod_num != 0 ~ "post_mod",
  pre_mod_num != 0  & post_mod_num != 0 ~ "pre_post_mod"
))
# column for modification type 2
# two levels: pre-modification, post-modification
data_filtered <- data_filtered %>%  mutate(mod_type_2 = case_when(
  pre_mod_num != 0  & post_mod_num == 0 ~ "pre_mod",
  pre_mod_num == 0  & post_mod_num != 0 ~ "post_mod"
))
# create numeric response (0=post, 1=pre)
data_filtered <- data_filtered %>%  mutate(mod_type_2_num = case_when(
  mod_type_2 == "post_mod" ~ 0,
  mod_type_2 == "pre_mod" ~ 1
))

# get length of head noun
data_filtered$noun_len <- nchar(data_filtered$noun)

# remove outliers
# remove observations with dependency number > 20
data_filtered <- data_filtered %>%
  filter(data_filtered$dep_num <= 20)
# remove observations with dependency length > 25
data_filtered <- data_filtered %>%
  filter(data_filtered$dep_len <= 25)
# remove observations with noun length > 20
data_filtered <- data_filtered %>%
  filter(data_filtered$noun_len <= 20)

# consider only selected syntactic roles
data_filtered <- data_filtered %>%
  filter(deprel %in% c("nsubj", "nsubj:outer", "nsubj:pass", "obj",
                       "obl", "obl:agent", "obl:npmod", "obl:tmod"))
# summarize syntactic roles which are sub-categories
data_filtered <- data_filtered %>%
  mutate(deprel = case_when(deprel == "nsubj:outer" ~ "nsubj",
                            deprel == "nsubj:pass" ~ "nsubj",
                            deprel == "obl:agent" ~ "obl",
                            deprel == "obl:npmod" ~ "obl",
                            deprel == "obl:tmod" ~ "obl",
                            TRUE ~ deprel))
levels(as.factor(data_filtered$deprel))

# consider only selected text types
data_filtered <- data_filtered %>%
  mutate(text_type = tolower(text_type)) %>% # convert to lower case
  filter(text_type %in% c("article"))

# get subset with either only pre- or only post-modification
data_PrePost <- data_filtered %>%
  filter(!is.na(data_filtered$mod_type_2_num))

# stratified sampling: sample while keeping proportions of data per year
set.seed(24)
data_sampled <- data_PrePost %>%
  group_by(year) %>%  # stratify by year
  sample_frac(0.02) %>%  # take 0.02 % from each category
  ungroup()

# center year variable
data_sampled$year_cent <- scale(as.numeric(data_sampled$year), center=T, scale=F)
# center and scale other continuous variables
data_sampled$dep_num_sc <- scale(as.numeric(data_sampled$dep_num), center=T, scale=T)
data_sampled$dep_len_sc <- scale(as.numeric(data_sampled$dep_len), center=T, scale=T)
data_sampled$noun_len_sc <- scale(as.numeric(data_sampled$noun_len), center=T, scale=T)
data_sampled$sent_len_sc <- scale(as.numeric(data_sampled$sent_len), center=T, scale=T)

# create factors
data_sampled$mod_type_2_F <- as.factor(data_sampled$mod_type_2) 
data_sampled$deprel_F <- as.factor(data_sampled$deprel)
data_sampled$det_F <- as.factor(data_sampled$det_def)
data_sampled$author_F <- as.factor(data_sampled$author)
data_sampled$noun_F <- as.factor(data_sampled$noun)
# show factor levels
levels(data_sampled$mod_type_2_F)
levels(data_sampled$deprel_F)
levels(data_sampled$det_F)

# contrast coding
contrasts(data_sampled$mod_type_2_F) = contr.treatment(2, base=1) # baseline: post-mod (0)
contrasts(data_sampled$deprel_F) = contr.treatment(3, base=1) # baseline: nsubj
contrasts(data_sampled$det_F) = contr.treatment(2, base=1) # baseline: False (no definite determiner)

# check data
colSums(is.na(data_sampled)) # check for NAs
str(data_sampled)

#### EXPLORATION ####

# plot different outcomes for modification type
ggplot2::ggplot(data_filtered, aes(x = mod_type)) +
  geom_bar(fill = "steelblue") +
  labs(title = "Outcomes for Modification Type",
       x = "Modification Type", y = "Count") +
  theme_minimal()

# relationship between modification type and dependency number
ggplot2::ggplot(data_filtered, aes(x = mod_type, y = dep_num, fill = mod_type)) +
  geom_boxplot() +
  labs(title = "Dependency Number by Modification Type",
       x = "Modification Type", y = "Dependency Number") +
  theme_minimal()

# relationship between modification type and dependency length
ggplot2::ggplot(data_filtered, aes(x = mod_type, y = dep_len, fill = mod_type)) +
  geom_boxplot() +
  labs(title = "Dependency Number by Modification Type",
       x = "Modification Type", y = "Dependency Length") +
  theme_minimal()

# relationship between modification type and noun length
ggplot2::ggplot(data_filtered, aes(x = mod_type, y = noun_len, fill = mod_type)) +
  geom_boxplot() +
  labs(title = "Dependency Number by Modification Type",
       x = "Modification Type", y = "Noun Length") +
  theme_minimal()

# relationship between modification type and definite determiner
ggplot2::ggplot(data_filtered, aes(x = mod_type, y = det_def, fill = mod_type)) +
  geom_boxplot() +
  labs(title = "Dependency Number by Modification Type",
       x = "Modification Type", y = "Text Type") +
  theme_minimal()

# group-level variability: head noun
ggplot2::ggplot(data_filtered, aes(x = factor(noun), y = dep_num)) +
  geom_boxplot() +
  labs(title = "Dependency Number Distribution by Head Noun",
       x = "Head Noun", y = "Dependency Number") +
  theme_minimal()

# dependency number distribution within groups
ggplot2::ggplot(data_filtered, aes(x = dep_num, fill = mod_type)) +
  geom_histogram(bins = 15, alpha = 0.6) +
  facet_wrap(~group) +
  theme_minimal()

# plot modification type
ggplot2::ggplot(data_sampled,
                aes(x=mod_type_2_F)) + 
  labs(x = "Modification Type", y = "Num. of Observations") +
  scale_x_discrete(labels = c("postmodification", "premodification")) +
  geom_bar()

# plot dependency role
ggplot2::ggplot(data_sampled,
                aes(x=deprel_F)) + 
  labs(x = "Syntactic Role", y = "Num. of Observations") +
  geom_bar()

# plot definite determiner
ggplot2::ggplot(data_sampled,
                aes(x=det_F)) +
  labs(x = "Has Definite Determiner", y = "Num. of Observations") +
  geom_bar()

# plot journal
ggplot2::ggplot(data_sampled,
                aes(x=journal)) + 
  labs(x = "Journal", y = "Num. of Observations") +
  geom_bar()

# plot time
ggplot2::ggplot(data_sampled,
                aes(x=year)) + 
  labs(x = "Year", y = "Num. of Observations") +
  geom_bar()

# unique values of variables
summary_modType <- data_sampled %>%
  group_by(mod_type_2_num) %>%
  summarise(count_modType = n())
summary_journal <- data_sampled %>%
  group_by(journal) %>%
  summarise(count_journal = n())
summary_deprel <- data_sampled %>%
  group_by(deprel) %>%
  summarise(count_deprel = n())
summary_det <- data_sampled %>%
  group_by(det_def) %>%
  summarise(count_det = n())

# plot modifier type
data_modType <- data.frame(
  data_sampled$relcl_f_num,
  data_sampled$relcl_nf_num,
  data_sampled$nmod_num,
  data_sampled$compound_num,
  data_sampled$adj_num,
  data_sampled$adv_num
)
feature_sums <- colSums(data_modType) # sum each column
# convert to data frame for ggplot
data_modType_sums <- data.frame(
  Modification_Type = names(feature_sums),
  Count = as.numeric(feature_sums)
)
# plot
ggplot2::ggplot(data_modType_sums, aes(x = Modification_Type,
                                       y = Count)) +
  geom_bar(stat = "identity") +
  labs(title = "",
       x = "Modifier Type",
       y = "Num. of Observations") +
  scale_x_discrete(labels = c("adj", "adv", "compound",
                              "nmod", "finite relcl", "non-finite relcl"))


#### REGRESSION MODELS ####

# dependent variable: modification type
# predictor: dependency number
# control variables: time, syntactic role of NP,
#                    dependency length for head noun, length of head noun
#                    presence of definite determiner
# random effects: author, head noun, journal


# simple model
m0_tmb <- glmmTMB::glmmTMB(mod_type_2_num ~ year_cent
                           + dep_num_sc
                           + dep_len_sc
                           + noun_len_sc
                           + deprel_F
                           + det_F
                           + (1 | noun),  
                           data = data_sampled, 
                           family = binomial())
# model diagnostics
# random effects variance
VarCorr(m0_tmb)
AIC(m0_tmb) # 17809
# check residuals
sim_m0_tmb <- DHARMa::simulateResiduals(m0_tmb)
DHARMa::plotQQunif(sim_m0_tmb) # create qq-plot
DHARMa::plotResiduals(sim_m0_tmb) # plot residuals against expected value
DHARMa::plotResiduals(sim_m0_tmb, form = data_sampled$mod_type_2_num) # plot residuals against predictor

# model with interaction
m1_tmb <- glmmTMB::glmmTMB(mod_type_2_num ~ year_cent
                           + dep_num_sc * noun_len_sc
                           + dep_len_sc
                           + deprel_F
                           + det_F
                           + (1 | noun),  
                           data = data_sampled, 
                           family = binomial())
# model diagnostics
# random effects variance
VarCorr(m1_tmb)
AIC(m1_tmb) # 17809.56
# check residuals
sim_m1_tmb <- DHARMa::simulateResiduals(m1_tmb)
DHARMa::plotQQunif(sim_m1_tmb) # create qq-plot
DHARMa::plotResiduals(sim_m1_tmb) # plot residuals against expected value
DHARMa::plotResiduals(sim_m1_tmb, form = data_sampled$mod_type_2_num) # plot residuals against predictor

# model with additional variable sentence length
m0a_tmb <- glmmTMB::glmmTMB(mod_type_2_num ~ year_cent
                            + dep_num_sc
                            + dep_len_sc
                            + noun_len_sc
                            + deprel_F
                            + det_F
                            + sent_len_sc
                            + (1 | noun),  
                            data = data_sampled, 
                            family = binomial())
# model diagnostics
# random effects variance
VarCorr(m0a_tmb)
AIC(m0a_tmb) # 17766.34
# check residuals
sim_m0a_tmb <- DHARMa::simulateResiduals(m0a_tmb)
DHARMa::plotQQunif(sim_m0a_tmb) # create qq-plot
DHARMa::plotResiduals(sim_m0a_tmb) # plot residuals against expected value
DHARMa::plotResiduals(sim_m0a_tmb, form = data_sampled$mod_type_2_num) # plot residuals against predictor

# model with more random effects
m0b_tmb <- glmmTMB::glmmTMB(mod_type_2_num ~ year_cent
                            + dep_num_sc
                            + dep_len_sc
                            + noun_len_sc
                            + deprel_F 
                            + det_F
                            + sent_len_sc
                            + (1 | author)
                            + (1 | noun),  
                            data = data_sampled, 
                            family = binomial())
# model diagnostics
# random effects variance
VarCorr(m0b_tmb)
AIC(m0b_tmb) # 17761.11
# check residuals
sim_m0b_tmb <- DHARMa::simulateResiduals(m0b_tmb)
DHARMa::plotQQunif(sim_m0b_tmb) # create qq-plot
DHARMa::plotResiduals(sim_m0b_tmb) # plot residuals against expected value
DHARMa::plotResiduals(sim_m0b_tmb, form = data_sampled$mod_type_2_num) # plot residuals against predictor

m0c_tmb <- glmmTMB::glmmTMB(mod_type_2_num ~ year_cent
                            + dep_num_sc
                            + dep_len_sc
                            + noun_len_sc
                            + deprel_F 
                            + det_F
                            + sent_len_sc
                            + (1 | journal)
                            + (1 | author)
                            + (1 | noun),  
                            data = data_sampled, 
                            family = binomial())
# model diagnostics
# random effects variance
VarCorr(m0c_tmb)
AIC(m0c_tmb) # 17759.8
# check residuals
sim_m0c_tmb <- DHARMa::simulateResiduals(m0c_tmb)
DHARMa::plotQQunif(sim_m0c_tmb) # create qq-plot
DHARMa::plotResiduals(sim_m0c_tmb) # plot residuals against expected value
DHARMa::plotResiduals(sim_m0c_tmb, form = data_sampled$mod_type_2_num) # plot residuals against predictor

m0d_tmb <- glmmTMB::glmmTMB(mod_type_2_num ~ year_cent
                            + dep_num_sc
                            + dep_len_sc
                            + noun_len_sc
                            + deprel_F 
                            + det_F
                            + sent_len_sc
                            + (1 | author)
                            + (1 | journal)
                            + (1 + dep_num_sc | noun),  
                            data = data_sampled, 
                            family = binomial())
# model diagnostics
# random effects variance
VarCorr(m0d_tmb)
AIC(m0d_tmb) # 17699.46
# check residuals
sim_m0d_tmb <- DHARMa::simulateResiduals(m0d_tmb)
DHARMa::plotQQunif(sim_m0d_tmb) # create qq-plot
DHARMa::plotResiduals(sim_m0d_tmb) # plot residuals against expected value
DHARMa::plotResiduals(sim_m0d_tmb, form = data_sampled$mod_type_2_num) # plot residuals against predictor

# model summary
summary(m0d_tmb)
output <- capture.output(summary(m0d_tmb))
cat("model_summary_m0d_tmb", output, file="./results/20250304_d/20250304d_summary_m0d_tmb.txt", sep="\n", append=TRUE)

m0e_tmb <- glmmTMB::glmmTMB(mod_type_2_num ~ year_cent
                            + dep_num_sc
                            + dep_len_sc
                            + noun_len_sc
                            + deprel_F
                            + det_F
                            + sent_len_sc
                            + (1 | author)
                            + (1 | journal)
                            + (1 + noun_len_sc | noun),  
                            data = data_sampled, 
                            family = binomial())
# model diagnostics
# random effects variance
VarCorr(m0e_tmb)
AIC(m0e_tmb) # 17734.56
# check residuals
sim_m0e_tmb <- DHARMa::simulateResiduals(m0e_tmb)
DHARMa::plotQQunif(sim_m0e_tmb) # create qq-plot
DHARMa::plotResiduals(sim_m0e_tmb) # plot residuals against expected value
DHARMa::plotResiduals(sim_m0e_tmb, form = data_sampled$mod_type_2_num) # plot residuals against predictor

# test interaction dep num * deprel
m0f_tmb <- glmmTMB::glmmTMB(mod_type_2_num ~ year_cent
                            + dep_num_sc * deprel_F
                            + dep_len_sc
                            + noun_len_sc
                            + det_F
                            + sent_len_sc
                            + (1 | author)
                            + (1 | journal)
                            + (1 + noun_len_sc | noun),  
                            data = data_sampled, 
                            family = binomial())
# model diagnostics
# random effects variance
VarCorr(m0f_tmb)
AIC(m0f_tmb) # 17737.94
# multicollinearity
performance::check_collinearity(m0f_tmb)
# check residuals
sim_m0f_tmb <- DHARMa::simulateResiduals(m0f_tmb)
DHARMa::plotQQunif(sim_m0f_tmb) # create qq-plot
DHARMa::plotResiduals(sim_m0f_tmb) # plot residuals against expected value
DHARMa::plotResiduals(sim_m0f_tmb, form = data_sampled$mod_type_2_num) # plot residuals against predictor
# model summary
summary(m0f_tmb)
output <- capture.output(summary(m0f_tmb))
cat("model_summary_m0f_tmb", output, file="./results/20250304_d/20250304d_summary_m0f_tmb.txt", sep="\n", append=TRUE)

# test interaction dep len * deprel: convergence issue
m0g_tmb <- glmmTMB::glmmTMB(mod_type_2_num ~ year_cent
                            + dep_num_sc 
                            + dep_len_sc * deprel_F
                            + noun_len_sc
                            + det_F
                            + sent_len_sc
                            + (1 | author)
                            + (1 | journal)
                            + (1 + noun_len_sc | noun),  
                            data = data_sampled, 
                            family = binomial(),
                            control = glmmTMBControl(optimizer = optim,
                                                     optArgs = list(method = "Nelder-Mead")))
# model diagnostics
# random effects variance
VarCorr(m0g_tmb)
AIC(m0g_tmb) # 
# check residuals
sim_m0f_tmb <- DHARMa::simulateResiduals(m0g_tmb)
DHARMa::plotQQunif(sim_m0g_tmb) # create qq-plot
DHARMa::plotResiduals(sim_m0g_tmb) # plot residuals against expected value
DHARMa::plotResiduals(sim_m0g_tmb, form = data_sampled$mod_type_2_num) # plot residuals against predictor

# test three-way interaction: convergence issue


#### VISUALIZATION ####

# effects for non-interaction model
# plot effect of time
ggeffects::ggeffect(m0d_tmb, c("year_cent")) %>%
  plot() +
  labs(x = "Time",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of dependency number
ggeffects::ggeffect(m0d_tmb, c("dep_num_sc")) %>%
  plot() +
  labs(x = "Number of Dependencies",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of dependency length
ggeffects::ggeffect(m0d_tmb, c("dep_len_sc")) %>%
  plot() +
  labs(x = "Distance to Head",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of noun length
ggeffects::ggeffect(m0d_tmb, c("noun_len_sc")) %>%
  plot() +
  labs(x = "Noun Length",
       y = "Likelihood of Premodification")
# plot effect of sentence length length
ggeffects::ggeffect(m0d_tmb, c("sent_len_sc")) %>%
  plot() +
  labs(x = "Sentence Length",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of dependency relation
ggeffects::ggeffect(m0d_tmb, c("deprel_F")) %>%
  plot() +
  labs(x = "Syntactic Role",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of determiner
ggeffects::ggeffect(m0d_tmb, c("det_F")) %>%
  plot() +
  labs(x = "Has Definite Determiner",
       y = "Likelihood of Premodification",
       title = "")

# effects for interaction model
# plot effect of time
ggeffects::ggeffect(m0f_tmb, c("year_cent")) %>%
  plot() +
  labs(x = "Time",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of dependency number
ggeffects::ggeffect(m0f_tmb, c("dep_num_sc")) %>%
  plot() +
  labs(x = "Number of Dependencies",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of dependency length
ggeffects::ggeffect(m0f_tmb, c("dep_len_sc")) %>%
  plot() +
  labs(x = "Distance to Head",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of noun length
ggeffects::ggeffect(m0f_tmb, c("noun_len_sc")) %>%
  plot() +
  labs(x = "Noun Length",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of sentence length length
ggeffects::ggeffect(m0f_tmb, c("sent_len_sc")) %>%
  plot() +
  labs(x = "Sentence Length",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of dependency relation
ggeffects::ggeffect(m0f_tmb, c("deprel_F")) %>%
  plot() +
  labs(x = "Syntactic Role",
       y = "Likelihood of Premodification",
       title = "")
# plot effect of determiner
ggeffects::ggeffect(m0f_tmb, c("det_F")) %>%
  plot() +
  labs(x = "Has Definite Determiner",
       y = "Likelihood of Premodification",
       title = "")
