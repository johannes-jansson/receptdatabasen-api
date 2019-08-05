module Page.Recipe.Editor exposing (Model, Msg, initEdit, initNew, toSession, update, view)

import Array exposing (Array)
import Browser.Navigation as Nav
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (class, for, id, min, placeholder, style, type_, value)
import Html.Events exposing (keyCode, onInput, onSubmit, preventDefaultOn)
import Http exposing (Expect)
import Json.Decode as Decode exposing (Decoder)
import Json.Encode as Encode
import Recipe exposing (Full, Recipe, fullDecoder)
import Recipe.Slug as Slug exposing (Slug)
import Route
import Session exposing (Session)
import Set exposing (Set)
import Task
import Url
import Url.Builder



-- MODEL


type alias Model =
    { session : Session
    , status : Status
    }


type Status
    = -- New Recipe
      EditingNew (List Problem) Form
    | Creating Form
      -- Edit Recipe
    | Loading Slug
    | LoadingFailed Slug
    | Editing Slug (List Problem) Form
    | Saving Slug Form


type Problem
    = InvalidEntry ValidatedField String
    | ServerError String


type alias Form =
    { title : String
    , description : String
    , instructions : String
    , quantity : Int
    , tags : Set String
    , currentTag : String
    , currentIngredient : String
    , ingredients : Array String
    }


initNew : Session -> ( Model, Cmd msg )
initNew session =
    ( { session = session
      , status =
            EditingNew []
                { title = ""
                , description = ""
                , instructions = ""
                , quantity = 1
                , tags = Set.empty
                , currentTag = ""
                , currentIngredient = ""
                , ingredients = Array.empty
                }
      }
    , Cmd.none
    )


initEdit : Session -> Slug -> ( Model, Cmd Msg )
initEdit session slug =
    ( { session = session
      , status = Loading slug
      }
    , fetchRecipe slug
    )


fetchUrl : Slug -> String
fetchUrl slug =
    Url.Builder.crossOrigin "http://localhost:3000" [ "recipes" ] [ Url.Builder.string "title" "eq." ]


fetchRecipe : Slug -> Cmd Msg
fetchRecipe slug =
    Http.request
        { url = fetchUrl slug ++ Slug.toString slug
        , method = "GET"
        , timeout = Nothing
        , tracker = Nothing
        , headers = [ Http.header "Accept" "application/vnd.pgrst.object+json" ]
        , body = Http.emptyBody
        , expect = Http.expectJson CompletedRecipeLoad Recipe.fullDecoder
        }



-- VIEW


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "New Recipe"
    , content =
        case model.status of
            -- Creating a new recipe
            EditingNew probs form ->
                div [] [ viewForm form, viewProblems probs ]

            Creating form ->
                viewForm form

            -- Editing an exisiting recipe
            Loading slug ->
                text "Loading"

            LoadingFailed slug ->
                text ("Failed to load" ++ Slug.toString slug)

            Editing slug probs form ->
                div [] [ viewForm form, viewProblems probs ]

            Saving slug form ->
                viewForm form
    }


viewForm : Form -> Html Msg
viewForm fields =
    form [ onSubmit ClickedSave ]
        [ viewTitleInput fields
        , viewDescriptionInput fields
        , viewQuantityInput fields
        , viewTagsInput fields
        , viewIngredientsInput fields
        , viewInstructionsInput fields
        , button []
            [ text "Save" ]
        ]


viewInstructionsInput : Form -> Html Msg
viewInstructionsInput fields =
    div [ class "instructions" ]
        [ h3 [] [ text "Instructions" ]
        , textarea
            [ placeholder "Instruktioner"
            , onInput EnteredInstructions
            , value fields.instructions
            ]
            []
        ]


viewIngredientsInput : Form -> Html Msg
viewIngredientsInput fields =
    div [ class "ingredients" ]
        [ h3 [] [ text "Ingredients" ]
        , input
            [ placeholder "Ingredienser"
            , onEnter PressedEnterIngredient
            , onInput EnteredCurrentIngredient
            , value fields.currentIngredient
            ]
            []
        , ul [] (List.map viewIngredient <| Array.toIndexedList fields.ingredients)
        ]


viewProblems : List Problem -> Html Msg
viewProblems problems =
    ul [ class "error-messages" ] (List.map viewProblem problems)


