module Result = Bos_setup.R
open Result.Infix

type entry = {
  id : Odoc_model.Paths.Identifier.Any.t;
  doc : Odoc_model.Comment.docs option;
}

module Generate = struct
  (** Get plain text doc-comment from a doc comment *)

  let get_value x = x.Odoc_model.Location_.value

  let rec string_of_doc (doc : Odoc_model.Comment.docs) =
    doc |> List.map get_value
    |> List.map s_of_block_element
    |> String.concat " "

  and s_of_block_element (be : Odoc_model.Comment.block_element) =
    match be with
    | `Paragraph is -> inlines is
    | `Tag _ -> ""
    | `List (_, ls) ->
        List.map (fun x -> x |> List.map get_value |> List.map nestable) ls
        |> List.concat |> String.concat " "
    | `Heading (_, _, h) -> content h
    | `Modules _ -> ""
    | `Code_block (_, s, _) -> s |> get_value
    | `Verbatim v -> v
    | `Math_block m -> m
    | `Table _t -> failwith "TODO"

  and nestable (n : Odoc_model.Comment.nestable_block_element) =
    s_of_block_element (n :> Odoc_model.Comment.block_element)

  and inlines is =
    is |> List.map get_value |> List.map inline |> String.concat ""

  and inline (i : Odoc_model.Comment.inline_element) =
    match i with
    | `Code_span s -> s
    | `Word w -> w
    | `Math_span m -> m
    | `Space -> " "
    | `Reference (_, c) -> link_content c
    | `Link (_, c) -> link_content c
    | `Styled (_, b) -> inlines b
    | `Raw_markup (_, _) -> ""

  and link_content l =
    l |> List.map get_value
    |> List.map non_link_inline_element
    |> String.concat ""

  and content l =
    l |> List.map get_value
    |> List.map inline
    |> String.concat ""

    and non_link_inline_element (n : Odoc_model.Comment.non_link_inline_element) =
    inline (n :> Odoc_model.Comment.inline_element)

  let prefixname :
      [< Odoc_model.Paths.Identifier.t_pv ] Odoc_model.Paths.Identifier.id ->
      string =
   fun n ->
    match (n :> Odoc_model.Paths.Identifier.t) |> Odoc_model.Paths.Identifier.fullname |> List.rev with
    | [] -> ""
    | _ :: q -> String.concat "." (List.rev q)

  let string_of_entry { id; doc } =
    Odoc_document.Url.from_identifier ~stop_before:false id >>= fun url ->
    let config =
      Odoc_html.Config.v ~semantic_uris:true ~indent:false ~flat:false
        ~open_details:false ~as_json:false ()
    in
    let name = Odoc_model.Paths.Identifier.name id in
    let prefixname = prefixname id in
    let kind =
      match id.iv with
      | `InstanceVariable _ -> "instance variable"
      | `Parameter _ -> "parameter"
      | `Module _ -> "module"
      | `ModuleType _ -> "module type"
      | `Method _ -> "method"
      | `Field _ -> "field"
      | `Result _ -> "result"
      | `Label _ -> "label"
      | `Type _ -> "type"
      | `Exception _ -> "exception"
      | `Class _ -> "class"
      | `Page _ -> "page"
      | `LeafPage _ -> "leaf page"
      | `CoreType _ -> "core type"
      | `ClassType _ -> "class type"
      | `Value _ -> "val"
      | `CoreException _ -> "core exception"
      | `Constructor _ -> "constructor"
      | `Extension _ -> "extension"
      | `Root _ -> "root"
      | `SourceDir _ -> "source dir"
      |`AssetFile _ -> "asset file" |`SourceLocationMod _-> "source location mod" |`SourceLocation _-> "source location"|
`SourcePage _-> "source page"|`ExtensionDecl _-> "extension decl"|`SourceLocationInternal _-> "source location internal"
    in
    let url = Odoc_html.Link.href ~config ~resolve:(Base "") url in
    let json =
      `Assoc
        [
          ("name", `String name);
          ("prefixname", `String prefixname);
          ("kind", `String kind);
          ("url", `String url);
          ( "comment",
            match doc with None -> `Null | Some c -> `String (string_of_doc c)
          );
        ]
    in
    Ok (Yojson.to_string json)
end

module Load_doc = struct
  open Odoc_model.Paths
  open Odoc_model.Lang

  let add t ppf =
    if Identifier.is_internal t.id then ()
    else
      match Generate.string_of_entry t with
      | Ok entry -> Format.fprintf ppf "%s,\n" entry
      | Error _ -> ()

  let rec unit ppf t =
    let open Compilation_unit in
    let () = content ppf t.content in
    add { id = (t.id :> Identifier.Any.t); doc = None } ppf

  and content ppf =
    let open Compilation_unit in
    function
    | Module m ->
        let () = signature ppf m in
        ()
    | Pack _ -> ()

  and signature ppf (s : Signature.t) = List.iter (signature_item ppf) s.items

  and signature_item ppf s_item =
    match s_item with
    | Signature.Module (_, m) -> module_ ppf m
    | ModuleType mt -> module_type ppf mt
    | ModuleSubstitution mod_subst -> module_subst ppf mod_subst
    | ModuleTypeSubstitution mt_subst -> module_type_subst ppf mt_subst
    | Open _ -> ()
    | Type (_, t_decl) -> type_decl ppf t_decl
    | TypeSubstitution t_decl -> type_decl ppf t_decl
    | TypExt te -> type_extension ppf te
    | Exception exc -> exception_ ppf exc
    | Value v -> value ppf v
    | Class (_, cl) -> class_ ppf cl
    | ClassType (_, clt) -> class_type ppf clt
    | Include i -> include_ ppf i
    | Comment _ -> ()

  and include_ ppf inc =
    let () = include_decl ppf inc.decl in
    include_expansion ppf inc.expansion

  and include_decl _ppf _decl = ()
  and include_expansion ppf expansion = signature ppf expansion.content

  and class_type ppf ct =
    let () = add { id = (ct.id :> Identifier.Any.t); doc = Some ct.doc } ppf in
    let () = class_type_expr ppf ct.expr in
    match ct.expansion with None -> () | Some cs -> class_signature ppf cs

  and class_type_expr ppf ct_expr =
    match ct_expr with
    | ClassType.Constr (_, _) -> ()
    | ClassType.Signature cs -> class_signature ppf cs

  and class_signature ppf ct_expr =
    List.iter (class_signature_item ppf) ct_expr.items

  and class_signature_item ppf item =
    match item with
    | ClassSignature.Method m ->
        add { id = (m.id :> Identifier.Any.t); doc = Some m.doc } ppf
    | ClassSignature.InstanceVariable _ -> ()
    | ClassSignature.Constraint _ -> ()
    | ClassSignature.Inherit _ -> ()
    | ClassSignature.Comment _ -> ()

  and class_ ppf cl =
    let () = add { id = (cl.id :> Identifier.Any.t); doc = Some cl.doc } ppf in
    let () = class_decl ppf cl.type_ in
    match cl.expansion with
    | None -> ()
    | Some cl_signature -> class_signature ppf cl_signature

  and class_decl ppf cl_decl =
    match cl_decl with
    | Class.ClassType expr -> class_type_expr ppf expr
    | Class.Arrow (_, _, decl) -> class_decl ppf decl

  and exception_ ppf exc =
    add { id = (exc.id :> Identifier.Any.t); doc = Some exc.doc } ppf

  and type_extension ppf te =
    match te.constructors with
    | [] -> ()
    | c :: _ ->
        let () =
          add { id = (c.id :> Identifier.Any.t); doc = Some te.doc } ppf
        in
        List.iter (extension_constructor ppf) te.constructors

  and extension_constructor ppf ext_constr =
    add
      { id = (ext_constr.id :> Identifier.Any.t); doc = Some ext_constr.doc }
      ppf

  and module_subst _ppf _mod_subst = ()
  and module_type_subst _ppf _mod_subst = ()

  and value ppf v =
    add { id = (v.id :> Identifier.Any.t); doc = Some v.doc } ppf

  and module_ ppf m =
    let () = add { id = (m.id :> Identifier.Any.t); doc = Some m.doc } ppf in
    let () =
      match m.type_ with
      | Module.Alias (_, None) -> ()
      | Module.Alias (_, Some s_e) -> simple_expansion ppf s_e
      | Module.ModuleType mte -> module_type_expr ppf mte
    in
    ()

  and type_decl ppf td =
    add { id = (td.id :> Identifier.Any.t); doc = Some td.doc } ppf

  and module_type ppf mt =
    let () = add { id = (mt.id :> Identifier.Any.t); doc = Some mt.doc } ppf in
    match mt.expr with
    | None -> ()
    | Some mt_expr -> module_type_expr ppf mt_expr

  and simple_expansion ppf s_e =
    match s_e with
    | ModuleType.Signature sg -> signature ppf sg
    | Functor (param, s_e) ->
        let () = functor_parameter ppf param in
        simple_expansion ppf s_e

  and module_type_expr ppf mte =
    match mte with
    | ModuleType.Path _ -> ()
    | ModuleType.Signature s -> signature ppf s
    | ModuleType.Functor (fp, mt_expr) ->
        let () = functor_parameter ppf fp in
        let () = module_type_expr ppf mt_expr in
        ()
    | ModuleType.With { w_expansion = None; _ } -> ()
    | ModuleType.With { w_expansion = Some se; _ } -> simple_expansion ppf se
    | ModuleType.TypeOf { t_expansion = None; _ } -> ()
    | ModuleType.TypeOf { t_expansion = Some se; _ } -> simple_expansion ppf se

  and functor_parameter ppf fp =
    match fp with
    | FunctorParameter.Unit -> ()
    | FunctorParameter.Named n -> module_type_expr ppf n.expr
end

let load_dir path =
  Odoc_odoc.Fs.Directory.fold_files_rec_result ~ext:"odocl"
    (fun acc file ->
      Odoc_odoc.Odoc_file.load file >>= fun unit -> Ok (unit :: acc))
    [] path

let generate_index dirs output =
  dirs
  |> List.fold_left
       (fun acc dir ->
         acc >>= fun acc ->
         load_dir dir >>= fun units -> Ok (units @ acc))
       (Ok [])
  >>= fun units ->
  let units =
    List.filter_map
      (function
        | { Odoc_odoc.Odoc_file.content = Unit_content unit; _ }
          when not unit.hidden ->
            Some unit
        | _ -> None)
      units
  in
  let ppf =
    Odoc_odoc.Fs.Directory.mkdir_p (Odoc_odoc.Fs.File.dirname output);
    let oc = open_out_bin (Odoc_odoc.Fs.File.to_string output) in
    Format.formatter_of_out_channel oc
  in
  Format.fprintf ppf "let documents = [";
  let () = List.iter (Load_doc.unit ppf) units in
  let () =
    Format.fprintf ppf
      {|];
const options = { keys: ['name', 'comment'] };
var idx_fuse = new Fuse(documents, options);|}
  in
  Ok ()
