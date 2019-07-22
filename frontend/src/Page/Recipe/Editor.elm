module Page.Recipe.Editor exposing (Model, Msg, initNew, toSession, update, view)

import Browser exposing (Document)
import Dict exposing (Dict)
import Html exposing (..)
import Html.Attributes exposing (class, for, id, min, placeholder, type_, value)
import Html.Events exposing (keyCode, on, onInput, onSubmit)
import Http
import Json.Decode as Decode
import Json.Encode as Encode
import Recipe exposing (Full, Recipe, fullDecoder)
import Session exposing (Session)
import Set exposing (Set)
import Url
import Url.Builder



-- MODEL


type alias Model =
    { session : Session
    , status : Status
    }


type Status
    = -- New Article
      EditingNew (List Problem) Form
    | Creating Form


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

    -- , ingredients : Dict String (List String)
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
                }
      }
    , Cmd.none
    )



-- VIEW


view : Model -> Document Msg
view model =
    { title = "New Recipe"
    , body =
        [ case model.status of
            EditingNew probs form ->
                viewForm form

            Creating form ->
                viewForm form
        ]
    }


viewForm : Form -> Html Msg
viewForm fields =
    form [ onSubmit ClickedSave ]
        [ viewTitleInput fields
        , viewDescriptionInput fields
        , viewQuantityInput fields
        , viewTagsInput fields
        , button []
            [ text "Save" ]
        ]


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
                Decode.succeed msg

            else
                Decode.fail "not ENTER"
    in
    on "keydown" (Decode.andThen isEnter keyCode)


viewTag : String -> Html Msg
viewTag tag =
    li [] [ text tag ]


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
    | PressedEnterTag
    | CompletedCreate (Result Http.Error (List (Recipe Full)))


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

        CompletedCreate (Ok recipes) ->
            updateForm (\form -> { form | title = "saved" }) model

        CompletedCreate (Err error) ->
            updateForm (\form -> { form | title = "error" }) model


save : Status -> ( Status, Cmd Msg )
save status =
    case status of
        EditingNew _ form ->
            ( Creating form, create form )

        _ ->
            ( status, Cmd.none )


url : String
url =
    Url.Builder.crossOrigin "http://localhost:3000" [ "recipes" ] []


create : Form -> Cmd Msg
create form =
    let
        quantityString =
            String.fromInt form.quantity

        recipe =
            Encode.object
                [ ( "title", Encode.string form.title )
                , ( "description", Encode.string form.description )
                , ( "instructions", Encode.string form.instructions )
                , ( "quantity", Encode.string quantityString )
                ]

        body =
            Http.jsonBody recipe
    in
    Http.post
        { url = url
        , body = body
        , expect = Http.expectJson CompletedCreate Recipe.fullDecoder
        }


updateForm : (Form -> Form) -> Model -> ( Model, Cmd Msg )
updateForm transform model =
    let
        newModel =
            case model.status of
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
