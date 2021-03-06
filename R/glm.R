#' Generalized linear models (GLM)
#'
#' @details See \url{http://mostly-harmless.github.io/radiant/quant/glm.html} for an example in Radiant
#'
#' @param dataset Dataset name (string). This can be a dataframe in the global environment or an element in an r_data list from Radiant
#' @param glm_dep_var The dependent variable in the regression
#' @param data_filter Expression intered in, e.g., Data > View to filter the dataset in Radiant. The expression should be a string (e.g., "price > 10000")
#' @param glm_indep_var Independent variables in the regression
#' @param glm_test_var Variables to evaluate in model comparison (i.e., a competing models F-test)
#' @param glm_int_var Interaction term to include in the model
#' @param glm_interactions Should interactions be considered. Options are "", 2, and 3. None ("") is the default. To consider 2-way interactions choose 2, and for 2- and 3-way interactions choose 3.
#' @param glm_predict Choose the type of prediction input. Default is no prediction (""). To generate predictions using a data.frame choose ("data"), and to include a command to generate values to predict select ("cmd")
#' @param glm_predict_cmd Generate predictions using a command. For example, carat = seq(.5, 1.5, .1) would produce predicitions for values of carat starting at .5, increasing to 1.5 in increments of .1. Make sure to press Enter after you finish entering the command. If no results are shown the command was likely invalid. Try entering the same expression in the R(studio) console to debug the command
#' @param glm_predict_data Generate predictions by specifying the name of a dataset (e.g., "diamonds"). The dataset must have all columns used in model estimation
#' @param glm_check Optional output or estimation parameters. "rsme" to show the root mean squared error. "sumsquares" to show the sum of squares table. "vif" to show the multicollinearity diagnostics. "confint" to show coefficient confidence interval estimates. "standardize" to use standardized coefficient estimates. "stepwise" to apply step-wise selection of variables to estimate the regression model
#' @param glm_conf_level Confidence level to use to estimate the confidence intervals (.95 is the default)
#' @param glm_plots Regression plots to produce for the specified regression model. Specify "" to avoid showing any plots (default). "hist" to show histograms of all variables in the model. "correlations" for a visual representation of the correlation matrix of all variables in the data. "scatter" to show scatter plots (or box plots for factors) for all independent variables with the dependent variable. "dashboard" a series of six plots that can be used to evaluate model fit visually. "resid_pred" to plot the independent variables against the model residuals. "coef" for a coefficient plot with adjustable confidence intervals. "leverage" to show leverage plots for each independent variable
#' @param glm_coef_int Include the intercept in the coefficient plot (TRUE, FALSE). FALSE is the default

