#' Compare proportions across groups
#'
#' @details See \url{http://mostly-harmless.github.io/radiant/quant/compare_props.html} for an example in Radiant
#'
#' @param dataset Dataset name (string). This can be a dataframe in the global environment or an element in an r_data list from Radiant
#' @param cp_var1 A grouping variable to creates slips in the data for comparisons
#' @param cp_var2 The variable to calculate proportions for
#' @param data_filter Expression intered in, e.g., Data > View to filter the dataset in Radiant. The expression should be a string (e.g., "price > 10000")
#' @param cp_levels The factor level selected for the proportion comparison
#' @param cp_alternative The alternative hypothesis (two.sided, greater or less)
#' @param cp_sig_level Span of the confidence interval
#' @param cp_adjust Adjustment for multiple comparisons (none or bonferroni)
#' @param cp_plots One or more plots of proportions or counts ("props" or "counts")
#'
#' @return A list with all variables defined in the function as an object of class compare_props
#'
#' @examples
#' result <- compare_props("titanic", "pclass", "survived")
#'
#' @seealso \code{\link{summary.compare_props}} to summarize results
#' @seealso \code{\link{plots.compare_props}} to plot results
#' @export
compare_props <- function(dataset, cp_var1, cp_var2,
                         data_filter = "",
                         cp_levels = "",
                         cp_alternative = "two.sided",
                         cp_sig_level = .95,
                         cp_adjust = "none",
                         cp_plots = "props") {

# load("~/Desktop/GitHub/radiant_dev/inst/marketing/data/data_examples/titanic.rda")
# dataset <- "titanic"
# data_filter = ""
# cp_var1 <- "pclass"
# cp_var2 <- "survived"
# cp_alternative = "two.sided"
# cp_sig_level = .95
# cp_adjust = "none"
# cp_plots = "bar"

	vars <- c(cp_var1, cp_var2)
	dat <- getdata_exp(dataset, vars, filt = data_filter) %>% mutate_each(funs(as.factor))

	levs <- levels(dat[,cp_var2])
	if(cp_levels != "") {
		levs <- levels(dat[,cp_var2])
		if(cp_levels %in% levs && levs[1] != cp_levels) {
			dat[,cp_var2] %<>% as.character %>% as.factor %>% relevel(cp_levels)
			levs <- levels(dat[,cp_var2])
		}
	}

	# check variances in the data
  if(dat %>% summarise_each(., funs(var(.,na.rm = TRUE))) %>% min %>% {. == 0})
  	return("Test could not be calculated. Please select another variable.")

  rn <- ""
  dat %>%
  group_by_(cp_var1, cp_var2) %>%
  summarise(n = n()) %>%
  spread_(cp_var2, "n") %>%
  {
  	.[,1][[1]] %>% as.character ->> rn
	  select(., -1) %>%
	  as.matrix %>%
	  set_rownames(rn)
  } -> prop_input

	##############################################
	# flip the order of pairwise testing - part 1
	##############################################
  flip_alt <- c("two.sided" = "two.sided",
                "less" = "greater",
                "greater" = "less")
	##############################################

	suppressWarnings(pairwise.prop.test(prop_input, p.adj = cp_adjust,
	                     alternative = flip_alt[cp_alternative])) %>% tidy -> res

	##############################################
	# flip the order of pairwise testing - part 2
	##############################################
	res[,c("group1","group2")] <- res[,c("group2","group1")]
	##############################################

	plot_height <- 400 * length(cp_plots)

	# from http://www.cookbook-r.com/Graphs/Plotting_props_and_error_bars_(ggplot2)/
	ci_calc <- function(se, conf.lev = .95)
	 	se * qnorm(conf.lev/2 + .5, lower.tail = TRUE)

	class(prop_input)

	prop_input %>%
		data.frame %>%
		mutate(n = .[,1:2] %>% rowSums, p = .[,1] / n,
					 se = (p * (1-p) / n) %>% sqrt,
       		 ci = ci_calc(se, cp_sig_level)) %>%
		set_rownames({prop_input %>% rownames})-> dat_summary

	vars <- paste0(vars, collapse=", ")
  environment() %>% as.list %>% set_class(c("compare_props",class(.)))
}

# library(broom)
# library(dplyr)
# library(tidyr)
# library(magrittr)
# library(ggplot2)
# source("~/gh/radiant_dev/R/radiant.R")
# rm(r_env)

