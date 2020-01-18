module Tests exposing (beautiful, beautifulJson, bold, boldJson, creepy, creepyJson, jsonList, jsonMessage, msg, one, several)

import Expect
import Json.Decode as D
import Main exposing (Node, msgDecoder, nodeDecoder)
import Test exposing (Test, test)


boldJson : String
boldJson =
    """
        {
            "name": "bold",
            "id": "id-2387",
            "ip": "1.2.3.4",
            "instanceType": "im.large",
            "canExtend": false,
            "remaining": "3h 14m",
            "state": "running"
        }
    """


beautifulJson : String
beautifulJson =
    """
        {
            "name": "beautiful",
            "id": "id-8346",
            "ip": "5.6.7.8",
            "instanceType": "im.medium",
            "canExtend": true,
            "state": "stopped"
        }
    """


creepyJson : String
creepyJson =
    """
        {
            "name": "creepy",
            "id": "id-9473",
            "ip": "9.10.11.12",
            "instanceType": "im.small",
            "canExtend": true,
            "state": "pending"
        }
    """


jsonList : String
jsonList =
    "[" ++ boldJson ++ "," ++ beautifulJson ++ "," ++ creepyJson ++ "]"


jsonMessage : String
jsonMessage =
    "{\"nodes\":" ++ jsonList ++ "}"


creepy : Node
creepy =
    { name = "creepy"
    , id = "id-9473"
    , ip = "9.10.11.12"
    , instanceType = "im.small"
    , canExtend = True
    , remaining = Nothing
    , state = "pending"
    }


beautiful : Node
beautiful =
    { name = "beautiful"
    , id = "id-8346"
    , ip = "5.6.7.8"
    , instanceType = "im.medium"
    , canExtend = True
    , remaining = Nothing
    , state = "stopped"
    }


bold : Node
bold =
    { name = "bold"
    , id = "id-2387"
    , ip = "1.2.3.4"
    , instanceType = "im.large"
    , canExtend = False
    , remaining = Just "3h 14m"
    , state = "running"
    }


msg : Test
msg =
    test "Decode full status message" <|
        \_ ->
            Expect.equal
                (msgDecoder jsonMessage)
            <|
                Ok [ bold, beautiful, creepy ]


several : Test
several =
    test "Decode list of namespaces from JSON" <|
        \_ ->
            Expect.equal
                (D.decodeString (D.list nodeDecoder) jsonList)
                (Ok [ bold, beautiful, creepy ])


one : Test
one =
    test "Decode namespace from JSON" <|
        \_ ->
            Expect.equal
                (D.decodeString nodeDecoder beautifulJson)
                (Ok beautiful)
