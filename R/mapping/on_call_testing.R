library("ggmap")

# map <- ggmap::get_map(c(left = -97.1268, bottom = 31.536245,
#                         right = -97.099334, top = 31.559652))
# map2 <- ggmap::get_map(source = "stamen", maptype = "toner", c(left = -97.1268, bottom = 31.536245, right = -97.099334, top = 31.559652))
map4 <- ggmap::get_map(source = "stamen", maptype = "watercolor", c(left = -97.1268, bottom = 31.536245, right = -97.099334, top = 31.559652))

ggmap(map2)


