type level =
  | ERROR
  | WARN
  | INFO
  | DEBUG

val set_log_level : level -> unit
val info : string -> unit
val debug : string -> unit
val error : string -> unit
val warn : string -> unit
val info_lwt : string -> unit Lwt.t
val debug_lwt : string -> unit Lwt.t
val error_lwt : string -> unit Lwt.t
val warn_lwt : string -> unit Lwt.t
