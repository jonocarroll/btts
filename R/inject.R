#' Install a package with injected HTML in the help file
#'
#' Behaviour is otherwise identical to \code{\link[devtools]{install_github}}
#' except that some HTML code is carefully inserted in the roxygen2 header.
#' Processing of the roxygen2 code into a .Rd \code{\link[utils]{help}} file is
#' also hijacked and HTML sanitisation is deactivated (for that call only). The
#' injected HTML (static, not user-changeable for now) overlays a pull-up tab at
#' the bottom of HTML help files (such as viewed in RStudio) with some context
#' of the GitHub package, such as links to the source, issues page, version, and
#' author.
#'
#' The code for *that* function is linked to in the GitHub repo, meaning you can
#' see exactly how the function was written, rather than the comment-lacking
#' body() from within R.
#'
#' It is advisable to install the package for the first time using
#' `devtools::install_github` so that dependencies are properly met. The
#' additional functionality can then be added by re-installing with
#' `btts::install_github`.
#'
#' @details Warnings \strong{This function has potential to make damaging
#'   changes to your R library, and should not be executed on production or
#'   mission-critical setups.} You are invited to carefully scrutinize the
#'   source code \url{http://github.com/jonocarroll/btts} to ensure that nothing
#'   malicious is being done here.
#'
#'   Because this function needs to unload the namespace of the package it is
#'   trying to reinstall, it is a *very* good idea to start with a fresh session
#'   before using this function. In RStudio, CTRL/CMD + F10 restarts the
#'   session.
#'
#' @section Limitations: This function is not currently able to install GitHub
#'   packages that it itself depends on (for now, RCurl, gtools, and itself).
#'   Doing so results in failure to re-load the namespace and that's not good.
#'   This of course means that it can't self-document with the injected HTML.
#'
#'   The full consequences of changing the default parameters has not been
#'   explored. Most of the code for this function calls devtools functions, but
#'   there is no guarantee attached to any of it.
#'
#' @section If something goes wrong: If you do find a bug that causes something
#'   to go wrong, please file an Issue on GitHub. Some steps to try and remedy
#'   the failure that I've found to work include \itemize{ \item Restarting the
#'   R session and trying again, \item Manually removing the offending package
#'   with (\code{utils::\link[utils]{remove.packages}}), \item Manually deleting
#'   the library folder for the offending package, \item Installing the GitHub
#'   or CRAN version of the package with the standard tools, (i.e.
#'   \code{utils::\link[utils]{install.packages}} or
#'   \code{devtools::\link[devtools]{install_github}}). }
#'
#' @section Acknowledgements: Noam Ross created
#'   https://github.com/noamross/htmlhelp which I adapted into this form. This
#'   would not have been possible without his first steps.
#'
#' @inheritParams devtools::install_github
#'
#' @references \url{http://github.com/jonocarroll/btts}
#'
#' @param force whether to force installation of dependencies even if their SHA1
#'   reference hasn't changed from the currently installed version.
#'
#' @examples
#' \dontrun{
#' install_github("jonocarroll/butteRfly")
#' }
#'
#' @importFrom gtools getDependencies
#' @importFrom utils installed.packages
#' @import devtools
#' @export
install_github <- function(repo, username = NULL, ref = "master", subdir = NULL,
                           auth_token = devtools:::github_pat(quiet),
                           host = "api.github.com", force = TRUE,
                           quiet = FALSE, ...) {

  # prevent attempts to remove/re-install packages that btts depends on
  ght_deps <- gtools::getDependencies("btts")
  req_repo <- sub(".*/", "", repo)
  if (req_repo %in% ght_deps) stop("Unable to remove/re-install a
                                   package that btts depends on.")

  message("Warning: this function has the potential to damage your R setup.
It interferes with the devtools install process and injects HTML into the
help files.

*** DO NOT USE THIS FUNCTION ON PRODUCTION/MISSION CRITICAL SETUPS ***

Best results are obtained by starting with a fresh R session.

Refer to http://github.com/jonocarroll/btts for further disclaimers.
")

  continue_yn <- readline(prompt = "If you would like to continue,
                         please type YES and hit Enter.")

  waive_blame <- tolower(continue_yn)
  stopifnot(waive_blame == "yes")

  remotes <- lapply(repo, devtools:::github_remote, username = username,
                    ref = ref, subdir = subdir, auth_token = auth_token,
                    host = host)
  if (!isTRUE(force)) {
    # remotes <- Filter(function(x) devtools:::different_sha(x, quiet = quiet),
    remotes <- Filter(function(x) devtools:::different_sha(x),
                      remotes)
  }
  btts::install_remotes(remotes, quiet = quiet, ...)
}

#' @export
#' @keywords internal
install_remotes <- function(remotes, ...) {
  invisible(vapply(remotes, btts::install_remote, ..., FUN.VALUE = logical(1)))
}

#' @export
#' @keywords internal
install_remote <- function(remote, ..., quiet=FALSE) {
  ## hijack devtools:::install_remote to inject some HTML into help files

  stopifnot(devtools:::is.remote(remote))

  if (any(grepl(remote$repo, installed.packages()[, 1])))
      utils::remove.packages(remote$repo)

  bundle <- devtools:::remote_download(remote, quiet = FALSE)
  # quiet = FALSE to force re-install
  on.exit(unlink(bundle), add = TRUE)
  source <- devtools:::source_pkg(bundle, subdir = remote$subdir)
  on.exit(unlink(source, recursive = TRUE), add = TRUE)
  metadata <- devtools:::remote_metadata(remote, bundle, source)

  message("*** INJECTING HTML CODE INTO HELP FILE ***")
  allrfiles <- dir(file.path(source, "R"), full.names = TRUE)

  for (ifile in allrfiles) {

    # cat(paste0("injecting to ",basename(ifile), "\n"))

    injection <- paste0("#' \\if{html}{\\Sexpr[stage=render,
                        results=text]{btts:::github_overlay(",
                        "'", remote$username, "/", remote$repo, "',",
                        "'R/", basename(ifile), "')}}")

    rcontent <- file(ifile, "r")

    all_lines <- readLines(rcontent, n = -1)

    ## find roxygen functions
    ## hooking into @export works if there aren't examples,
    ## otherwise the injection is treated as an example.
    # return_lines <- which(grepl("#'[ ]+@export", all_lines))
    # STILL FAILS IF AFTER @inheritParams or @import
    ## NEED A BETTER INJECTION POINT
    roxy_blocks <- which(grepl("^#'", all_lines))
    runs <- split(roxy_blocks, cumsum(seq_along(roxy_blocks) %in%
                                          (which(diff(roxy_blocks) > 1) + 1)))
    # runs = split(seq_along(roxy_blocks), cumsum(c(0, diff(roxy_blocks) > 1)))
    # cat(paste0("runs has length ",length(runs)))
    if (length(runs) > 0) {
      # roxy_lines <- lapply(runs, function(x) all_lines[roxy_blocks[x]])
      roxy_lines <- lapply(runs, function(x) all_lines[x])
      for (iblock in seq_along(runs)) {
        if (length(roxy_lines[[iblock]]) > 5) { ## skip over helper files
          # example_line <- which(grepl("^#'[ ]+@examples", roxy_lines[[iblock]]))
          export_line <- which(grepl("^#'[ ]+@export", roxy_lines[[iblock]]))
          ## check that the fn is exported
          if (length(export_line) != 0) {
              inject_line <- 2 ## just after the one-line title... should be safe(r)
              all_lines[runs[[iblock]][inject_line]] <-
                  paste0("#'\n", injection, "\n#'\n", all_lines[runs[[iblock]][inject_line]])
            # if (length(example_line) == 0) {
            #   inject_line <- export_line
            #   all_lines[runs[[iblock]][inject_line]] <-
            #   paste0("#'\n#'\n", injection, "\n#'\n", all_lines[runs[[iblock]][inject_line]])
            # # } else if (export_line < example_line) {
            # #   inject_line <- export_line
            # #   all_lines[runs[[iblock]][inject_line]] <-
            #   paste0("#'\n", injection, "\n#'\n", all_lines[runs[[iblock]][inject_line]])
            # } else {
            #   inject_line <- min(example_line)
            #   all_lines[runs[[iblock]][inject_line]] <-
            #   paste0("#'\n#'\n", injection, "\n#'\n", all_lines[runs[[iblock]][inject_line]])
            # }
          }
        }
      }
    }
    # return_lines <- which(grepl("#'[ ]+@export", all_lines))

    ## write out the file, but inject the footer code before @export

    # saved_lines <- all_lines
    # message(paste0("*** INJECTING HTML CODE INTO ",basename(ifile)," HELP FILE ***"))
    # all_lines[return_lines] <- paste0(all_lines[return_lines], "\n\n", injection, "\n\n")
    # all_lines[return_lines] <- paste0("#'\n", injection, "\n#'\n", all_lines[return_lines])

    cat(all_lines, file = ifile, sep = "\n")

    close(rcontent)

  }

  # cat(source)

  ## add the GitHub logo to the package help
  manfigdir <- file.path(source, "man/figures")
  if (!dir.exists(manfigdir)) dir.create(manfigdir)
  file.copy(from = system.file("extdata", "GitHub-Mark-Light-64px.png",
                               package = "btts"), to = manfigdir)

  message("*** REBUILDING HELP FILES WITH INJECTED CODE ***")
  devtools::document(pkg = source)
  # message("DOCUMENTED.")
  ret_code <- devtools:::install(source, ..., quiet = quiet, metadata = metadata)

  ## re-write the documentation
  # devtools::document(pkg = as.package(remote$repo))

  # install(source, ..., quiet = quiet, metadata = metadata)
  return(invisible(ret_code))
}
