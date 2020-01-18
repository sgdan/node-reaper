module Main exposing (Node, main, msgDecoder, nodeDecoder, statusDecoder)

import Browser
import Element
    exposing
        ( Attribute
        , Color
        , Element
        , alignRight
        , column
        , el
        , fill
        , fillPortion
        , height
        , layout
        , maximum
        , none
        , padding
        , rgb255
        , row
        , shrink
        , spacing
        , table
        , text
        , width
        )
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input
import Html
import Http exposing (Error(..))
import Json.Decode as D
import Json.Encode as E
import Time



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


type ServerState
    = Loading
    | LoadFailed String
    | Loaded (List Node)


type alias Model =
    { state : ServerState
    , url : String
    , filter : String
    }


type alias Flags =
    String


type alias Node =
    { name : String
    , id : String
    , ip : String
    , instanceType : String
    , canExtend : Bool
    , remaining : Maybe String
    , state : String
    }


type alias Cell =
    { content : String
    , attributes : List (Attribute Msg)
    }


loadState : String -> Cmd Msg
loadState url =
    Http.get
        { url = url ++ "status"
        , expect = Http.expectString GotUpdate
        }


encode : String -> E.Value
encode id =
    E.object [ ( "id", E.string id ) ]


extend : String -> String -> Cmd Msg
extend url id =
    Http.post
        { url = url ++ "extend"
        , body = encode id |> Http.jsonBody
        , expect = Http.expectString GotUpdate
        }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { state = Loading
      , url = flags
      , filter = ""
      }
    , loadState flags
    )



-- UPDATE


type Msg
    = GotUpdate (Result Http.Error String)
    | GetUpdate Time.Posix
    | Extend String
    | Filter String


toString : Http.Error -> String
toString e =
    case e of
        BadUrl msg ->
            "Bad url: " ++ msg

        Timeout ->
            "Timeout"

        NetworkError ->
            "Network error"

        BadStatus x ->
            "Bad status: " ++ String.fromInt x

        BadBody msg ->
            "Bad body: " ++ msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotUpdate result ->
            case result of
                Ok json ->
                    case msgDecoder json of
                        Ok status ->
                            ( { model | state = Loaded status }, Cmd.none )

                        Err x ->
                            ( { model | state = LoadFailed <| D.errorToString x }, Cmd.none )

                Err x ->
                    ( { model | state = LoadFailed <| toString x }, Cmd.none )

        GetUpdate _ ->
            ( model, loadState model.url )

        Extend node ->
            ( model, extend model.url node )

        Filter entered ->
            ( { model | filter = entered }, Cmd.none )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Time.every 5000 GetUpdate


blue : Color
blue =
    rgb255 100 100 255


green : Color
green =
    rgb255 75 255 75


red : Color
red =
    rgb255 255 75 75


dark : Color
dark =
    rgb255 20 20 20


grey : Color
grey =
    rgb255 130 130 130


right : Cell -> Cell
right cell =
    { cell | attributes = Font.alignRight :: cell.attributes }


render : Cell -> Element Msg
render cell =
    text cell.content |> el cell.attributes


header : String -> Cell
header content =
    Cell content [ Font.size 20, Font.color blue ]


value : String -> Cell
value content =
    Cell content []


nodeTable : List Node -> Element Msg
nodeTable nodes =
    table
        [ spacing 10
        , padding 10
        , width (fill |> maximum 950)
        , Font.size 18
        ]
        { data = nodes
        , columns =
            [ { header = header "Name" |> render
              , width = fillPortion 2
              , view = \n -> value n.name |> color n |> render
              }
            , { header = header "Instance ID" |> render
              , width = fillPortion 1
              , view = \n -> value n.id |> color n |> render
              }
            , { header = header "IP Address" |> render
              , width = fillPortion 1
              , view = \n -> value n.ip |> color n |> render
              }
            , { header = header "State" |> render
              , width = fillPortion 1
              , view = \n -> value n.state |> color n |> render
              }
            , { header = header "Remaining" |> right |> render
              , width = fillPortion 1
              , view = showRemaining
              }
            , { header = none
              , width = shrink
              , view = extendButton
              }
            , { header = none
              , width = fillPortion 1
              , view = \_ -> none
              }
            ]
        }


isNothing : Maybe a -> Bool
isNothing a =
    case a of
        Just _ ->
            False

        Nothing ->
            True


color : Node -> Cell -> Cell
color node base =
    let
        c =
            if isNothing node.remaining && node.state /= "stopped" then
                red

            else if node.state == "stopped" then
                grey

            else if node.state == "running" then
                green

            else
                red
    in
    { base | attributes = Font.color c :: base.attributes }


showRemaining : Node -> Element Msg
showRemaining n =
    case n.remaining of
        Nothing ->
            none

        Just x ->
            value x |> color n |> right |> render


extendButton : Node -> Element Msg
extendButton ns =
    if ns.canExtend then
        Input.button
            [ alignRight
            , Border.width 0
            , Border.rounded 3
            ]
            { onPress = Just <| Extend ns.id, label = text ">" }

    else
        none


defaultPage : List (Element Msg) -> Element Msg
defaultPage content =
    column
        [ Font.color grey, spacing 20, padding 20, width fill, height fill ]
        content


errorPage : String -> Element Msg
errorPage message =
    defaultPage [ title, el [] (text message) ]


title : Element Msg
title =
    row [ width fill ]
        [ el [ Font.size 40 ] <| text "Node Reaper" ]


page : List Node -> String -> Element Msg
page nodes filter =
    defaultPage
        [ title
        , Input.text
            [ Background.color dark
            , Border.width 0
            , padding 0
            , width (fill |> maximum 300)
            , Font.size 14
            ]
            { onChange = \x -> Filter x
            , text = filter
            , placeholder = Nothing
            , label = Input.labelLeft [] <| text "Filter: "
            }
        , nodeTable <| List.filter (\a -> String.contains filter a.name) nodes
        ]


defaultStyle : List (Attribute msg)
defaultStyle =
    [ Background.color dark
    , Font.color grey
    ]


nodeDecoder : D.Decoder Node
nodeDecoder =
    D.map7 Node
        (D.field "name" D.string)
        (D.field "id" D.string)
        (D.field "ip" D.string)
        (D.field "instanceType" D.string)
        (D.field "canExtend" D.bool)
        (D.maybe <| D.field "remaining" D.string)
        (D.field "state" D.string)


decodeNodes : Maybe (List Node) -> D.Decoder (List Node)
decodeNodes ns =
    D.succeed (Maybe.withDefault [] ns)


statusDecoder : D.Decoder (List Node)
statusDecoder =
    D.maybe (D.field "nodes" <| D.list nodeDecoder) |> D.andThen decodeNodes


msgDecoder : String -> Result D.Error (List Node)
msgDecoder json =
    D.decodeString statusDecoder json


view : Model -> Html.Html Msg
view model =
    case model.state of
        LoadFailed msg ->
            layout defaultStyle <| errorPage <| "Unable to retrieve namespace data: " ++ msg

        Loading ->
            layout defaultStyle <| errorPage "Loading..."

        Loaded status ->
            layout defaultStyle <| page status model.filter
