# drake file
# see https://github.com/aforren1/replan_finger/blob/master/README.md
# for what each column is
library(knitr)
library(rmarkdown)
library(data.table)
library(ggplot2)
library(drake)

slider <- function(x, y, window_size = 0.1) {
  out <- rep(NA, length(y))
  upper <- x + (window_size/2)
  lower <- x - (window_size/2)
  for (nn in seq(1, length(y))) {
    out[nn] <- mean(y[x <= upper[nn] & x >= lower[nn]], na.rm = TRUE)
  }
  out
}

raw_data <- function() {
  fread('extended_table.csv') # comes from matlab file write_extended_data.m
}

clean_data <- function(dat2) {
  dat <- copy(dat2)
  dat <- dat[real_prep_time > 0]
  dat <- dat[first_image != second_image]
  dat <- dat[!is.nan(first_press)]
  dat[, 'hand1' := ifelse(first_image > 5, 'right', 'left')]
  dat[, 'hand2' := ifelse(second_image > 5, 'right', 'left')]
  
  # can't think
  fings <- c('pinky', 'ring', 'middle', 'index', 'thumb')
  fingers <- data.frame(first_image = 1:10, finger1 = c(fings, rev(fings)))
  dat <- merge(dat, fingers, by = 'first_image', sort = FALSE)
  names(fingers) <- c('second_image', 'finger2')
  dat <- merge(dat, fingers, by = 'second_image', sort = FALSE)
  
  dat[, 'label' := ifelse(hand1 == hand2, 'same_hand',
                          ifelse(finger1 == finger2, 'homologous', 'heterologous'))]
  dat
}

slide_data <- function(dat2) {
  dat <- copy(dat2)
  # correctness
  dat[, 'slide_correct_id' := slider(real_prep_time, correct), by = c('label', 'id')]
  dat[, 'slide_correct_group' := slider(real_prep_time, correct), by = c('label')]
  # choice
  dat[, 'chose_old' := first_image == first_press]
  dat[, 'chose_new' := second_image == first_press]
  dat[, 'chose_null' := chose_old == chose_new] # chose neither old nor new (one of the other choices)
  dat[, 'hand_choice' := ifelse(first_press > 5, 'right', 'left')]
  dat[, 'chose_null_old_hand' := chose_null & (hand_choice == hand1)]
  dat[, 'chose_null_new_hand' := chose_null & !chose_null_old_hand]
  
  dat[, 'slide_old_group' := slider(real_prep_time, chose_old), by = c('label')]
  dat[, 'slide_new_group' := slider(real_prep_time, chose_new), by = c('label')]
  dat[, 'slide_null_group' := slider(real_prep_time, chose_null), by = c('label')]
  dat[, 'slide_null_old_hand_group' := slider(real_prep_time, chose_null_old_hand), by = c('label')]
  dat[, 'slide_null_new_hand_group' := slider(real_prep_time, chose_null_new_hand), by = c('label')]
  
  dat[, 'slide_old_id' := slider(real_prep_time, chose_old), by = c('label', 'id')]
  dat[, 'slide_new_id' := slider(real_prep_time, chose_new), by = c('label', 'id')]
  dat[, 'slide_null_id' := slider(real_prep_time, chose_null), by = c('label', 'id')]
  dat[, 'slide_null_old_hand_id' := slider(real_prep_time, chose_null_old_hand), by = c('label', 'id')]
  dat[, 'slide_null_new_hand_id' := slider(real_prep_time, chose_null_new_hand), by = c('label', 'id')]
  dat
}

my_knit <- function(file, ...) {
  knit(file)
}
my_render <- function(file, ...) {
  render(file)
}
myplan <- plan(
  dat = raw_data(),
  clean_dat = clean_data(dat),
  explore_dat = slide_data(clean_dat)
)

check(myplan)
make(myplan)
