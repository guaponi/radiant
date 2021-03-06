% Generated by roxygen2 (4.1.0): do not edit by hand
% Please edit documentation in R/compare_prop.R
\name{summary.compare_props}
\alias{summary.compare_props}
\title{Summarize method for output from the compare_props function. This is a method of class compare_props and can be called as summary or summary.compare_props}
\usage{
\method{summary}{compare_props}(result)
}
\description{
Summarize method for output from the compare_props function. This is a method of class compare_props and can be called as summary or summary.compare_props
}
\details{
See \url{http://mostly-harmless.github.io/radiant/quant/compare_props.html} for an example in Radiant
}
\examples{
result <- compare_props("titanic", "pclass", "survived")
summary(result)
}
\seealso{
\code{\link{compare_props}} to calculate results

\code{\link{plot.compare_props}} to plot results
}

