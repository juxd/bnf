open Core


(* module FirstSet = Set.Make (Types.first_set) *)

let find_production (assignments: Types.assignment list) (non_terminal: Types.non_terminal) =
  List.find_exn assignments ~f:(fun assignment -> String.(=) assignment.lhs non_terminal)

let epsilon_only_set = Types.FirstSet.add Types.FirstSet.empty Epsilon

let rec generate_first_set_assignment (assignments: Types.assignment list) (assignment: Types.assignment) =
  let rhs = assignment.rhs in
  generate_first_set_or_expr assignments rhs

and

generate_first_set_expr (assignments: Types.assignment list) (expr: Types.expr) =
  generate_first_set_or_expr assignments expr

and

generate_first_set_or_expr (assignments: Types.assignment list) (or_expr: Types.or_expr) =
  match or_expr with
    | OR_EXPR(sequential_expr, or_expr) ->
      let seq_first_set = generate_first_set_seq_expr assignments sequential_expr in
      let or_first_set = generate_first_set_or_expr assignments or_expr in
      Types.FirstSet.union (seq_first_set) (or_first_set)
    | OR_EXPR_BASE(sequential_expr) ->
      let seq_first_set = generate_first_set_seq_expr assignments sequential_expr in
      seq_first_set

and

generate_first_set_seq_expr (assignments: Types.assignment list) (seq_expr: Types.sequential_expr) =
  match seq_expr with
    | SEQUENTIAL_EXPR(primary_expr, sequential_expr) ->
      let primary_first_set = generate_first_set_primary_expr assignments primary_expr in
      if Types.FirstSet.equal epsilon_only_set primary_first_set then
        generate_first_set_seq_expr assignments sequential_expr
      else
        primary_first_set
    | SEQUENTIAL_EXPR_BASE(primary_expr) ->
      let primary_first_set = generate_first_set_primary_expr assignments primary_expr in
      primary_first_set

and

generate_first_set_primary_expr (assignments: Types.assignment list) (primary_expr: Types.primary_expr) =
  match primary_expr with
    | PRIMARY_EXPR(term) -> generate_first_set_term assignments term
    | PRIMARY_PARENTHESIZED_EXPR(expr) -> generate_first_set_expr assignments expr

and

generate_first_set_term (assignments: Types.assignment list) (term: Types.term) = match term with
  | NonTerminal(non_terminal) ->
    let production = find_production assignments non_terminal in
    generate_first_set_assignment assignments production
  | Terminal(terminal) ->
    Types.FirstSet.add Types.FirstSet.empty (Terminal terminal)
  | Epsilon -> epsilon_only_set
