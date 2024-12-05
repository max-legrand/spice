open Base
open Unix

(** ANSI color codes *)
let cyan = "\027[0;36m"

let purple = "\027[0;35m"
let red = "\027[0;31m"
let yellow = "\027[0;33m"
let reset = "\027[0m"

type level =
  | ERROR
  | WARN
  | INFO
  | DEBUG

(** Global log level - Default is INFO *)
let log_level = ref INFO

let set_log_level level = log_level := level

let should_log msg_level =
  match !log_level, msg_level with
  | ERROR, ERROR -> true
  | WARN, ERROR | WARN, WARN -> true
  | INFO, ERROR | INFO, WARN | INFO, INFO -> true
  | DEBUG, _ -> true
  | _ -> false
;;

let level_to_string level =
  match level with
  | ERROR -> "ERROR"
  | WARN -> "WARN"
  | INFO -> "INFO"
  | DEBUG -> "DEBUG"
;;

(** Get timestamp*)
let get_timestamp () = Unix.localtime (Unix.time ())

(** Convert timestamp to string of the form YYYY-MM-DD HH:MM:SS *)
let timestamp_to_string (timestamp : Unix.tm) =
  Printf.sprintf
    "%04d-%02d-%02d %02d:%02d:%02d"
    (timestamp.tm_year + 1900)
    (timestamp.tm_mon + 1)
    timestamp.tm_mday
    timestamp.tm_hour
    timestamp.tm_min
    timestamp.tm_sec
;;

let _log_inner level msg lwt =
  let color =
    match level with
    | ERROR -> red
    | WARN -> yellow
    | INFO -> cyan
    | DEBUG -> purple
  in
  let timestamp = timestamp_to_string (get_timestamp ()) in
  let formatted_msg =
    Printf.sprintf "%s%s [%s]:%s %s" color timestamp (level_to_string level) reset msg
  in
  match level, lwt with
  | ERROR, true -> Lwt_io.eprintl formatted_msg
  | ERROR, false ->
    Stdio.prerr_endline formatted_msg;
    Lwt.return_unit
  | _, true -> Lwt_io.printl formatted_msg
  | _, false ->
    Stdio.print_endline formatted_msg;
    Lwt.return_unit
;;

let info msg = if should_log INFO then Lwt.ignore_result (_log_inner INFO msg false)
let debug msg = if should_log DEBUG then Lwt.ignore_result (_log_inner DEBUG msg false)
let error msg = if should_log ERROR then Lwt.ignore_result (_log_inner ERROR msg false)
let warn msg = if should_log WARN then Lwt.ignore_result (_log_inner WARN msg false)
let info_lwt msg = if should_log INFO then _log_inner INFO msg true else Lwt.return_unit

let debug_lwt msg =
  if should_log DEBUG then _log_inner DEBUG msg true else Lwt.return_unit
;;

let error_lwt msg =
  if should_log ERROR then _log_inner ERROR msg true else Lwt.return_unit
;;

let warn_lwt msg = if should_log WARN then _log_inner WARN msg true else Lwt.return_unit

let infof fmt =
  Printf.ksprintf
    (fun msg -> if should_log INFO then Lwt.ignore_result (_log_inner INFO msg false))
    fmt
;;

let debugf fmt =
  Printf.ksprintf
    (fun msg -> if should_log DEBUG then Lwt.ignore_result (_log_inner DEBUG msg false))
    fmt
;;

let errorf fmt =
  Printf.ksprintf
    (fun msg -> if should_log ERROR then Lwt.ignore_result (_log_inner ERROR msg false))
    fmt
;;

let warnf fmt =
  Printf.ksprintf
    (fun msg -> if should_log WARN then Lwt.ignore_result (_log_inner WARN msg false))
    fmt
;;

(* Lwt versions *)
let infof_lwt fmt =
  Printf.ksprintf
    (fun msg -> if should_log INFO then _log_inner INFO msg true else Lwt.return_unit)
    fmt
;;

let debugf_lwt fmt =
  Printf.ksprintf
    (fun msg -> if should_log DEBUG then _log_inner DEBUG msg true else Lwt.return_unit)
    fmt
;;

let errorf_lwt fmt =
  Printf.ksprintf
    (fun msg -> if should_log ERROR then _log_inner ERROR msg true else Lwt.return_unit)
    fmt
;;

let warnf_lwt fmt =
  Printf.ksprintf
    (fun msg -> if should_log WARN then _log_inner WARN msg true else Lwt.return_unit)
    fmt
;;
