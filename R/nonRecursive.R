#------------------------------------------------------------------------------
#' nonRecursive trimming procedure.
#'
#' \code{nonRecursive} takes a data frame of RT data and returns trimmed rt
#' data that fall below a set standard deviation above the each participant's
#' mean for each condition. The SD used for trimming is proportional to the
#' number of trials in the data being passed, as described in van Selst &
#' Jolicoeur (1994).
#'
#' @param data A data frame. It must contain columns named "participant",
#' "condition", "rt", and "accuracy". The RT can be in seconds
#' (e.g., 0.654) or milliseconds (e.g., 654). Typically, "condition" will
#' consist of strings. "accuracy" must be 1 for correct and 0 for error
#' responses.
#' @param minRT The lower criteria for acceptable response time. Must be in
#' the same form as rt column in data frame (e.g., in seconds OR milliseconds).
#' All RTs below this value are removed before proceeding with SD trimming.
#' @param ppt.var The quoted name of the column in the data that identifies participants.
#' @param cond.var The quoted name of the column in the data that includes the conditions.
#' @param rt.var The quoted name of the column in the data containing reaction times.
#' @param acc.var The quoted name of the column in the data containing accuracy,
#' coded as 0 or 1 for incorrect and correct trial, respectively.
#' @param omitErrors If set to TRUE, error trials will be removed before
#' conducting trimming procedure. Final data returned will not be influenced
#' by errors in this case.
#' @param digits How many decimal places to round to after trimming?
#' @examples
#' # load the example data that ships with trimr
#' data(exampleData)
#'
#' # perform the trimming, returning mean RT
#' trimmedData <- nonRecursive(data = exampleData, minRT = 150)
#'
#' @references Van Selst, M. & Jolicoeur, P. (1994). A solution to the effect
#' of sample size on outlier elimination. \emph{Quarterly Journal of Experimental
#' Psychology, 47} (A), 631-650.
#'
#' @importFrom stats sd
#'
#' @export

nonRecursive <- function(data,
                         minRT,
                         ppt.var = "participant",
                         cond.var = "condition",
                         rt.var = "rt",
                         acc.var = "accuracy",
                         omitErrors = TRUE,
                         digits = 3) {

  # remove errors if the user has asked for it
  if(omitErrors == TRUE){
    trimmedData <- data[data[[acc.var]] == 1, ]
  } else {
    trimmedData <- data
  }

  # get the list of participant numbers
  participant <- unique(data[[ppt.var]])

  # get the list of experimental conditions
  conditionList <- unique(data[, cond.var])

  # trim the data
  trimmedData <- trimmedData[trimmedData[[rt.var]] > minRT, ]

  # ready the final data set
  # make a df here to preserve ppt column
  finalData <- as.data.frame(matrix(0, nrow = length(participant),
                                    ncol = length(conditionList)))

  # give the columns the condition names
  colnames(finalData) <- conditionList

  # add the participant column
  finalData <- cbind(participant, finalData)

  # convert to data frame
  finalData <- data.frame(finalData)

  # intialise looping variable for subjects
  i <- 1

  # loop over all subjects
  for(currSub in participant){

    # intialise looping variable for conditions. It starts at 2 because the
    # first column in the data file containing condition information is the
    # second one.
    j <- 2

    # loop over all conditions
    for(currCond in conditionList){

      # get the relevant data
      tempData <- trimmedData[trimmedData[[ppt.var]] == currSub &
                                trimmedData[[cond.var]] == currCond, ]


      # find the average, and add to the data frame
      finalData[i, j] <- round(nonRecursiveTrim(tempData[[rt.var]]), digits = digits)

      # update condition loop counter
      j <- j + 1
    }

    # update participant loop counter
    i <- i + 1
  }
  return(finalData)
}
#------------------------------------------------------------------------------


#------------------------------------------------------------------------------
### The function that acually does the trimming
nonRecursiveTrim <- function(data){

  # load the linear interpolation data file (hidden from user)
  criterion <- linearInterpolation

  # get the sample size of the current data
  sampleSize <- length(data)

  # if the sample size is greater than 100, use SDs for N = 100
  if(sampleSize > 100){
    sampleSize <- 100
  }

  # look up the SD to use for the current sampleSize
  stDev <- criterion$nonRecursive[sampleSize]

  # now use this value to do the trimming
  curMean <- mean(data)
  curSD <- sd(data)
  maxCutoff <- curMean + (stDev * curSD)
  minCutoff <- curMean - (stDev * curSD)

  # which trials should be included?
  includedTrials <- data < maxCutoff & data > minCutoff

  # calculate the final mean RT
  finalData <- mean(data[includedTrials])

  # return it
  return(finalData)
}
#------------------------------------------------------------------------------
