> Cross-tab analysis is used to evaluate if two nominally scaled variables are associated. This tool is also known as chi-square or contingency table analysis

#### Example 1

The data are from a sample for 580 newspaper readers that indicated which newspaper they read most frequently (USA today or Wall Street Journal) and their level of income (Low income vs. High income). The data has three variables:  A respondent identifier (Resp), respondent income (High or Low), and the primary newspaper the respondent reads (USA today or Wall Street Journal).

We will examine if there is a relationship between income level and choice of newspaper. In particular, we test the following null and alternative hypothesis:

- H0: There is no relationship between income level and newspaper choice
-	Ha: There is a relationship between income level and newspaper choice

If the null-hypothesis is rejected we can investigate which cell(s) contribute to the hypothesized association. In Radiant (Base > Cross-tab) we choose Income as the grouping factor and Newspaper as the second factor. First we compare the observed and expected frequencies. The expected frequencies are calculated using H0 (i.e., no association) as (Row total x Column Total) /  Overall Total.

![cross-tab - summary](figures_quant/crosstab_summary.png)

The Pearson chi-squared test evaluates if we can reject the null-hypothesis that the two variables are independent. It does so by comparing the observed frequencies (i.e., what we actually see in the data) to the expected frequencies (i.e., what we would expect to see if the two variables were independent). If there are big differences between the table of expected and observed frequencies the chi-square value will be 'large'. The chi-square value for each cell is calculated as (O - E)^2 / E, where O is the observed frequency in a cell and E is the expected frequency in that cell if the null hypothesis holds. These values can be shown by clicking the 'Contribution to chi-square value' box. The overall chi-square value is obtained by summing across all cells, i.e., it is the sum of the values shown in the 'Contribution to chi-square value' table.

In order to determine if the chi-square value can be considered large we first determine the degrees of freedom (df). In particular: df = (# rows - 1) x (# columns - 1). In a 2X 2 table, we have (2-1) X (2-1) = 1 df. The output in the Summary tab shows the value of the chi-square statistic, the associated df and the p-value associated with the test. We also see the contribution from each cells to the overall chi-square measure.

Remember to check the expected values: None of of the cells should have an expected count of less than 5. If necessary, ‘collapse’ rows and/or columns. All expected frequencies are > 5 therefore the chi-square statistic is unlikely to be biased. As usual we reject the null-hypothesis when the p-value is smaller 0.05. Since our p-value is very small (< .001) we can reject the null-hypothesis (i.e., the data support the conclusion that there is an association between newspaper readership and income).

In addition to the numerical output provided in the Summary tab we can evaluate the hypothesis visually (see Plots tab). We choose the same variables as before. However, we will plot the the the standardized deviations. This measure is calculated as O - E / sqrt(E), i.e., a score of how different the observed and expected frequencies in one cell in our table are. When a cell's standardized deviation is greater than 1.96 (in absolute value) we can say the cell has a significant deviation from the model of independence (or no association).

![cross-tab - plots](figures_quant/crosstab_plots.png)

In the plot we see that all cells contribute to the association between income and readership as all standardized deviations are larger than 1.96 in absolute value (i.e., the bars extend beyond the outer dotted line in the plot).

In other words, there are significantly fewer low income respondents that read WSJ and significantly more high income respondents that read WSJ than would be expected if the null hypothesis of no-association were true. Furthermore, there are significantly more low income respondents that read USA today and significantly fewer high income respondents that read USA Today than would be expected if the null hypothesis of no-association were true.

Note: The data description for the goals2 dataset has information on how rows or columns in a cross-tab can be collapsed when some of the expected values are below 5.

&copy; Vincent Nijs (2015) <a rel="license" href="http://creativecommons.org/licenses/by-nc-sa/4.0/" target="_blank"><img alt="Creative Commons License" style="border-width:0" src="imgs/80x15.png" /></a>
