# calculate flow & demands against nat_gf + flowby scens

# choose
#   b.demand_max_mgd as demand_mgd
# OR
#  b.demand_2025_mgd as demand_mgd
alt_gf <- sqldf(
  "
   select a.Date, a.year, a.month,
    b.demand_max_mgd as demand_mgd,
      a.Flow
   from nat_gf as a
   left outer join demand_lf as b
   on (
     a.Date = b.Date
   )
  "
)
alt_gf <- sqldf("select * from alt_gf where demand_mgd is not null")

alt_gf <- sqldf(
  "
    select *,
      (Flow * 0.2)/1.547 as avail_p20_mgd,
      (Flow * 0.3)/1.547 as avail_p30_mgd,
      CASE
        WHEN Flow >= (300.0 * 1.547)
          THEN (Flow - (300.0 * 1.547))/1.547
        ELSE 0.0
      END as avail_curr_mgd,
      CASE
        WHEN Flow >= (500.0 * 1.547)
          THEN (Flow - (500.0 * 1.547))/1.547
        ELSE 0.0
      END as avail_q500_mgd
    from alt_gf
  "
)

# add in the demands, factoring for flowby
alt_gf <- sqldf(
  "
    select a.*,
      CASE
        WHEN demand_mgd > avail_curr_mgd THEN avail_curr_mgd
        ELSE demand_mgd
      END as wd_curr_mgd,
      CASE
        WHEN demand_mgd > avail_p20_mgd THEN avail_p20_mgd
        ELSE demand_mgd
      END as wd_p20_mgd,
      CASE
        WHEN demand_mgd > avail_p30_mgd THEN avail_p30_mgd
        ELSE demand_mgd
      END as wd_p30_mgd,
      CASE
        WHEN demand_mgd > avail_q500_mgd THEN avail_q500_mgd
        ELSE demand_mgd
      END as wd_q500_mgd
    from alt_gf as a
    order by Date
  "
)

# calculate release needed
alt_gf <- sqldf(
  "
    select a.*,
      demand_mgd - wd_curr_mgd as need_curr_mgd,
      demand_mgd - wd_p20_mgd as need_p20_mgd,
      demand_mgd - wd_p30_mgd as need_p30_mgd,
      demand_mgd - wd_q500_mgd as need_q500_mgd,
      Flow - wd_curr_mgd * 1.547 as Flow_curr,
      Flow - wd_p20_mgd * 1.547 as Flow_p20,
      Flow - wd_p30_mgd * 1.547 as Flow_p30,
      Flow - wd_q500_mgd * 1.547 as Flow_q500
    from alt_gf as a
    order by Date
  "
)

# calculate release needed
need_gf <- sqldf(
  "
    select year, sum(need_curr_mgd) as need_curr_mgd,
      sum(need_p20_mgd) as need_p20_mgd,
      sum(need_p30_mgd) as need_p30_mgd,
      sum(need_q500_mgd) as need_q500_mgd
    from alt_gf
    group by year
  "
)

alt_gf_p10 <- sqldf("select * from alt_gf where Flow <= 2103")


# gives total annual releases needed in MGY
nprobs <- c(0,0.25,0.5,0.75,0.9,0.95,0.99,1.0)
needs_gf <- as.data.frame(rbind(
  round(quantile(need_gf$need_curr_mgd, probs=nprobs)),
  round(quantile(need_gf$need_q500_mgd, probs=nprobs)),
  #  round(quantile(need_gf$need_p20_mgd, probs=nprobs)),
  round(quantile(need_gf$need_p30_mgd, probs=nprobs))
))

# gives total annual releases needed in MGY
fprobs <- c(0,0.01,0.05,0.1,0.25,0.5,0.99,1.0)
gf_flows_stats <- as.data.frame(rbind(
  round(quantile(alt_gf$Flow, probs=fprobs)),
  round(quantile(alt_gf$Flow_curr, probs=fprobs)),
  round(quantile(alt_gf$Flow_q500, probs=fprobs)),
  round(quantile(alt_gf$Flow_p20, probs=fprobs)),
  round(quantile(alt_gf$Flow_p30, probs=fprobs))
))

mean(alt_gf$demand_mgd)

gf_flows_stats_current <- rbind(
  cbind(
    scenario = "Baseline", gf_flows_stats[1,]
  ),
  cbind(
    scenario = "Post WD", gf_flows_stats[2,]
  )
)

hydroTSM::fdc(
  cbind(
    alt_gf_p10$Flow,
    alt_gf_p10$Flow_curr
  ),
  yat = c(100,500,1000,1500,2000,2500),
  main = "Flow Duration Curve",
  sub = "",
  ylab = "Q, [cfs]",
)

hydroTSM::fdc(
  cbind(
    alt_gf$Flow,
    alt_gf$Flow_curr
  ),
  yat = c(100,500,1000,1500,2000,2500),
  main = "Flow Duration Curve",
  sub = "",
  ylab = "Q, [cfs]",
)
