Install the package

  $ PKG=can-render-org-files
  $ opam install packages/$PKG --yes > /dev/null
  [NOTE] Package can-render-org-files is currently pinned to file:///home/emile/Projects/ocaml/voodoo/_build/.sandbox/335d37239ee7e474e575aabfaac3e457/default/test/packages/can-render-org-files (version 1.0).

Generate the can-render-org-files documentation

  $ voodoo-prep
  Warning: No universes have been specified: will generate dummy universes

  $ voodoo-do -p $PKG -b
  Got dune
  Found 0 mld pages and 1 other pages
  libraries: []
  compile command: odoc compile ./p.mld -o compile/page-p.odoc --child
                     page-"can-render-org-files"
  File "./p.mld", line 2, characters 12-32:
  Warning: Unknown reference qualifier 'can-render-org'.
  compile command: odoc compile ./can-render-org-files.mld -o
                     compile/p/page-can-render-org-files.odoc --package "p" -I
                     compile --child page-"1.0"
  File "./can-render-org-files.mld", line 2, characters 14-15:
  Warning: Child label is not allowed in the last component of a reference path.
  Suggestion: 'child-0' should be first.
  compile command: odoc compile ./1.0.mld -o
                     compile/p/can-render-org-files/page-1.0.odoc --package
                     "can-render-org-files" -I compile/p --child page-"doc"
  compile command: odoc compile ./doc.mld -o
                     compile/p/can-render-org-files/1.0/page-doc.odoc --package
                     "1.0" -I compile/p/can-render-org-files --child
                     page-"dummy"
  No children
  File "compile/p/can-render-org-files/1.0/page-doc.odoc":
  Warning: Failed to lookup child page dummy
  1 other files to copy
  dst: linked/p/can-render-org-files/1.0/doc/opam
  dst: linked/p/can-render-org-files/1.0/doc/README.org
  dest: linked/p/can-render-org-files/1.0/doc/README.org
  odoc html-generate --indent linked/p/can-render-org-files/1.0/page-doc.odocl -o html

  $ tree linked
  linked
  `-- p
      `-- can-render-org-files
          `-- 1.0
              |-- doc
              |   |-- README.org
              |   `-- opam
              |-- package.json
              `-- page-doc.odocl
  
  5 directories, 4 files

  $ voodoo-gen -n $PKG -o output
  0 other versions, 1 packages
  Found 1 files
  File : linked/p/can-render-org-files/1.0/page-doc.odocl
  File : output/"1.0"/doc/index.html.json
  Content: {"type":"documentation","uses_katex":false,"breadcrumbs":[{"name":"\"1.0\"","href":"../index.html","kind":"page"},{"name":"doc","href":"#","kind":"page"}],"toc":[],"source_anchor":null,"preamble":"<h1 id=\"can-render-org-files-1.0\"><a href=\"#can-render-org-files-1.0\" class=\"anchor\"></a>can-render-org-files 1.0</h1>","content":""}
  render_other: linked/p/can-render-org-files/1.0/doc/README.org
  render_org Ok
  File : output/"1.0"/README.org.html.json
  Content: {"type":"documentation","uses_katex":false,"breadcrumbs":[{"name":"\"1.0\"","href":"index.html","kind":"page"},{"name":"README.org","href":"#","kind":"leaf-page"}],"toc":[],"source_anchor":null,"preamble":"<h2>Title 1</h2>","content":"<h3>Title 2</h3>"}
  render_other: linked/p/can-render-org-files/1.0/package.json
  File : output/"1.0"/package.json.html.json
  Content: {"type":"documentation","uses_katex":false,"breadcrumbs":[{"name":"\"1.0\"","href":"index.html","kind":"page"},{"name":"package.json","href":"#","kind":"leaf-page"}],"toc":[],"source_anchor":null,"preamble":"<h2>package.json</h2>","content":"<pre>{&quot;libraries&quot;:[]}\u000A</pre>"}

Generates a status.json file
  $ cat output/p/$PKG/1.0/status.json | jq .
  {
    "failed": false,
    "otherdocs": {
      "readme": [
        "linked/p/can-render-org-files/1.0/doc/README.org"
      ],
      "license": [],
      "changes": [],
      "others": [
        "linked/p/can-render-org-files/1.0/package.json"
      ]
    }
  }

Converted the README.org file in HTML
  $ cat output/p/$PKG/1.0/doc/README.org.html.json | jq '.content'
  cat: output/p/can-render-org-files/1.0/doc/README.org.html.json: No such file or directory

  $ ls
  1.0.mld
  can-render-org-files.mld
  compile
  doc.mld
  html
  linked
  output
  p.mld
  packages
  prep
  $ tree html
  html
  `-- "1.0"
      `-- doc
          `-- index.html
  
  3 directories, 1 file
  $ tree linked
  linked
  `-- p
      `-- can-render-org-files
          `-- 1.0
              |-- doc
              |   |-- README.org
              |   `-- opam
              |-- package.json
              `-- page-doc.odocl
  
  5 directories, 4 files
  $ ls output/p/$PKG
  1.0
  $ tree output
  output
  |-- "1.0"
  |   |-- README.org.html.json
  |   |-- doc
  |   |   `-- index.html.json
  |   `-- package.json.html.json
  `-- p
      `-- can-render-org-files
          `-- 1.0
              |-- index.js
              |-- package.json
              `-- status.json
  
  6 directories, 6 files
  $ tree output/p/$PKG
  output/p/can-render-org-files
  `-- 1.0
      |-- index.js
      |-- package.json
      `-- status.json
  
  2 directories, 3 files

Uninstall the package
  $ opam remove $PKG --yes > /dev/null