#' @return A list with all variables defined in the function as an object of class glm_reg
#'
#' @examples
#' result <- glm_reg("titanic", "survived", c("pclass","sex"))
#'
#' @seealso \code{\link{summary.glm_reg}} to summarize results
#' @seealso \code{\link{plot.glm_reg}} to plot results
#'
#' @export
glm_reg <- function(dataset, glm_dep_var, glm_indep_var,
                data_filter = "",
                glm_test_var = "",
                # glm_int_var = "",
                # glm_interactions = "",
                glm_link = "logit",
                glm_predict = "",
                glm_predict_cmd = "",
                glm_predict_data = "",
                glm_check = "",
                glm_conf_level = .95,
                glm_plots = "",
                glm_coef_int = FALSE,
                glm_lines = "") {

# load("~/Desktop/GitHub/radiant_dev/inst/marketing/data/data_examples/titanic.rda")
# dataset <- "titanic"
# data_filter <- ""
# glm_dep_var <- "survived"
# glm_indep_var <- "pclass"
# glm_link <- "logit"
# glm_check <- "confint"
# glm_conf_level = .95
# glm_plots = "coef"

	vars <- glm_indep_var
	dat <- getdata_exp(dataset, c(glm_dep_var, glm_indep_var), filt = data_filter)

	# if(input$glm_interactions != 'none') vars <- c(vars,input$glm_intsel)

	if("standardize" %in% glm_check) {
    isNum <- sapply(dat, is.numeric)
    if(sum(isNum > 0)) dat[,isNum] %<>% data.frame %>% mutate_each(funs(scale))
  }

	formula <- paste(glm_dep_var, "~", paste(vars, collapse = " + ")) %>% as.formula

	if("stepwise" %in% glm_check) {
    # use k = 2 for AIC, use k = log(nrow(dat)) for BIC
		model <- glm(paste(glm_dep_var, "~ 1") %>% as.formula,
		             family = binomial(link = glm_link), data = dat) %>%
      			 step(k = 2, scope = list(upper = formula), direction = 'both')
	} else {
		model <- glm(formula, family = binomial(link = glm_link), data = dat)
	}

  glm_coeff <- tidy(model)
  glm_coeff$` ` <- sig_stars(glm_coeff$p.value)
  glm_coeff[,c(2:5)] %<>% round(3)
  glm_coeff$p.value[glm_coeff$p.value < .001] <- "< .001"
  colnames(glm_coeff) <- c("  ","coefficient","std.error","z.value","p.value"," ")

  isFct <- sapply(select(dat,-1), is.factor)
  if(sum(isFct) > 0) {
    for(i in names(select(dat,-1)[isFct]))
      glm_coeff$`  ` %<>% gsub(i, paste0(i," > "), .)

    rm(i, isFct)
  }

  if("confint" %in% glm_check || "odds" %in% glm_check || "coef" %in% glm_plots) {
    if(model$coeff %>% is.na %>% any) {
      glm_plots <- ""
    } else {
      cl_split <- function(x) 100*(1-x)/2
      cl_split(glm_conf_level) %>% round(1) %>% as.character %>% paste0(.,"%") -> cl_low
      (100 - cl_split(glm_conf_level)) %>% round(1) %>% as.character %>% paste0(.,"%") -> cl_high

      suppressMessages(confint(model, level = glm_conf_level)) %>%
        data.frame %>%
        magrittr::set_colnames(c("Low","High")) %>%
        cbind(select(glm_coeff,2),.) %>%
        set_rownames(glm_coeff$`  `) -> ci_tab
    }
    if("odds" %in% glm_check) odds_tab <- exp(ci_tab) %>% round(3)
    ci_tab %<>% round(3)
  }

  nrVars <- length(as.character(attr(model$terms,'variables'))[-1])
	plot_height <- 500
	plot_width <- 650

	if(glm_plots == 'hist') plot_height <- (plot_height / 2) * ceiling(nrVars / 2)
  if(glm_plots == 'coef') plot_height <- 300 + 20 * length(model$coefficients)

  environment() %>% as.list %>% set_class(c("glm_reg",class(.)))
}

# library(broom)
# library(dplyr)
# library(tidyr)
# library(magrittr)
# library(ggplot2)
# options(max.print = 100)
# source("~/gh/radiant_dev/R/radiant.R")
# load("~/Desktop/GitHub/radiant_dev/inst/marketing/data/data_examples/titanic.rda")
# titanic.est <- titanic %>%
#   filter(!age=='NA') %>%
#   mutate(age.f=cut(age,breaks=c(0,20,30,40,50,60,100)))

# dataset <- "titanic.est"
# data_filter <- ""
# glm_dep_var <- "survived"
# glm_indep_var <- c("pclass","sex","age.f")
# glm_link <- "logit"
# # glm_check <- "confint"
# glm_check <- "odds"
# glm_conf_level = .95
# glm_plots = "dashboard"
# glm_coef_int = TRUE
# glm_test_var = "age.f"

# result <- glm_reg(dataset, glm_dep_var, glm_indep_var, glm_check = glm_check, glm_plots = glm_plots,
#                   glm_coef_int = glm_coef_int, glm_test_var = glm_test_var)
# summary(result)
# plot(result)

