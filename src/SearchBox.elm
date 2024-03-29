module SearchBox exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http
import Json.Decode as D exposing (Decoder)


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }



-- Model


type alias Model =
    { input : String
    , userState : UserState
    }


type UserState
    = Init
    | Wating
    | Loaded User
    | Failed Http.Error


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model "" Init, Cmd.none )



-- Update


type Msg
    = Input String
    | Send
    | Receive (Result Http.Error User)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Input newInput ->
            ( { model | input = newInput }, Cmd.none )

        Send ->
            ( { model | input = "", userState = Wating }, Http.get { url = "https://api.github.com/users/" ++ model.input, expect = Http.expectJson Receive userDecoder } )

        Receive (Ok user) ->
            ( { model | userState = Loaded user }, Cmd.none )

        Receive (Err e) ->
            ( { model | userState = Failed e }, Cmd.none )



-- View


view : Model -> Html Msg
view model =
    div []
        [ Html.form [ onSubmit Send ]
            [ input
                [ onInput Input
                , autofocus True
                , placeholder "Github name"
                , value model.input
                ]
                []
            , button [ disabled ((model.userState == Wating) || String.isEmpty (String.trim model.input)) ]
                [ text "Submit" ]
            ]
        , case model.userState of
            Init ->
                text ""

            Wating ->
                text "Waiting"

            Loaded user ->
                a
                    [ href user.htmlUrl, target "_blank" ]
                    [ img [ src user.avatarUrl, width 200 ] []
                    , div [] [ text user.name ]
                    , div []
                        [ case user.bio of
                            Just bio ->
                                text bio

                            Nothing ->
                                text ""
                        ]
                    ]

            Failed error ->
                div [] [ text (Debug.toString error) ]
        ]



-- Data


type alias User =
    { login : String
    , avatarUrl : String
    , name : String
    , htmlUrl : String
    , bio : Maybe String
    }


userDecoder : Decoder User
userDecoder =
    D.map5 User
        (D.field "login" D.string)
        (D.field "avatar_url" D.string)
        (D.field "name" D.string)
        (D.field "html_url" D.string)
        (D.maybe (D.field "bio" D.string))