# load("~/Desktop/GitHub/radiant_dev/inst/marketing/data/data_examples/titanic.rda")
# dataset <- "titanic"
# data_filter = ""
# cp_var1 <- "pclass"
# cp_var2 <- "survived"
# cp_alternative = "two.sided"
# cp_sig_level = .95
# cp_adjust = "none"
# cp_plots = c("props","counts")
# result <- compare_props(dataset, cp_var1, cp_var2, cp_plots = cp_plots)
# summary.compare_props(result)
# plot.compare_props(result)

#' Summarize method for output from the compare_props function. This is a method of class compare_props and can be called as summary or summary.compare_props
#'
#' @details See \url{http://mostly-harmless.github.io/radiant/quant/compare_props.html} for an example in Radiant
#'
#' @examples
#' result <- compare_props("titanic", "pclass", "survived")
#' summary(result)
#'
#' @seealso \code{\link{compare_props}} to calculate results
#' @seealso \code{\link{plot.compare_props}} to plot results
#' @export
summary.compare_props <- function(result) {

  if(result$cp_adjust == "bonf") {
    cat("Pairwise comparisons (bonferroni adjustment)\n")
  } else {
	  cat("Pairwise comparisons (no adjustment)\n")
  }

	cat("Data     :", result$dataset, "\n")
	if(result$data_filter %>% gsub("\\s","",.) != "")
		cat("Filter   :", gsub("\\n","", result$data_filter), "\n")
	cat("Variables:", result$vars, "\n\n")

  result$dat_summary[,-1] %<>% round(3)
  print(result$dat_summary %>% as.data.frame, row.names = FALSE)
	cat("\n")

  hyp_symbol <- c("two.sided" = "not equal to",
                  "less" = "<",
                  "greater" = ">")[result$cp_alternative]

  props <- result$dat_summary$p
  names(props) <- result$rn
	res <- result$res
	res$`Alt. hyp.` <- paste(res$group1,hyp_symbol,res$group2," ")
	res$`Null hyp.` <- paste(res$group1,"=",res$group2, " ")
	res$diff <- (props[res$group1 %>% as.character] - props[res$group2 %>% as.character]) %>% round(3)
	res <- res[,c("Alt. hyp.", "Null hyp.", "diff", "p.value")]
	res$` ` <- sig_stars(res$p.value)
	res$p.value <- round(res$p.value,3)
	res$p.value[ res$p.value < .001 ] <- "< .001"
	print(res, row.names = FALSE, right = FALSE)
	cat("\nSignif. codes:  0 '***' 0.001 '**' 0.01 '*' 0.05 '.' 0.1 ' ' 1\n")
}

#' Plot results from the compare_props function. This is a method of class compare_props and can be called as plot or plot.compare_props
#'
#' @details See \url{http://mostly-harmless.github.io/radiant/quant/compare_props.html} for an example in Radiant
#'
#' @examples
#' result <- compare_props("titanic", "pclass", "survived", cp_plots = "props")
#' plot(result)
#'
#' @seealso \code{\link{compare_props}} to calculate results
#' @seealso \code{\link{summary.compare_props}} to summarize results
#'
#' @export
plot.compare_props <- function(result) {

	dat <- result$dat
	var1 <- colnames(dat)[1]
	var2 <- colnames(dat)[-1]
	result$dat_summary[,var1] <- result$rn
	lev_name <- result$levs[1]

	# from http://www.cookbook-r.com/Graphs/Plotting_props_and_error_bars_(ggplot2)/
	plots <- list()
	if("props" %in% result$cp_plots) {
		# use of `which` allows the user to change the order of the plots shown
		plots[[which("props" == result$cp_plots)]] <-
			ggplot(result$dat_summary, aes_string(x = var1, y = "p", fill = var1)) +
			geom_bar(stat = "identity") +
	 		geom_errorbar(width = .1, aes(ymin = p-ci, ymax = p+ci)) +
	 		geom_errorbar(width = .05, aes(ymin = p-se, ymax = p+se), colour = "blue")
	}

	if("counts" %in% result$cp_plots) {
		# use of `which` allows the user to change the order of the plots shown
		plots[[which("counts" == result$cp_plots)]] <-
			ggplot(result$dat, aes_string(x = var1, fill = var2)) +
			geom_bar(position = "dodge")
	}

	sshh( do.call(grid.arrange, c(plots, list(ncol = 1))) )
}
