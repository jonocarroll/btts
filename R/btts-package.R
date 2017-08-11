#' btts: We need to go... Back To The Source
#' 
#' Provides an Rmd macro to insert an HTML popup bar in the help menu linking 
#' back to the GitHub page to encourage collaboration, report bugs, etc...
#' 
#' \if{html}{\figure{BTTS.png}{options: width="80\%"}}
#' 
#' The behaviour of \code{\link[btts]{install_github}} is identical to the 
#' devtools version \code{\link[devtools]{install_github}}, except that
#' some HTML code is carefully inserted in the roxygen2 header. Processing of 
#' the roxygen2 code into a .Rd \code{\link[utils]{help}} file is also hijacked 
#' and HTML sanitisation is deactivated (for that call only). The injected HTML 
#' (static, not user-changeable for now) overlays a pull-up tab at the bottom 
#' of HTML help files (such as viewed in RStudio) with GitHub links to the 
#' source, issues page, version, and author.
#' 
#' When viewing the help file for a specific function, the link is to *that* 
#' function, making it easy to see exactly how the function was written.
#' 
#' Noam Ross created \url{https://github.com/noamross/htmlhelp} which I adapted
#' into this form. This would not have been possible without his initial work.
#' 
#' @docType package
#' @name btts
NULL