viewProblem : Problem -> Html msg
viewProblem problem =
    let
        errorMessage =
            case problem of
                InvalidEntry _ message ->
                    message

                ServerError message ->
                    message
    in
    li [] [ code [ style "background-color" "red", style "color" "white" ] [ text errorMessage ] ]


viewTagsInput : Form -> Html Msg
viewTagsInput fields =
    div [ class "tags" ]
        [ input
            [ placeholder "Tags"
            , onEnter PressedEnterTag
            , onInput EnteredCurrentTag
            , value fields.currentTag
            ]
            []
        , ul []
            (List.map viewTag <| Set.toList fields.tags)
        ]


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Decode.succeed ( msg, True )

            else
                Decode.fail "not ENTER"
    in
    preventDefaultOn "keydown" (Decode.andThen isEnter keyCode)


viewTag : String -> Html Msg
viewTag tag =
    li [] [ text tag ]


viewIngredient : ( Int, String ) -> Html Msg
viewIngredient ( idx, ingredient ) =
    li []
        [ input
            [ value ingredient
            , onInput (EnteredIngredient idx)
            ]
            []
        ]


viewDescriptionInput : Form -> Html Msg
viewDescriptionInput fields =
    div [ class "description" ]
        [ textarea
            [ placeholder "Description"
            , onInput EnteredDescription
            , value fields.description
            ]
            []
        ]


viewTitleInput : Form -> Html Msg
viewTitleInput fields =
    div [ class "title" ]
        [ input
            [ placeholder "Recipe Title"
            , onInput EnteredTitle
            , value fields.title
            ]
            []
        ]


viewQuantityInput : Form -> Html Msg
viewQuantityInput fields =
    div [ class "quantity" ]
        [ label [ for "quantity-input" ] [ text "Enter quantity" ]
        , input
            [ id "quantity"
            , placeholder "Quantity"
            , type_ "number"
            , onInput EnteredQuantity
            , value (String.fromInt fields.quantity)
            , min "1"
            ]
            []
        ]



-- UPDATE


type Msg
    = ClickedSave
    | EnteredTitle String
    | EnteredDescription String
    | EnteredInstructions String
    | EnteredQuantity String
    | EnteredCurrentTag String
    | EnteredCurrentIngredient String
    | PressedEnterTag
    | PressedEnterIngredient
    | EnteredIngredient Int String
    | CompletedCreate (Result MyError (Recipe Full))
    | CompletedRecipeLoad (Result Http.Error (Recipe Full))
    | CompletedEdit (Result Http.Error (Recipe Full))


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ClickedSave ->
            model.status
                |> save
                |> Tuple.mapFirst (\status -> { model | status = status })

        EnteredTitle title ->
            updateForm (\form -> { form | title = title }) model

        EnteredDescription description ->
            updateForm (\form -> { form | description = description }) model

        EnteredInstructions instructions ->
            updateForm (\form -> { form | instructions = instructions }) model

        EnteredQuantity quantity ->
            let
                quantityInt =
                    Maybe.withDefault 0 <| String.toInt quantity
            in
            updateForm (\form -> { form | quantity = quantityInt }) model

        EnteredCurrentTag currentTag ->
            updateForm (\form -> { form | currentTag = currentTag }) model

        PressedEnterTag ->
            updateForm
                (\form ->
                    { form
                        | tags = Set.insert form.currentTag form.tags
                        , currentTag = ""
                    }
                )
                model

        EnteredCurrentIngredient currentIngredient ->
            updateForm (\form -> { form | currentIngredient = currentIngredient }) model

        PressedEnterIngredient ->
            updateForm
                (\form ->
                    { form
                        | ingredients = Array.push form.currentIngredient form.ingredients
                        , currentIngredient = ""
                    }
                )
                model

        EnteredIngredient idx ingredient ->
            updateForm (\form -> { form | ingredients = Array.set idx ingredient form.ingredients }) model

        CompletedCreate (Ok recipe) ->
            ( model
            , Route.Recipe (Recipe.slug recipe)
                |> Route.replaceUrl (Session.navKey model.session)
            )

        CompletedCreate (Err error) ->
            ( { model | status = savingError error model.status }
            , Cmd.none
            )

        CompletedRecipeLoad (Ok recipe) ->
            let
                { id, title } =
                    Recipe.metadata recipe

                { description, instructions, tags, quantity, ingredients } =
                    Recipe.contents recipe

                status =
                    Editing (Recipe.slug recipe)
                        []
                        { title = Slug.toString title
                        , description = description
                        , instructions = instructions
                        , quantity = quantity
                        , tags = Set.fromList tags
                        , currentTag = ""
                        , currentIngredient = ""
                        , ingredients = Array.empty -- TODO: fill in ingredients from recipe
                        }
            in
            ( { model | status = status }, Cmd.none )

        CompletedRecipeLoad (Err error) ->
            Debug.todo "completedRecipeLoad isn't impleted"

        CompletedEdit (Ok recipe) ->
            ( model
            , Route.Recipe (Recipe.slug recipe)
                |> Route.replaceUrl (Session.navKey model.session)
            )

        CompletedEdit (Err error) ->
            Debug.todo "CompletedEdit not yet implemented"


