# calculate flow & demands against nat_lf + flowby scens

alt_lf <- sqldf(
  "
   select a.Date, a.year, a.month,
    (b.wssc_pot + b.wa_gf + b.wa_lf
      + b.fw_pot + b.rville) as demand_mgd,
      a.Flow
   from nat_lf as a
   left outer join icprb_prod_max as b
   on (
     a.month = b.month
   )
  "
)

alt_lf <- sqldf(
  "
    select *,
      (Flow * 0.2)/1.547 as avail_p20_mgd,
      (Flow * 0.3)/1.547 as avail_p30_mgd,
      CASE
        WHEN Flow >= (100.0 * 1.547)
          THEN (Flow - (100.0 * 1.547))/1.547
        ELSE 0.0
      END as avail_curr_mgd,
      CASE
        WHEN Flow >= (500.0 * 1.547)
          THEN (Flow - (500.0 * 1.547))/1.547
        ELSE 0.0
      END as avail_q500_mgd
    from alt_lf
  "
)

# add in the demands, factoring for flowby
alt_lf <- sqldf(
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
    from alt_lf as a
    order by Date
  "
)

# calculate release needed
alt_lf <- sqldf(
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
    from alt_lf as a
    order by Date
  "
)

# calculate release needed
need_lf <- sqldf(
  "
    select year, sum(need_curr_mgd) as need_curr_mgd,
      sum(need_p20_mgd) as need_p20_mgd,
      sum(need_p30_mgd) as need_p30_mgd,
      sum(need_q500_mgd) as need_q500_mgd
    from alt_lf
    group by year
  "
)

rbind(
  round(quantile(need_lf$need_curr_mgd, probs=c(0,0.25,0.5,0.75,0.9,0.95,0.99,1.0))),
  round(quantile(need_lf$need_q500_mgd, probs=c(0,0.25,0.5,0.75,0.9,0.95,0.99,1.0))),
  round(quantile(need_lf$need_p20_mgd, probs=c(0,0.25,0.5,0.75,0.9,0.95,0.99,1.0))),
  round(quantile(need_lf$need_p30_mgd, probs=c(0,0.25,0.5,0.75,0.9,0.95,0.99,1.0)))
)
