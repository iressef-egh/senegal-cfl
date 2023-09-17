
RomanToNumeric <- function(x) 
{
  roman <- c(" i", " ii", " iii", " iv", " v", " vi", " vii", " viii", " ix", " x") %>%
    paste0(., "$")
  numeric <- c(1:10) %>% as.character %>% paste0(" ", .)
  names(numeric) <- roman
  str_replace_all(x, numeric)
}


deduplicate.spaces <- function(x) 
{
  t <- data.table(var=x)
  t[, n := .GRP, by=gsub(" ", "", var)]
  t[order(n, -stri_length(var))]
  t[, var := var[[1]], by=n]
  return(t$var)
}

collapse.spaces <- function(x, threshold=0.4) 
{
  ifelse(str_count(x, "\\s")/str_length(x)>=threshold, gsub(" ", "", x), x)
}

clean.fac_name <- function(x) 
{
  x %>% 
    stri_trans_general('Latin-ASCII') %>%
    tolower() %>%
    ## If more than 40% of characters ar spaces, remove all spaces
    collapse.spaces(.) %>%
    ## Roman to numeric
    RomanToNumeric(.) %>% 
    ## Force space between number
    gsub("([1-9]+)", " \\1", .) %>% 
    ## Remove punctuation
    gsub("\\'","", .) %>%
    gsub("[[:punct:]]+"," ", .) %>%
    ## Remove double spaces
    gsub("  ", " ", .) %>%
    ## Trim white spaces
    trimws(.)
}

get.aregexec <- function(str, vec, dist=0.1) 
{
  matches <- aregexec(str, vec, max.distance = dist)
  starts <- unlist(matches)
  ends <- starts - 1 + map_int(matches, ~ attr(., "match.length"))
  res <- substr(vec, starts, ends) %>% as.data.table
  res <- res[!(starts < 0)]
  res <- unique(res)
  return(res[[1]])
}

## Subtoken dist
token_dist <- function(s1, s2, method="jw") {
  s1.tokens <- s1 %>% str_split(., " ") %>% unlist %>% unique
  s2.tokens <- s2 %>% str_split(., " ") %>% unlist %>% unique
  dists <- stringdistmatrix(s1.tokens, s2.tokens, method=method) %>% apply(1, min) 
  lengths <- str_length(s1.tokens)
  weighted_dists <- ((1-dists)*lengths)
  score <- 1 - sum(weighted_dists/sum(lengths))
  return(score)
}
token_dist <- Vectorize(token_dist, vectorize.args = c("s1", "s2"))

tokendistmatrix <- function(x, y=NULL, method="jw") {
  if (is.null(y)) y <- x
  m <- lapply(1: length(y), function(i) {
    token_dist(x, y[i], method=method) %>% as.matrix
  })
  Reduce(cbind, m)
}