save : Status -> ( Status, Cmd Msg )
save status =
    case status of
        EditingNew _ form ->
            ( Creating form, create form )

        _ ->
            ( status, Cmd.none )


savingError : MyError -> Status -> Status
savingError error status =
    let
        problems =
            [ ServerError ("Error saving " ++ myErrorAsString error) ]
    in
    case status of
        Creating form ->
            EditingNew problems form

        _ ->
            status


myErrorAsString : MyError -> String
myErrorAsString error =
    case error of
        MyError (Http.BadUrl str) ->
            "BadUrl" ++ str

        MyError Http.NetworkError ->
            "NetworkError"

        MyErrorWithBody (Http.BadStatus status) body ->
            "BadStatus " ++ String.fromInt status ++ body

        MyError (Http.BadBody str) ->
            "BadBody: " ++ str

        MyError Http.Timeout ->
            "Timeout"

        _ ->
            ""


url : String
url =
    Url.Builder.crossOrigin "http://localhost:3000" [ "recipes" ] []


create : Form -> Cmd Msg
create form =
    let
        quantityString =
            String.fromInt form.quantity

        ingredientDict =
            Dict.fromList [ ( "ingredients", Array.toList form.ingredients ) ]

        recipe =
            Encode.object
                [ ( "title", Encode.string form.title )
                , ( "description", Encode.string form.description )
                , ( "instructions", Encode.string form.instructions )
                , ( "quantity", Encode.string quantityString )
                , ( "tags", Encode.set Encode.string form.tags )
                , ( "ingredients", Encode.dict identity (Encode.list Encode.string) ingredientDict )
                ]

        body =
            Http.jsonBody recipe
    in
    Http.request
        { url = url
        , method = "POST"
        , timeout = Nothing
        , tracker = Nothing
        , headers = [ Http.header "Prefer" "return=representation", Http.header "Accept" "application/vnd.pgrst.object+json" ]
        , body = body
        , expect = expectJson CompletedCreate Recipe.fullDecoder
        }


type MyError
    = MyError Http.Error
    | MyErrorWithBody Http.Error String


expectJson : (Result MyError a -> Msg) -> Decoder a -> Expect Msg
expectJson toMsg decoder =
    Http.expectStringResponse toMsg <|
        \response ->
            case response of
                Http.BadUrl_ urll ->
                    Err (MyError (Http.BadUrl urll))

                Http.Timeout_ ->
                    Err (MyError Http.Timeout)

                Http.NetworkError_ ->
                    Err (MyError Http.NetworkError)

                Http.BadStatus_ metadata body ->
                    Err (MyErrorWithBody (Http.BadStatus metadata.statusCode) body)

                Http.GoodStatus_ metadata body ->
                    case Decode.decodeString decoder body of
                        Ok value ->
                            Ok value

                        Err err ->
                            -- TODO: Http.BadBody is quite misleading - the decoding failed, not the request...
                            Err (MyError (Http.BadBody (Decode.errorToString err)))


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm transform model =
    let
        newModel =
            case model.status of
                Loading _ ->
                    model

                LoadingFailed _ ->
                    model

                Saving slug form ->
                    { model | status = Saving slug (transform form) }

                Editing slug errors form ->
                    { model | status = Editing slug errors (transform form) }

                EditingNew errors form ->
                    { model | status = EditingNew errors (transform form) }

                Creating form ->
                    { model | status = Creating (transform form) }
    in
    ( newModel, Cmd.none )


type TrimmedForm
    = Trimmed Form


type ValidatedField
    = Title
    | Body


toSession : Model -> Session
toSession model =
    model.session
