(lang dune 3.16)

(name spice)

(generate_opam_files true)

(source
 (github max-legrand/spice))

(authors "Maxwell Legrand")

(maintainers "Maxwell Legrand")

(license MIT)

(package
 (name spice)
 (synopsis "Small OCaml Logging tool")
 (description "A small and lightweight OCaml logging tool. This is tailored around my personal preferences.")
 (depends ocaml dune lwt stdio base core_unix)
 (tags
  (topics "logging")))
