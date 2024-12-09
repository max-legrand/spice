open Base
open Core_unix

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

type output_target =
  | Stdout
  | Stderr
  | File of string
  | Multiple of output_target list

(** Global configuration *)
type config =
  { mutable log_level : level
  ; mutable output : output_target
  }

let config = { log_level = INFO; output = Stdout }
let set_log_level level = config.log_level <- level
let set_output target = config.output <- target
let exists fp = access fp [ `Exists ]

let ensure_file_exists filename =
  match exists filename with
  | Ok () -> ()
  | Error _ ->
    (* Create an out_channel for the file *)
    let out_channel = Out_channel.open_text filename in
    Out_channel.output_string out_channel ""
;;

let append_to_file filename msg =
  let channel = Out_channel.open_text filename in
  Out_channel.output_string channel (msg ^ "\n");
  Out_channel.close channel
;;

let append_to_file_lwt filename msg =
  Lwt_io.with_file ~mode:Lwt_io.Output filename (fun channel ->
    Lwt_io.write_line channel msg)
;;

let should_log msg_level =
  match config.log_level, msg_level with
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
  let colored_msg =
    Printf.sprintf "%s%s [%s]:%s %s" color timestamp (level_to_string level) reset msg
  in
  let plain_msg = Printf.sprintf "%s [%s]: %s" timestamp (level_to_string level) msg in
  let rec write_to_target target =
    match target, lwt with
    | Stdout, true -> Lwt_io.printl colored_msg
    | Stdout, false ->
      Stdio.print_endline plain_msg;
      Lwt.return_unit
    | Stderr, true -> Lwt_io.eprintl colored_msg
    | Stderr, false ->
      Stdio.prerr_endline plain_msg;
      Lwt.return_unit
    | File filename, true ->
      ensure_file_exists filename;
      append_to_file_lwt filename plain_msg
    | File filename, false ->
      ensure_file_exists filename;
      append_to_file filename plain_msg;
      Lwt.return_unit
    | Multiple targets, _ -> Lwt_list.iter_s write_to_target targets
  in
  write_to_target config.output
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
