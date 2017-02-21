#' btts: We need to go... Back To The Source
#' 
#' Provides an Rmd macro to insert a HTML popup bar in the help menu linking 
#' back to the GitHub page to encourage collaboration, report bugs, etc...
#' 
#' \if{html}{\figure{BTTS.png}{options: width="80\%"}}
#' 
#' The behaviour of \code{\link[btts]{install_github}} is otherwise identical to
#' the devtools version \code{\link[devtools]{install_github}} except that some
#' HTML code is carefully inserted in the roxygen2 header. Processing of the
#' roxygen2 code into a .Rd \code{\link[utils]{help}} file is also hijacked and
#' HTML sanitisation is deactivated (for that call only). The injected HTML
#' (static, not user-changeable for now) overlays a pull-up tab at the bottom of
#' HTML help files (such as viewed in RStudio) with some context of the GitHub 
#' package, such as links to the source, issues page, version, and author.
#' 
#' The code for *that* function is linked to in the GitHub repo, meaning you can
#' see exactly how the function was written, rather than the comment-lacking 
#' body() from within R.
#' 
#' Noam Ross created \url{https://github.com/noamross/htmlhelp} which I adapted
#' into this form. This would not have been possible without his first steps.
#' 
#' @docType package
#' @name btts
NULL
