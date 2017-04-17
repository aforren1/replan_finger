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

wd <- paste0(getwd(), '/jcc')
filenames <- list.files(path = wd, pattern = '*.csv$', recursive = TRUE, full.names= TRUE)
filenames <- filenames[!grepl(filenames, pattern = '000')]

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
  scale_y_continuous(breaks = seq(0, 1, 0.2))