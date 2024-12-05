(lang dune 3.16)

(name spice)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Maxwell Legrand")

(maintainers "Maxwell Legrand")

(license MIT)

(package
 (name spice)
 (synopsis "Small OCaml Logging tool")
 (description "A small and lightweight OCaml logging tool. This is tailored around my personal preferences.")
 (depends ocaml dune)
 (tags
  (topics "logging")