#' @export
summary.glm_reg <- function(result) {

	if(class(result$model)[1] != 'glm') return(result)

  cat("Generalized linear model (glm)")
  cat("\nLink function:", result$glm_link)
  cat("\nData         :", result$dataset)
  if(result$data_filter %>% gsub("\\s","",.) != "")
    cat("\nFilter       :", gsub("\\n","", result$data_filter))
  cat("\nDependent variable   :", result$glm_dep_var)
  cat("\nIndependent variables:", paste0(result$glm_indep_var, collapse=", "))
  if("standardize" %in% result$glm_check)
 		cat("\nStandardized coefficients shown")
 	cat("\n\n")
  # cat("Null hyp.: variables x and y are not correlated\n")
  # cat("Alt. hyp.: variables x and y are correlated\n\n")
	print(result$glm_coeff, row.names=FALSE)

	# summary(result$model)
	glm_fit <- glance(result$model)

	# pseudo R2 (likelihood ratio) - http://en.wikipedia.org/wiki/Logistic_regression
	glm_fit %<>% mutate(r2 = (null.deviance - deviance) / null.deviance) %>% round(3)

	# chi-squared test of overall model fit (p-value) - http://www.ats.ucla.edu/stat/r/dae/logit.htm
	chi_pval <- with(result$model, pchisq(null.deviance - deviance, df.null - df.residual, lower.tail = FALSE))
	chi_pval %<>% { if(. < .001) "< .001" else round(.,3) }

  cat("\nPseudo R-squared:", glm_fit$r2)
  cat(paste0("\nLog-likelihood: ", glm_fit$logLik, ", AIC: ", glm_fit$AIC, ", BIC: ", glm_fit$BIC))
  cat(paste0("\nChi-statistic: ", with(glm_fit, null.deviance - deviance) %>% round(3), " df(",
         with(glm_fit, df.null - df.residual), "), p.value ", chi_pval), "\n")
  cat("Nr obs: ", nrow(result$dat), "\n\n")

  if("confint" %in% result$glm_check) {
    if(result$model$coeff %>% is.na %>% any) {
      cat("There is perfect multi-collineary in the set of independent variables.\nOne or more variables were dropped from the estimation.\nMulti-collinearity diagnostics were not calculated.\n")
    } else {
      result$ci_tab$`+/-` <- (result$ci_tab$High - result$ci_tab$coefficient)
      result$ci_tab %>%
        magrittr::set_colnames(c("coefficient", result$cl_low, result$cl_high, "+/-")) %>%
        print
      cat("\n")
    }
  }

  if("odds" %in% result$glm_check) {
    if(result$model$coeff %>% is.na %>% any) {
      cat("There is perfect multi-collineary in the set of independent variables.\nOne or more variables were dropped from the estimation.\nMulti-collinearity diagnostics were not calculated.\n")
    } else {
    	result$odds_tab
      result$odds_tab$`+/-` <- (result$odds_tab$High - result$odds_tab$Low)
      result$odds_tab %>%
        magrittr::set_colnames(c("odds", result$cl_low, result$cl_high, "+/-")) %>%
        print
      cat("\n")
    }
  }

  if("vif" %in% result$glm_check) {
    if(result$model$coeff %>% is.na %>% any) {
      cat("The set of independent variables exhibit perfect multi-collinearity.\nOne or more variables were dropped from the estimation.\nMulti-collinearity diagnostics were not calculated.\n")
    } else {
      if(length(result$glm_indep_var) > 1) {
        cat("Variance Inflation Factors\n")
        vif(result$model) %>%
          { if(!dim(.) %>% is.null) .[,"GVIF"] else . } %>% # needed when factors are included
          data.frame("VIF" = ., "Rsq" = 1 - 1/.) %>%
          round(3) %>%
          .[order(.$VIF, decreasing=T),] %>%
          { if(nrow(.) < 8) t(.) else . } %>% print
      } else {
        cat("Insufficient number of independent variables selected to calculate\nmulti-collinearity diagnostics")
      }
    }
    cat("\n")
  }

	if(result$glm_test_var != "") {
		sub_formula <- ". ~ 1"
		vars <- result$glm_indep_var

		# if(!is.null(input$glm_intsel) && input$glm_interactions != 'none') vars <- c(vars,input$glm_intsel)

		not_selected <- setdiff(vars, result$glm_test_var)
		if(length(not_selected) > 0) sub_formula <- paste(". ~", paste(not_selected, collapse = " + "))
		glm_sub <- update(result$model, sub_formula, data = result$dat)
		glm_sub_fit <- glance(glm_sub)
		glm_sub <- anova(glm_sub, result$model, test='Chi')

		# pseudo R2 (likelihood ratio) - http://en.wikipedia.org/wiki/Logistic_regression
		glm_sub_fit %<>% mutate(r2 = (null.deviance - deviance) / null.deviance) %>% round(3)
		glm_sub_pval <- glm_sub[,"Pr(>Chi)"][2] %>% { if(. <- .001) "< .001" else round(.3) }
		cat(attr(glm_sub,"heading")[2])
		cat("\nPseudo R-squared, Model 1 vs 2:", c(glm_sub_fit$r2, glm_fit$r2))
		cat(paste0("\nChi-statistic: ", glm_sub$Deviance[2] %>% round(3), " df(", glm_sub$Df[2], "), p.value ", glm_sub_pval))
	}
}

