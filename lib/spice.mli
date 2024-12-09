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

val set_log_level : level -> unit
val set_output : output_target -> unit
val info : string -> unit
val debug : string -> unit
val error : string -> unit
val warn : string -> unit
val info_lwt : string -> unit Lwt.t
val debug_lwt : string -> unit Lwt.t
val error_lwt : string -> unit Lwt.t
val warn_lwt : string -> unit Lwt.t
val infof : ('a, unit, string, unit) format4 -> 'a
val debugf : ('a, unit, string, unit) format4 -> 'a
val errorf : ('a, unit, string, unit) format4 -> 'a
val warnf : ('a, unit, string, unit) format4 -> 'a
val infof_lwt : ('a, unit, string, unit Lwt.t) format4 -> 'a
val debugf_lwt : ('a, unit, string, unit Lwt.t) format4 -> 'a
val errorf_lwt : ('a, unit, string, unit Lwt.t) format4 -> 'a
val warnf_lwt : ('a, unit, string, unit Lwt.t) format4 -> 'a
