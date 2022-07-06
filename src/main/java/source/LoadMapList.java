package source;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import model.Map;
import org.json.JSONArray;
import org.json.JSONObject;

import java.io.IOException;
import java.lang.reflect.Type;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

public class LoadMapList {

    String url = "https://0.0.0.0/gs-robot/data/maps";
    String charset = java.nio.charset.StandardCharsets.UTF_8.name();

    String jsonString = "{\n" +
            "   \"data\":[\n" +
            "      {\n" +
            "         \"createdAt\":\"2016-08-11 04:08:30\",\n" +
            "         \"dataFileName\":\"40dd8fcd-5e6d-4890-b620-88882d9d3977.data\",\n" +
            "         \"id\":0,\n" +
            "         \"mapInfo\":{\n" +
            "            \"gridHeight\":1152,\n" +
            "            \"gridWidth\":1344,\n" +
            "            \"originX\":-10,\n" +
            "            \"originY\":-10,\n" +
            "            \"resolution\":0.1\n" +
            "         },\n" +
            "         \"name\":\"demo\",\n" +
            "         \"obstacleFileName\":\"\",\n" +
            "         \"pgmFileName\":\"6a3e7cae-c4a8-4583-9a5d-08682344647a.pgm\",\n" +
            "         \"pngFileName\":\"228b335f-8c1a-4f05-a292-160f942cbe00.png\",\n" +
            "         \"yamlFileName\":\"4108be8c-4004-4ad6-a9c5-599b4a3d49df.yaml\"\n" +
            "      },\n" +
            "      {\n" +
            "         \"createdAt\":\"2016-07-27 23:37:31\",\n" +
            "         \"dataFileName\":\"df5ff3c6-ac5c-4365-a89a-ca0128057006.data\",\n" +
            "         \"id\":0,\n" +
            "         \"mapInfo\":{\n" +
            "            \"gridHeight\":992,\n" +
            "            \"gridWidth\":992,\n" +
            "            \"originX\":-24.8,\n" +
            "            \"originY\":-24.8,\n" +
            "            \"resolution\":0.05000000074505806\n" +
            "         },\n" +
            "         \"name\":\"tom5\",\n" +
            "         \"obstacleFileName\":\"\",\n" +
            "         \"pgmFileName\":\"8768e979-6a27-46db-a479-b729036970b3.pgm\",\n" +
            "         \"pngFileName\":\"5ef8bd27-5ffa-4c44-8f25-2f2811d0d2e8.png\",\n" +
            "         \"yamlFileName\":\"e2c0cc20-6ee8-4ce9-91c0-1fe1fce39857.yaml\"\n" +
            "      }\n" +
            "   ],\n" +
            "   \"errorCode\":\"\",\n" +
            "   \"msg\":\"successed\",\n" +
            "   \"successed\":true\n" +
            "}";

    public List<Map> getMapList() {
        System.out.println("starting process");

        ArrayList<Map> mapList = new ArrayList<>();

        HttpClient client = HttpClient.newHttpClient();
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .build();
        try {
            HttpResponse<String> response = client.send(request, HttpResponse.BodyHandlers.ofString());
            if (response.statusCode() == 200) {
//                String jsonString = response.body();

                JSONObject jsonObject = new JSONObject(jsonString);
                if (Objects.equals(jsonObject.getString("msg"), "successed")) {
                    JSONArray mapArray = jsonObject.getJSONArray("data");

                    Type listType = new TypeToken<List<Map>>(){}.getType();

                    mapList = new Gson().fromJson(mapArray.toString(), listType);
                    System.out.println(mapList.get(0).getName());
                }

            }
        } catch (InterruptedException | IOException e) {
            e.printStackTrace();
        }

        // only for test when server if offline
        JSONObject jsonObject = new JSONObject(jsonString);
        System.out.println(jsonObject);
        System.out.println(jsonObject.getString("msg"));
        if (Objects.equals(jsonObject.getString("msg"), "successed")) {
            JSONArray mapArray = jsonObject.getJSONArray("data");
            Type listType = new TypeToken<List<Map>>(){}.getType();
            mapList = new Gson().fromJson(mapArray.toString(), listType);
            System.out.println(mapList.get(0).getName());
        }

        return mapList;
    }
}