#' @export
plot.glm_reg <- function(result) {

	if(class(result$model)[1] != 'glm') return(result)

	# if({result$reg_int_var %>% strsplit(":") %>% unlist} %in% result$reg_indep_var %>% all) {
	# 	# nothing
 # 	} else {
 #    cat("Interaction terms contain variables not selected as\nmain effects. Removing interactions from the estimation")
 #    reg_int_var <- ""
 # 	}

	model <- ggplot2::fortify(result$model)
	model$.fitted <- predict(result$model, type = 'response')
	model$.actual <- as.numeric(model[,1])
	model$.actual <- model$.actual - max(model$.actual) + 1 	# adjustment in case max > 1

	vars <- as.character(attr(result$model$terms,'variables'))[-1]
	glm_dep_var <- vars[1]
	glm_indep_var <- vars[-1]
	nrCol <- 2
	plots <- list()

	if(result$glm_plots == "hist") {

		plots <- list()
		for(i in vars) plots[[i]] <- ggplot(result$dat, aes_string(x = i)) + geom_histogram()

	} else if(result$glm_plots == "coef") {

		p <- result$ci_tab %>%  { if(!result$glm_coef_int) .[-1,] else . } %>%
    	mutate(variable = rownames(.)) %>% ggplot() +
	    	geom_pointrange(aes(x = variable, y = coefficient, ymin = Low, ymax = High)) +
	      geom_hline(yintercept = 0, linetype = 'dotdash', color = "blue") + coord_flip()
	      return(p)

  } else if (result$glm_plots == "scatter") {
		for(i in glm_indep_var) {
			if('factor' %in% class(result$dat[,i])) {
				# plots[[i]] <- ggplot(result$dat, aes_string(x=i, y=glm_dep_var, fill=i)) + geom_boxplot(alpha = .3)
        plots[[i]] <- ggplot(result$dat, aes_string(x=i, fill=glm_dep_var)) + geom_bar(position = "fill", alpha=.7) +
              labs(list(y = ""))
			} else {
				plots[[i]] <- ggplot(result$dat, aes_string(x=i, y=glm_dep_var, fill=i)) + geom_boxplot(alpha = .3)
			}
		}
		nrCol <- 1
	} else if (result$glm_plots == "dashboard") {
		plots[[1]] <- ggplot(model, aes(x=.fitted, y=.actual)) + geom_point(alpha = .25) +
					 stat_smooth(method="glm", family="binomial", se=TRUE) +
					 geom_jitter(position = position_jitter(height = .05)) +
					 labs(list(title = "Actual vs Fitted values", x = "Fitted values", y = "Actual"))

		plots[[2]] <- ggplot(model, aes(x=.fitted, y=.resid)) + geom_point(alpha = .25) +
					 geom_hline(yintercept = 0) + geom_smooth(size = .75, linetype = "dotdash", se = TRUE) +
					 labs(list(title = "Residuals vs Fitted values", x = "Fitted", y = "Residuals"))

  	plots[[3]] <- ggplot(model, aes(x = .resid)) + geom_histogram(binwidth = .5) +
      labs(list(title = "Histogram of residuals", x = "Residuals"))

    plots[[4]] <- ggplot(model, aes(x=.resid)) + geom_density(alpha=.3, fill = "green") +
      stat_function(fun = dnorm, args = list(mean = mean(model[,'.resid']), sd = sd(model[,'.resid'])), color = "blue") +
  		labs(list(title = "Residual vs Normal density", x = "Residuals", y = "")) + theme(axis.text.y = element_blank())
	}

	if(exists("plots")) sshh( do.call(grid.arrange, c(plots, list(ncol = nrCol))) )
}


