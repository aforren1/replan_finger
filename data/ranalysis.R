# figure out error trials

library(data.table)
library(ggplot2)

window_size <- 0.1

slider <- function(x, y, window_size = 0.1) {
  out <- rep(NA, length(y))
  upper <- x + (window_size/2)
  lower <- x - (window_size/2)
  for (nn in seq(1, length(y))) {
    out[nn] <- mean(y[x <= upper[nn] & x >= lower[nn]], na.rm = TRUE)
  }
  out
}

#wd <- paste0(getwd(), '/007')
wd <- getwd()
filenames <- list.files(path = wd, pattern = '*.csv$', recursive = TRUE, full.names= TRUE)
# remove garbage files from contention
filenames <- filenames[!grepl(filenames, pattern = '/archive')]
filenames <- filenames[!grepl(filenames, pattern = 'test')]
filenames <- filenames[!grepl(filenames, pattern = 'demo')]
filenames <- filenames[!grepl(filenames, pattern = '000')]

# remove poorly sampled people (opinion piece)
# filenames <- filenames[!grepl(filenames, pattern = '001')]
# filenames <- filenames[!grepl(filenames, pattern = '006')]

dat <- lapply(filenames, fread, header = TRUE)
dat <- rbindlist(dat)

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

dat[, 'slide_correct' := slider(real_prep_time, correct, window_size), by = c('label')]

ggplot(dat, aes(x = real_prep_time,y = slide_correct, colour = label)) + 
  geom_line(size = 1.2) + 
  geom_point(aes(y = ifelse(correct, 1.1, -0.1)), pch = '|', size = 4) + 
  labs(x = 'Preparation Time', y = 'Prop(Correct)') + 
  scale_x_continuous(breaks = seq(0, 0.5, 0.1), 
                     minor_breaks = seq(0, 0.5, 0.05), limits = c(0, .5)) +
  scale_y_continuous(breaks = seq(0, 1, 0.2)) + facet_wrap(~id)

## see P(choice|RT)
dat[, 'chose_old' := first_image == first_press]
dat[, 'chose_new' := second_image == first_press]
dat[, 'chose_null' := chose_old == chose_new] # chose neither old nor new (one of the other choices)
dat[, 'hand_choice' := ifelse(first_press > 5, 'right', 'left')]
dat[, 'chose_null_old_hand' := chose_null & (hand_choice == hand1)]
dat[, 'chose_null_new_hand' := chose_null & !chose_null_old_hand]

dat[, 'slide_old' := slider(real_prep_time, chose_old, window_size), by = c('label')]
dat[, 'slide_new' := slider(real_prep_time, chose_new, window_size), by = c('label')]
dat[, 'slide_null' := slider(real_prep_time, chose_null, window_size), by = c('label')]
dat[, 'chose_null_old_hand_slide' := slider(real_prep_time, chose_null_old_hand, window_size), by = c('label')]
dat[, 'chose_null_new_hand_slide' := slider(real_prep_time, chose_null_new_hand, window_size), by = c('label')]


ggplot(dat, aes(x = real_prep_time, y = slide_old)) + 
  geom_line(colour = 'red', size = 1) +
  geom_line(aes(y = slide_new), colour = 'green', size = 1) +
  geom_line(aes(y = chose_null_old_hand_slide), colour = 'black', size = 1) +
  geom_line(aes(y = chose_null_new_hand_slide), colour = 'gray', size = 1) +
  facet_wrap(~label) + 
  xlim(c(0, 0.75))
