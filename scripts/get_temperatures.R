# Get temperature for each location


library(raster)
library(tidyverse)

site_data <- read.csv("data/Peces_KelpForest_2011-2013.csv") %>% 
  group_by(year, location, latitude, longitude) %>% 
  count() %>% 
  ungroup() %>% 
  mutate(year = ifelse(year < 2013, 2011, 2013)) %>% 
  filter(location %in% c("ASA", "BMA", "ERE", "ERO", "ISME", "ITSP", "RET", "SMI", "SSI"))

coords2011 <- site_data %>% 
  filter(year == 2011) %>% 
  select(longitude, latitude) %>% 
  as.matrix()

coords2013 <- site_data %>% 
  filter(year == 2013) %>% 
  select(longitude, latitude) %>% 
  as.matrix()

coastline <- readRDS(file = here("raw_data", "spatial", "coastline_mx.rds")) %>% 
  st_as_sf() %>% 
  st_simplify(dTolerance = 0.1) %>% 
  as("Spatial")

# 2012
rasters2011 <- paste0(here("raw_data", "spatial", "temp"), list.files(path = here("raw_data", "spatial", "temp"), pattern = "[9:0:1]_[6:7:8:9].nc"))

meanT2011 <- stack(rasters2011, varname = "sst4") %>%
  crop(extent(-120, -108, 22, 36)) %>% 
  mask(coastline, inverse = T) %>% 
  mask(mask = . > 30, maskvalue = T) %>%
  calc(fun = mean, na.rm = T)

EmeanT2011 <- raster::extract(meanT2011, coords2011, buffer = 5000, fun = mean, na.rm = T) %>% 
  as.data.frame() %>% 
  magrittr::set_colnames(value = "temp") %>% 
  mutate(year = 2011) %>% 
  cbind(coords2011)

# 2013
rasters2013 <- paste0(here("raw_data", "spatial", "temp"), list.files(path = here("raw_data", "spatial", "temp"), pattern = "[123]_[6:7:8:9].nc"))

meanT2013 <- stack(rasters2013, varname = "sst4") %>%
  crop(extent(-120, -108, 22, 36)) %>% 
  mask(coastline, inverse = T) %>% 
  mask(mask = . > 30, maskvalue = T) %>%
  calc(fun = mean, na.rm = T)


EmeanT2013 <- raster::extract(meanT2013, coords2013, buffer = 5000, fun = mean, na.rm = T) %>% 
  as.data.frame() %>% 
  magrittr::set_colnames(value = "temp") %>% 
  mutate(year = 2013) %>% 
  cbind(coords2013)

all_temps <- rbind(EmeanT2011, EmeanT2013) %>% 
  left_join(site_data, by = c("year", "latitude", "longitude")) %>% 
  select(location, year, latitude, longitude, temp)

all_temps %>% 
  ggplot(aes(x = year, y = temp, color = location)) +
  geom_point() +
  geom_line() +
  theme_bw()

write.csv(x = all_temps, file = here("data", "temps.csv"), row.names = F)

































