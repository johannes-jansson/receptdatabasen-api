module Page.RecipeList exposing (Model, Msg, Status, init, toSession, update, view)

import Browser.Dom as Dom
import Element
    exposing
        ( Element
        , centerX
        , centerY
        , column
        , el
        , fill
        , height
        , link
        , padding
        , paragraph
        , rgba255
        , row
        , spacing
        , text
        , width
        , wrappedRow
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Element.Region as Region
import FeatherIcons
import Html.Attributes
import Http
import Json.Decode as Decoder exposing (Decoder, list)
import Loading
import Page.Recipe.Markdown as Markdown
import Palette
import Recipe exposing (Preview, Recipe, previewDecoder)
import Recipe.Slug as Slug exposing (Slug)
import Route exposing (Route)
import Session exposing (Session)
import Task
import Url
import Url.Builder



-- MODEL


type alias Model =
    { session : Session, recipes : Status (List (Recipe Preview)), query : String }


type Status recipes
    = Loading
    | Loaded recipes
    | Failed Recipe.ServerError


init : Session -> Maybe String -> ( Model, Cmd Msg )
init session query =
    ( { session = session
      , recipes = Loading
      , query = Maybe.withDefault "" query
      }
    , case query of
        Nothing ->
            Recipe.fetchMany LoadedRecipes

        Just q ->
            search session q
    )



-- VIEW


view : Model -> { title : String, content : Element Msg }
view model =
    case model.recipes of
        Loading ->
            { title = "Recept"
            , content = Element.html Loading.animation
            }

        Failed err ->
            { title = "Kunde ej ladda in recept"
            , content =
                column [ Region.mainContent ]
                    [ Loading.error "Kunde ej ladda in recept" (Recipe.serverErrorToString err) ]
            }

        Loaded recipes ->
            { title = "Recept"
            , content =
                column [ Region.mainContent, spacing 20, width fill, padding 10 ]
                    [ viewSearchBox model
                    , wrappedRow [ centerX, spacing 10 ]
                        (List.map viewPreview recipes)
                    ]
            }


viewSearchBox : Model -> Element Msg
viewSearchBox model =
    let
        placeholder =
            Input.placeholder []
                (row []
                    [ FeatherIcons.search |> FeatherIcons.toHtml [] |> Element.html
                    , text " Sök recept..."
                    ]
                )
    in
    Input.search [ Input.focusedOnLoad ]
        { onChange = SearchQueryEntered
        , text = model.query
        , placeholder = Just placeholder
        , label = Input.labelHidden "sök recept"
        }


imageWidths : { min : Int, max : Int }
imageWidths =
    let
        iPadWidth =
            768

        pagePadding =
            10

        max =
            768 - pagePadding * 2
    in
    -- iPad width: 768 - page padding x 2 = 748 => one recipe will fill the width on an iPad at most
    -- minimum: max - 10 for the spacing between recipes x 1/2 for good proportions
    { max = max
    , min = floor ((max - pagePadding) / 2)
    }


viewPreview : Recipe Preview -> Element Msg
viewPreview recipe =
    let
        { title, description, id, createdAt, images } =
            Recipe.metadata recipe

        image =
            List.head images

        titleStr =
            Slug.toString title

        imageUrl =
            let
                width =
                    -- *2 for Retina TODO: optimise with responsive/progressive images
                    String.fromInt <| imageWidths.max * 2
            in
            image
                |> Maybe.map (\i -> "/images/sig/" ++ width ++ "/" ++ i)
    in
    column
        [ width (fill |> Element.maximum imageWidths.max |> Element.minimum imageWidths.min)
        , height <| Element.px 400
        , Palette.cardShadow1
        , Palette.cardShadow2
        , Border.rounded 2
        ]
        [ Element.link [ height fill, width fill ]
            { url = Route.toString (Route.Recipe title)
            , label =
                column [ height fill, width fill ]
                    [ viewHeader id titleStr imageUrl
                    , viewDescription description
                    ]
            }
        ]


viewHeader : Int -> String -> Maybe String -> Element Msg
viewHeader id title imageUrl =
    let
        background =
            imageUrl
                |> Maybe.map Background.image
                |> Maybe.withDefault (Background.color Palette.white)
    in
    column [ width fill, height fill, Border.rounded 2 ]
        [ Element.el
            [ width fill
            , height fill
            , Border.rounded 2
            , background
            ]
            (el
                [ Element.behindContent <|
                    el
                        [ width fill
                        , height fill
                        , floorFade
                        ]
                        Element.none
                , width fill
                , height fill
                ]
                (column [ Element.alignBottom ]
                    [ paragraph
                        [ Font.medium
                        , Font.color Palette.white
                        , Palette.textShadow
                        , Font.size Palette.medium
                        , padding 20
                        ]
                        [ text title ]
                    ]
                )
            )
        ]


floorFade : Element.Attribute msg
floorFade =
    Background.gradient
        { angle = pi -- down
        , steps =
            [ rgba255 0 0 0 0
            , rgba255 0 0 0 0.2
            ]
        }


takeWordsUntilCharLimit : Int -> List String -> List String
takeWordsUntilCharLimit limit words =
    let
        f : String -> List String -> List String
        f w ws =
            if (String.join " " >> String.length) (List.append ws [ w ]) < limit then
                List.append ws [ w ]

            else
                ws
    in
    List.foldl f [] words


shorten : Int -> String -> String
shorten limit str =
    let
        append x y =
            -- String.append is weird, so need to switch args
            y ++ x
    in
    if String.length str <= limit then
        str

    else
        takeWordsUntilCharLimit limit (str |> String.trim |> String.words)
            |> String.join " "
            |> append "..."


viewDescription : Maybe String -> Element Msg
viewDescription description =
    Maybe.withDefault Element.none <|
        Maybe.map
            (shorten 147
                >> text
                >> el
                    [ Font.hairline
                    , Font.color Palette.nearBlack
                    , Element.htmlAttribute <| Html.Attributes.style "overflow-wrap" "anywhere"
                    ]
                >> List.singleton
                >> paragraph [ padding 20, Element.alignBottom ]
            )
            description



-- UPDATE


type Msg
    = LoadedRecipes (Result Recipe.ServerError (List (Recipe Preview)))
    | SearchQueryEntered String
    | SetViewport


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LoadedRecipes (Ok recipes) ->
            let
                setViewportFromSession session =
                    Session.viewport session
                        |> Maybe.map
                            (\{ viewport } ->
                                [ Task.perform (\_ -> SetViewport) (Dom.setViewport viewport.x viewport.y) ]
                            )
                        |> Maybe.withDefault []
                        |> Cmd.batch
            in
            ( { model | recipes = Loaded recipes }, setViewportFromSession model.session )

        LoadedRecipes (Err error) ->
            ( { model | recipes = Failed error }, Cmd.none )

        SearchQueryEntered "" ->
            ( { model | query = "" }, Recipe.fetchMany LoadedRecipes )

        SearchQueryEntered query ->
            ( { model | query = query }, search model.session query )

        SetViewport ->
            ( model, Cmd.none )


search : Session -> String -> Cmd Msg
search session query =
    Cmd.batch
        [ Route.RecipeList (Just query)
            |> Route.replaceUrl (Session.navKey session)
        , Recipe.search LoadedRecipes query
        ]



-- EXPORT


toSession : Model -> Session
toSession model =
    model.session
